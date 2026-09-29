import 'package:redux/redux.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../features/partnerships/domain/usecases/partnership_usecases.dart';
import '../actions/auth_actions.dart';
import '../actions/partnership_actions.dart';
import '../state/app_state.dart';

/// Runs the pharmacy partnership network calls.
class PartnershipMiddleware {
  PartnershipMiddleware({
    required this.loadPharmacyDirectory,
    required this.loadPartnershipOverview,
    required this.createGroup,
    required this.updateGroup,
    required this.assignPharmacyToGroup,
    required this.removePharmacyFromGroup,
    required this.movePharmacyToGroup,
    required this.createAgreement,
    required this.setAgreementStatus,
  });

  final LoadPharmacyDirectoryUseCase loadPharmacyDirectory;
  final LoadPartnershipOverviewUseCase loadPartnershipOverview;
  final CreateGroupUseCase createGroup;
  final UpdateGroupUseCase updateGroup;
  final AssignPharmacyToGroupUseCase assignPharmacyToGroup;
  final RemovePharmacyFromGroupUseCase removePharmacyFromGroup;
  final MovePharmacyToGroupUseCase movePharmacyToGroup;
  final CreateAgreementUseCase createAgreement;
  final SetAgreementStatusUseCase setAgreementStatus;

  List<Middleware<AppState>> get middleware => [
        TypedMiddleware<AppState, LoadPharmacyDirectoryAction>(_loadDirectory),
        TypedMiddleware<AppState, LoadPartnershipOverviewAction>(_loadOverview),
        TypedMiddleware<AppState, CreatePharmacyGroupAction>(_createGroup),
        TypedMiddleware<AppState, UpdatePharmacyGroupAction>(_updateGroup),
        TypedMiddleware<AppState, AssignPharmacyToGroupAction>(_assign),
        TypedMiddleware<AppState, RemovePharmacyFromGroupAction>(_remove),
        TypedMiddleware<AppState, MovePharmacyToGroupAction>(_move),
        TypedMiddleware<AppState, CreateAgreementAction>(_createAgreement),
        TypedMiddleware<AppState, SetAgreementStatusAction>(_setStatus),
      ];

  /// An expired or revoked token cannot be recovered from by retrying, so it
  /// signs the admin out instead of showing an error they cannot act on.
  /// `AppShell` watches for that and routes back to the login page.
  bool _signedOutOn(Store<AppState> store, Object error) {
    if (error is SessionExpiredFailure) {
      store.dispatch(const SessionExpiredAction());
      return true;
    }
    return false;
  }

  static String _messageFor(Object error) =>
      error is Failure ? error.message : error.toString();

  Future<void> _loadDirectory(
    Store<AppState> store,
    LoadPharmacyDirectoryAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final directory = await loadPharmacyDirectory.call(NoParams());
      store.dispatch(PharmacyDirectoryLoadedAction(directory));
    } on Object catch (error) {
      if (_signedOutOn(store, error)) return;
      store.dispatch(PharmacyDirectoryFailedAction(_messageFor(error)));
    }
  }

  Future<void> _loadOverview(
    Store<AppState> store,
    LoadPartnershipOverviewAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final overview = await loadPartnershipOverview.call(NoParams());
      store.dispatch(PartnershipOverviewLoadedAction(overview));
    } on Object catch (error) {
      if (_signedOutOn(store, error)) return;
      store.dispatch(PartnershipOverviewFailedAction(_messageFor(error)));
    }
  }

  /// Shared tail for every mutation: report it, then reload whatever it
  /// invalidated so the tables never show a stale row after a write.
  Future<void> _mutate(
    Store<AppState> store, {
    required Future<void> Function() run,
    required String successMessage,
    required List<Object> reload,
  }) async {
    try {
      await run();
      store.dispatch(PartnershipActionSucceededAction(successMessage));
      for (final action in reload) {
        store.dispatch(action);
      }
    } on Object catch (error) {
      if (_signedOutOn(store, error)) return;
      store.dispatch(PartnershipActionFailedAction(_messageFor(error)));
    }
  }

  Future<void> _createGroup(
    Store<AppState> store,
    CreatePharmacyGroupAction action,
    NextDispatcher next,
  ) async {
    next(action);

    await _mutate(
      store,
      run: () => createGroup.call(action.params),
      successMessage: '${action.params.groupName} created.',
      reload: const [LoadPartnershipOverviewAction()],
    );
  }

  Future<void> _updateGroup(
    Store<AppState> store,
    UpdatePharmacyGroupAction action,
    NextDispatcher next,
  ) async {
    next(action);

    await _mutate(
      store,
      run: () => updateGroup.call(action.params),
      successMessage: 'Group updated.',
      // A tier or name change shows up in the directory's Tier/Group columns
      // too, so both views reload.
      reload: const [
        LoadPartnershipOverviewAction(),
        LoadPharmacyDirectoryAction(),
      ],
    );
  }

  Future<void> _assign(
    Store<AppState> store,
    AssignPharmacyToGroupAction action,
    NextDispatcher next,
  ) async {
    next(action);

    await _mutate(
      store,
      run: () => assignPharmacyToGroup.call(action.params),
      successMessage: 'Pharmacy added to the group.',
      reload: const [
        LoadPharmacyDirectoryAction(),
        LoadPartnershipOverviewAction(),
      ],
    );
  }

  Future<void> _remove(
    Store<AppState> store,
    RemovePharmacyFromGroupAction action,
    NextDispatcher next,
  ) async {
    next(action);

    await _mutate(
      store,
      run: () => removePharmacyFromGroup.call(action.params),
      successMessage: 'Pharmacy removed from the group.',
      reload: const [
        LoadPharmacyDirectoryAction(),
        LoadPartnershipOverviewAction(),
      ],
    );
  }

  Future<void> _move(
    Store<AppState> store,
    MovePharmacyToGroupAction action,
    NextDispatcher next,
  ) async {
    next(action);

    await _mutate(
      store,
      run: () => movePharmacyToGroup.call(action.params),
      successMessage: 'Pharmacy moved to the new group.',
      reload: const [
        LoadPharmacyDirectoryAction(),
        LoadPartnershipOverviewAction(),
      ],
    );
  }

  Future<void> _createAgreement(
    Store<AppState> store,
    CreateAgreementAction action,
    NextDispatcher next,
  ) async {
    next(action);

    await _mutate(
      store,
      run: () => createAgreement.call(action.params),
      successMessage: 'Agreement created and left pending activation.',
      reload: const [LoadPartnershipOverviewAction()],
    );
  }

  Future<void> _setStatus(
    Store<AppState> store,
    SetAgreementStatusAction action,
    NextDispatcher next,
  ) async {
    next(action);

    await _mutate(
      store,
      run: () => setAgreementStatus.call(action.params),
      successMessage: action.params.activate
          ? 'Agreement activated.'
          : 'Agreement suspended.',
      reload: const [LoadPartnershipOverviewAction()],
    );
  }
}
