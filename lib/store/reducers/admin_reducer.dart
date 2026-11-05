import '../actions/admin_actions.dart';
import '../actions/auth_actions.dart';
import '../state/admin_state.dart';

/// Pure reducer for the admin data slice.
AdminState adminReducer(AdminState state, dynamic action) {
  // Signing out must not leave one admin's data on screen for the next.
  if (action is LogoutAction || action is SessionExpiredAction) {
    return AdminState.initial();
  }

  if (action is FetchAdminResourceAction) {
    final current = state.of(action.resource);
    final sameRequest = sameParams(current.params, action.params);
    return state.withResource(
      action.resource,
      RemoteData(
        status: LoadStatus.loading,
        // A reload keeps the old rows visible; a different request (another
        // group, another date range) must not show the previous one's data.
        data: sameRequest ? current.data : null,
        updatedAt: sameRequest ? current.updatedAt : null,
        params: action.params,
      ),
    );
  }

  if (action is AdminResourceLoadedAction) {
    if (!_isLatest(state, action.resource, action.params)) return state;
    return state.withResource(
      action.resource,
      RemoteData(
        status: LoadStatus.success,
        data: action.data,
        params: action.params,
        updatedAt: DateTime.now(),
      ),
    );
  }

  if (action is AdminResourceFailedAction) {
    if (!_isLatest(state, action.resource, action.params)) return state;
    final current = state.of(action.resource);
    return state.withResource(
      action.resource,
      RemoteData(
        status: LoadStatus.failure,
        error: action.error,
        data: current.data,
        updatedAt: current.updatedAt,
        params: action.params,
      ),
    );
  }

  if (action is ClearAdminResourceAction) {
    return state.withResource(action.resource, RemoteData.idle);
  }

  if (action is AdminMutationStartedAction) {
    return state.withPending({...state.pendingMutations, action.key});
  }

  if (action is AdminMutationFinishedAction) {
    return state.withPending(
        state.pendingMutations.where((k) => k != action.key).toSet());
  }

  return state;
}

/// A response is applied only if it answers the most recent request for that
/// resource — a slow reply for group 3 must not overwrite group 5's detail.
bool _isLatest(
        AdminState state, AdminResource resource, Map<String, dynamic> params) =>
    sameParams(state.of(resource).params, params);

/// Shallow equality for the flat param maps the admin actions carry.
bool sameParams(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
