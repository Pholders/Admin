import 'package:redux/redux.dart';

import '../../core/error/failures.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/admin_login_usecase.dart';
import '../../features/auth/domain/usecases/verify_admin_otp_usecase.dart';
import '../actions/auth_actions.dart';
import '../state/app_state.dart';

/// Runs asynchronous authentication work for auth actions.
class AuthMiddleware {
  AuthMiddleware({
    required this.adminLoginUseCase,
    required this.verifyAdminOtpUseCase,
    required this.authRepository,
  });

  final AdminLoginUseCase adminLoginUseCase;
  final VerifyAdminOtpUseCase verifyAdminOtpUseCase;
  final AuthRepository authRepository;

  List<Middleware<AppState>> get middleware => [
        TypedMiddleware<AppState, AdminLoginRequestAction>(_handleAdminLogin),
        TypedMiddleware<AppState, AdminVerifyOtpAction>(_handleAdminVerifyOtp),
        TypedMiddleware<AppState, LogoutAction>(_handleLogout),
      ];

  Future<void> _handleAdminLogin(
    Store<AppState> store,
    AdminLoginRequestAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      await adminLoginUseCase.call(
        AdminLoginParams(email: action.email, password: action.password),
      );
      store.dispatch(AdminOtpSentAction(email: action.email));
    } on Failure catch (failure) {
      store.dispatch(LoginFailureAction(errorMessage: failure.message));
    } on Exception catch (error) {
      store.dispatch(LoginFailureAction(errorMessage: error.toString()));
    }
  }

  Future<void> _handleAdminVerifyOtp(
    Store<AppState> store,
    AdminVerifyOtpAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final session = await verifyAdminOtpUseCase.call(
        VerifyAdminOtpParams(email: action.email, otpCode: action.otpCode),
      );
      store.dispatch(LoginSuccessAction(
        token: session.token,
        role: session.role,
        userName: session.userName,
      ));
    } on Failure catch (failure) {
      store.dispatch(LoginFailureAction(errorMessage: failure.message));
    } on Exception catch (error) {
      store.dispatch(LoginFailureAction(errorMessage: error.toString()));
    }
  }

  Future<void> _handleLogout(
    Store<AppState> store,
    LogoutAction action,
    NextDispatcher next,
  ) async {
    next(action);
    try {
      await authRepository.logout();
    } catch (_) {
      // The local state has already been cleared; logout is best effort.
    }
  }
}
