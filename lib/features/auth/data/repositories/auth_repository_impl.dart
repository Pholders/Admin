import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.apiClient, required this.secureStorage});

  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  static const _tokenKey = AppConstants.tokenStorageKey;
  static const _roleKey = AppConstants.userRoleStorageKey;
  static const _userNameKey = AppConstants.userNameStorageKey;

  /// Joins [nameParts] into a display name, falling back through [fallbacks]
  /// and finally to the local part of [email].
  static String _displayName(
    List<Object?> nameParts, {
    required List<Object?> fallbacks,
    required String email,
  }) {
    String clean(Object? value) => value?.toString().trim() ?? '';

    final name = nameParts.map(clean).where((v) => v.isNotEmpty).join(' ');
    if (name.isNotEmpty) return name;

    for (final fallback in fallbacks) {
      final value = clean(fallback);
      if (value.isNotEmpty) return value;
    }
    return email.split('@').first;
  }

  /// Requests an admin login code.
  ///
  /// `/users/admin/login` returns no token at all — only
  /// `{data: {email, expiresIn}}` confirming a 6-digit code was emailed. The
  /// session is issued by [verifyAdminOtp].
  ///
  /// No Authorization header is sent: the route sits behind
  /// `preventAuthenticated` and answers 403 "Already logged in as …" to any
  /// request carrying a valid token, which would otherwise stop a signed-in
  /// admin from signing in again.
  @override
  Future<void> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      await apiClient.dio.post(
        '/users/admin/login',
        data: {
          'email': email,
          'password': password,
        },
      );
    } on Failure {
      rethrow;
    } on Exception catch (e) {
      // 401 invalid password, 403 unknown/inactive account, 429 rate limit —
      // each carries a usable server message that must reach the user verbatim.
      throw ServerFailure(
        apiErrorMessage(e, fallback: 'Could not sign you in. Please try again.'),
      );
    }
  }

  /// Exchanges an emailed admin code for a session.
  ///
  ///            admin
  ///   token    data.token             (flat)
  ///   refresh  none                   (admin is never issued one)
  ///   profile  data.admin, snake_case
  ///
  /// The `admins` table has no role column, so the role is supplied here
  /// rather than read from the response.
  @override
  Future<AuthSession> verifyAdminOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/users/admin/verify-otp',
        // Field is `otp_code`, not `otp`: the handler reads it straight off the
        // body and answers 400 for anything else.
        data: {
          'email': email,
          'otp_code': otpCode,
        },
      );

      if (response.data == null) {
        throw const ServerFailure(
            'Verification succeeded but returned nothing.');
      }

      final body = Map<String, dynamic>.from(response.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : <String, dynamic>{};
      final admin = data['admin'] is Map
          ? Map<String, dynamic>.from(data['admin'] as Map)
          : <String, dynamic>{};

      final accessToken = data['token']?.toString() ?? '';
      if (accessToken.isEmpty) {
        throw const ServerFailure(
            'Verification succeeded but no token was returned.');
      }

      final session = AuthSession(
        token: accessToken,
        refreshToken: null,
        role: AppConstants.roleAdmin,
        userName: _displayName(
          [admin['first_name'], admin['last_name']],
          fallbacks: [admin['email']],
          email: email,
        ),
      );

      await secureStorage.write(key: _tokenKey, value: session.token);
      await secureStorage.write(key: _roleKey, value: session.role);
      await secureStorage.write(key: _userNameKey, value: session.userName);

      return session;
    } on Failure {
      // Already carries the server's wording — re-wrapping would replace it
      // with the generic fallback, since apiErrorMessage only reads
      // DioExceptions.
      rethrow;
    } on Exception catch (e) {
      throw ServerFailure(
        apiErrorMessage(e,
            fallback: 'Could not verify that code. Please try again.'),
      );
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final token = await secureStorage.read(key: _tokenKey);
      final role = await secureStorage.read(key: _roleKey);
      final userName = await secureStorage.read(key: _userNameKey);

      if (token == null || token.isEmpty || role == null) {
        return null;
      }

      return AuthSession(
        token: token,
        role: role,
        userName: userName ?? 'Admin',
      );
    } on Exception {
      throw const CacheFailure();
    }
  }

  /// Revokes the server session, then clears everything stored locally.
  ///
  /// The network call is best-effort: an expired token, a lost connection or a
  /// role-guard rejection must never strand the user in a logged-in UI, so the
  /// local state is cleared either way.
  @override
  Future<void> logout() async {
    final token = await secureStorage.read(key: _tokenKey);

    if (token != null && token.isNotEmpty) {
      try {
        await apiClient.dio.post(
          '/users/admin/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on Exception {
        // Nothing to recover: the session either expired or was never valid.
      }
    }

    try {
      await secureStorage.delete(key: _tokenKey);
      await secureStorage.delete(key: _roleKey);
      await secureStorage.delete(key: _userNameKey);
    } on Exception {
      throw const CacheFailure();
    }
  }
}
