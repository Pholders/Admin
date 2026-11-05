import '../state/app_state.dart';
import 'admin_reducer.dart';
import 'auth_reducer.dart';
import 'navigation_reducer.dart';

/// Root reducer — delegates each state slice to its own reducer.
AppState appReducer(AppState state, dynamic action) {
  return AppState(
    authState: authReducer(state.authState, action),
    navigationState: navigationReducer(state.navigationState, action),
    adminState: adminReducer(state.adminState, action),
  );
}
