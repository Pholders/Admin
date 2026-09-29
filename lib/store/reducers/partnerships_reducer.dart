import '../actions/auth_actions.dart';
import '../actions/partnership_actions.dart';
import '../state/partnerships_state.dart';

/// Pure reducer for the pharmacy partnership state slice.
PartnershipsState partnershipsReducer(
  PartnershipsState state,
  dynamic action,
) {
  if (action is LoadPharmacyDirectoryAction) {
    return state.copyWith(isLoadingDirectory: true, clearDirectoryError: true);
  }

  if (action is PharmacyDirectoryLoadedAction) {
    return state.copyWith(
      directory: action.directory,
      isLoadingDirectory: false,
      directoryLoadedAt: DateTime.now(),
      clearDirectoryError: true,
    );
  }

  if (action is PharmacyDirectoryFailedAction) {
    return state.copyWith(
      isLoadingDirectory: false,
      directoryError: action.errorMessage,
      directoryLoadedAt: DateTime.now(),
    );
  }

  if (action is LoadPartnershipOverviewAction) {
    return state.copyWith(isLoadingOverview: true, clearOverviewError: true);
  }

  if (action is PartnershipOverviewLoadedAction) {
    return state.copyWith(
      overview: action.overview,
      isLoadingOverview: false,
      overviewLoadedAt: DateTime.now(),
      clearOverviewError: true,
    );
  }

  if (action is PartnershipOverviewFailedAction) {
    return state.copyWith(
      isLoadingOverview: false,
      overviewError: action.errorMessage,
      overviewLoadedAt: DateTime.now(),
    );
  }

  if (action is CreatePharmacyGroupAction ||
      action is UpdatePharmacyGroupAction ||
      action is AssignPharmacyToGroupAction ||
      action is MovePharmacyToGroupAction ||
      action is RemovePharmacyFromGroupAction ||
      action is CreateAgreementAction ||
      action is SetAgreementStatusAction) {
    return state.copyWith(isMutating: true, clearActionMessages: true);
  }

  if (action is PartnershipActionSucceededAction) {
    // Any previous error was already cleared when the mutation started, so
    // the banner shows this success on its own.
    return state.copyWith(isMutating: false, actionMessage: action.message);
  }

  if (action is PartnershipActionFailedAction) {
    return state.copyWith(
      isMutating: false,
      actionError: action.errorMessage,
    );
  }

  if (action is ClearPartnershipMessagesAction) {
    return state.copyWith(clearActionMessages: true);
  }

  // Nothing here survives signing out: the next admin must not see the
  // previous one's data flash on screen before their own load finishes.
  if (action is LogoutAction || action is SessionExpiredAction) {
    return PartnershipsState.initial();
  }

  return state;
}
