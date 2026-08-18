/// Single source of truth for all route path strings.
///
/// No widget should hardcode a route path — always use this class.
class AppRoutes {
  AppRoutes._();

  // ─── Public ─────────────────────────────────────────────────────────────────
  /// Public only because it has to be: no token exists until the emailed code
  /// is verified.
  static const String adminLogin = '/admin/login';

  /// Second leg of the admin login.
  static const String adminVerify = '/admin/verify';

  // ─── Authenticated ──────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
}
