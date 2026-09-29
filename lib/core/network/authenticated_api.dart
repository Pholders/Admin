import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../error/failures.dart';
import 'api_client.dart';
import 'api_error_message.dart';

/// Every admin endpoint sits behind `authMiddleware` + `requireRole('admin')`,
/// so each call needs `Authorization: Bearer <token>`.
///
/// The header is attached here rather than by a global Dio interceptor on
/// purpose: `/users/admin/login` and `/users/admin/verify-otp` sit behind the
/// backend's `preventAuthenticated` guard, which answers 403 to any request
/// that carries a valid token. A blanket interceptor would make a signed-in
/// admin unable to sign in again.
class AuthenticatedApi {
  AuthenticatedApi({required this.apiClient, required this.secureStorage});

  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  Future<Options> _options() async {
    final token = await secureStorage.read(key: AppConstants.tokenStorageKey);
    if (token == null || token.isEmpty) {
      throw const SessionExpiredFailure('You are not signed in.');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Runs [send] and normalises whatever it throws into a [Failure].
  ///
  /// The backend reports an expired or revoked session as 401 and a
  /// role mismatch as 403; both mean the stored token is unusable, so both
  /// become [SessionExpiredFailure].
  Future<T> _guard<T>(Future<T> Function() send, String fallback) async {
    try {
      return await send();
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw SessionExpiredFailure(
          apiErrorMessage(e,
              fallback: 'Your session has expired. Please sign in again.'),
        );
      }
      throw ServerFailure(apiErrorMessage(e, fallback: fallback));
    } on Exception catch (e) {
      throw ServerFailure(apiErrorMessage(e, fallback: fallback));
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String fallbackError = 'Could not load that. Please try again.',
  }) async {
    final options = await _options();
    return _guard(
      () => apiClient.dio
          .get(path, queryParameters: queryParameters, options: options),
      fallbackError,
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    String fallbackError = 'Could not save that. Please try again.',
  }) async {
    final options = await _options();
    return _guard(
      () => apiClient.dio.post(path,
          data: data, queryParameters: queryParameters, options: options),
      fallbackError,
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    String fallbackError = 'Could not save that. Please try again.',
  }) async {
    final options = await _options();
    return _guard(
      () => apiClient.dio.put(path, data: data, options: options),
      fallbackError,
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    String fallbackError = 'Could not remove that. Please try again.',
  }) async {
    final options = await _options();
    return _guard(
      () => apiClient.dio.delete(path, data: data, options: options),
      fallbackError,
    );
  }
}

/// Reads the partnership endpoints' response envelope.
///
/// The partnership controllers answer `{status: 'success', data: …, total: n}`
/// — note `status`, not the `success` flag the auth endpoints use — so the
/// payload always sits under `data`.
extension ApiEnvelope on Response<dynamic> {
  /// The `data` object, or `{}` when the body is shaped unexpectedly.
  Map<String, dynamic> get dataObject {
    final body = data;
    if (body is! Map) return <String, dynamic>{};
    final payload = body['data'];
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return <String, dynamic>{};
  }

  /// The `data` array, or `[]` when the body is shaped unexpectedly.
  List<Map<String, dynamic>> get dataList {
    final body = data;
    if (body is! Map) return const [];
    final payload = body['data'];
    if (payload is! List) return const [];
    return payload
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
