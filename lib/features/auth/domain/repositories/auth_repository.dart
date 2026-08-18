import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// First leg of admin sign-in: checks the password and emails a 6-digit code.
  ///
  /// Returns no session — `/users/admin/login` issues no token. The token comes
  /// only from [verifyAdminOtp].
  Future<void> adminLogin({
    required String email,
    required String password,
  });

  /// Second leg: exchanges the emailed code for a session.
  Future<AuthSession> verifyAdminOtp({
    required String email,
    required String otpCode,
  });

  Future<AuthSession?> restoreSession();

  Future<void> logout();
}
