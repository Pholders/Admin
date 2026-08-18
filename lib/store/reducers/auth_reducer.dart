import '../actions/auth_actions.dart';
import '../state/auth_state.dart';

/// Pure reducer for the authentication state slice.
AuthState authReducer(AuthState state, dynamic action) {
  if (action is AdminLoginRequestAction || action is AdminVerifyOtpAction) {
    return state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
  }

  if (action is AdminOtpSentAction) {
    return state.copyWith(
      isLoading: false,
      clearError: true,
      successMessage: 'We sent a 6-digit code to ${action.email}.',
    );
  }

  if (action is LoginSuccessAction) {
    return state.copyWith(
      token: action.token,
      role: action.role,
      userName: action.userName,
      isLoading: false,
      clearError: true,
      clearSuccess: true,
    );
  }

  if (action is LoginFailureAction) {
    return state.copyWith(isLoading: false, errorMessage: action.errorMessage);
  }

  if (action is LogoutAction || action is SessionExpiredAction) {
    return AuthState.initial();
  }

  if (action is RestoreSessionAction) {
    if (action.token.isEmpty && action.role.isEmpty) return state;

    return state.copyWith(
      token: action.token,
      role: action.role,
      userName: action.userName,
    );
  }

  return state;
}
