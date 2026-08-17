import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/store.dart';

void main() {
  group('authReducer — admin sign-in', () {
    test('an emailed code does not authenticate the user', () {
      final nextState = authReducer(
        const AuthState(isLoading: true),
        const AdminOtpSentAction(email: 'ops@pholders.test'),
      );

      // The whole point of the two-step flow: step one issues no token, so
      // every protected route must stay shut until the code is verified.
      expect(nextState.isAuthenticated, isFalse);
      expect(nextState.token, isNull);
      expect(nextState.role, isNull);
      expect(nextState.isLoading, isFalse);
      expect(nextState.successMessage, contains('ops@pholders.test'));
    });

    test('submitting credentials clears a previous error', () {
      final nextState = authReducer(
        const AuthState(errorMessage: 'Invalid email or password'),
        const AdminLoginRequestAction(
            email: 'ops@pholders.test', password: 'secret'),
      );

      expect(nextState.isLoading, isTrue);
      expect(nextState.errorMessage, isNull);
    });

    test('submitting the code clears the code-sent message', () {
      final nextState = authReducer(
        const AuthState(successMessage: 'We sent a 6-digit code to x@y.test.'),
        const AdminVerifyOtpAction(email: 'x@y.test', otpCode: '123456'),
      );

      expect(nextState.isLoading, isTrue);
      expect(nextState.successMessage, isNull);
    });

    test('a verified code authenticates as admin', () {
      final nextState = authReducer(
        const AuthState(isLoading: true),
        const LoginSuccessAction(
            token: 'jwt', role: 'admin', userName: 'Thabo Mokoena'),
      );

      expect(nextState.isAuthenticated, isTrue);
      expect(nextState.role, 'admin');
      expect(nextState.userName, 'Thabo Mokoena');
      expect(nextState.isLoading, isFalse);
    });

    test('logout clears the session', () {
      final nextState = authReducer(
        const AuthState(token: 'jwt', role: 'admin', userName: 'Thabo'),
        const LogoutAction(),
      );

      expect(nextState.isAuthenticated, isFalse);
      expect(nextState.token, isNull);
      expect(nextState.role, isNull);
      expect(nextState.userName, isNull);
    });

    test('a failure surfaces the API message and stops loading', () {
      final nextState = authReducer(
        const AuthState(isLoading: true),
        const LoginFailureAction(
          errorMessage: 'Too many failed login attempts. Please try again '
              'later or contact support.',
        ),
      );

      expect(nextState.isLoading, isFalse);
      expect(nextState.errorMessage, contains('Too many failed'));
      expect(nextState.isAuthenticated, isFalse);
    });

    test('ignores an empty restore-session action', () {
      const state = AuthState(token: 'abc', role: 'admin', userName: 'Ada');

      final nextState = authReducer(
        state,
        const RestoreSessionAction(token: '', role: '', userName: ''),
      );

      expect(nextState, state);
    });

    test('restores a stored session', () {
      final nextState = authReducer(
        AuthState.initial(),
        const RestoreSessionAction(
            token: 'jwt', role: 'admin', userName: 'Ada'),
      );

      expect(nextState.isAuthenticated, isTrue);
      expect(nextState.userName, 'Ada');
    });
  });
}
