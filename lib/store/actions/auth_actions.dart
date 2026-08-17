/// Redux actions for the authentication state slice.
///
/// Actions only describe an event. Network and storage work belongs in
/// middleware.
library;

class AdminLoginRequestAction {
  final String email;
  final String password;

  const AdminLoginRequestAction({required this.email, required this.password});
}

class AdminOtpSentAction {
  final String email;

  const AdminOtpSentAction({required this.email});
}

class AdminVerifyOtpAction {
  final String email;
  final String otpCode;

  const AdminVerifyOtpAction({required this.email, required this.otpCode});
}

class LoginSuccessAction {
  final String token;
  final String role;
  final String userName;

  const LoginSuccessAction({
    required this.token,
    required this.role,
    required this.userName,
  });
}

class LoginFailureAction {
  final String errorMessage;

  const LoginFailureAction({required this.errorMessage});
}

class LogoutAction {
  const LogoutAction();
}

class RestoreSessionAction {
  final String token;
  final String role;
  final String userName;

  const RestoreSessionAction({
    required this.token,
    required this.role,
    required this.userName,
  });
}

class SessionExpiredAction {
  const SessionExpiredAction();
}
