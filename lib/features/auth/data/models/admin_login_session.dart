/// Carries the admin's email from the login page to the OTP page.
///
/// `/users/admin/verify-otp` needs the address the code was sent to, but the
/// login response holds nothing worth persisting and the code is valid for ten
/// minutes — so this is deliberately in-memory only, and never holds the
/// password.
///
/// Being in-memory, it does not survive a browser refresh. The OTP page must
/// treat a null [email] as "restart the sign-in", never post it as-is.
class AdminLoginSession {
  factory AdminLoginSession() => _instance;
  static final AdminLoginSession _instance = AdminLoginSession._internal();
  AdminLoginSession._internal();

  String? email;

  void clear() {
    email = null;
  }
}
