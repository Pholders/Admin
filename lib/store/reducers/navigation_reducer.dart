import '../actions/navigation_actions.dart';
import '../state/navigation_state.dart';

/// Pure reducer for sidebar navigation within the authenticated shell.
NavigationState navigationReducer(NavigationState state, dynamic action) {
  if (action is NavigateToAction && action.route != state.currentRoute) {
    return NavigationState(currentRoute: action.route);
  }

  return state;
}
