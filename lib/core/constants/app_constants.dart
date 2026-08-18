/// App-wide string constants and configuration values.
class AppConstants {
  AppConstants._();

  static const String appName = 'PHolders Admin';
  static const String appVersion = '1.0.0';

  // ─── API ────────────────────────────────────────────────────────────────────
  static const String apiBaseUrl =
      'https://backend-system-u8s2.onrender.com/api';

  // ─── Auth ───────────────────────────────────────────────────────────────────
  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';
  static const String userRoleStorageKey = 'user_role';
  static const String userNameStorageKey = 'auth_user_name';

  // ─── Roles ──────────────────────────────────────────────────────────────────
  /// The only role this app signs in. The `admins` table has no role column —
  /// role lives in the JWT — so the client supplies it rather than reading it
  /// off the response.
  static const String roleAdmin = 'admin';
}
