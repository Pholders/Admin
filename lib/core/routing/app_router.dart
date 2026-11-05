import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import 'package:pholders_admin/store.dart';
import '../../features/auth/presentation/admin_login_page.dart';
import '../../features/auth/presentation/admin_verify_otp_page.dart';
import '../../screens/root_shell.dart';
import '../../core/constants/app_constants.dart';
import 'app_routes.dart';

/// Builds the [GoRouter].
///
/// The router reads auth state from the Redux [Store] to handle redirects.
/// All route strings come from [AppRoutes] — never hardcoded here.
GoRouter createRouter(Store<AppState> store) {
  return GoRouter(
    initialLocation: AppRoutes.adminDashboard,
    debugLogDiagnostics: true,
    // Re-run [redirect] whenever the signed-in state flips, not only on
    // navigation — otherwise an admin whose token expires mid-session (the
    // admin middleware dispatches SessionExpiredAction on a 401) would stay
    // on a screen whose every request now fails.
    refreshListenable: _AuthChangeNotifier(store),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = store.state.authState;
      final isAuthenticated = authState.isAuthenticated;
      final role = authState.role;

      final isPublicRoute = [
        AppRoutes.adminLogin,
        AppRoutes.adminVerify,
      ].contains(state.matchedLocation);

      // Signed out and heading anywhere protected → login. This is what makes
      // "log out, then press Back" land on the login page instead of a stale
      // dashboard, and what protects a hand-typed URL.
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.adminLogin;
      }

      // Already signed in → no reason to see the login or OTP pages again.
      if (isAuthenticated && isPublicRoute) {
        return AppRoutes.adminDashboard;
      }

      // Belt and braces: this app only ever mints admin sessions, but a token
      // restored from storage carries whatever role was saved with it, and a
      // non-admin token cannot use any endpoint behind requireRole('admin').
      if (isAuthenticated && role != AppConstants.roleAdmin) {
        return AppRoutes.adminLogin;
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.adminVerify,
        builder: (context, state) => const AdminVerifyOtpPage(),
      ),
      // The shell swaps authenticated screens from the Redux navigation slice.
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const RootShell(),
      ),
    ],
  );
}


/// Notifies when [AuthState.isAuthenticated] changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Store<AppState> store)
      : _signedIn = store.state.authState.isAuthenticated {
    _subscription = store.onChange.listen((state) {
      final signedIn = state.authState.isAuthenticated;
      if (signedIn == _signedIn) return;
      _signedIn = signedIn;
      notifyListeners();
    });
  }

  bool _signedIn;
  late final StreamSubscription<AppState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
