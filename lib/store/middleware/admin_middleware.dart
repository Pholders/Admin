import 'package:redux/redux.dart';

import '../../core/error/failures.dart';
import '../../core/network/admin_api.dart';
import '../actions/admin_actions.dart';
import '../actions/auth_actions.dart';
import '../state/admin_state.dart';
import '../state/app_state.dart';

/// Runs the network work behind the admin actions.
///
/// Param keys each resource reads from `FetchAdminResourceAction.params`:
///
///   activityLog          limit
///   dashboardSummary     —
///   dashboardActivity    range (daily | monthly | yearly; default monthly)
///   recentUsers          role (all | patient | doctor | pharmacy), limit
///   pharmacies, patients, doctors
///                        limit, offset, status
///   accountDetail        role (patient | doctor | pharmacy), id (both required)
///   securityDashboard    hours
///   userLocations        user_id (required), days
///   groups               q (switches to search), tier, is_active (default true)
///   groupDetail          id (required)
///   agreements           status, entity_type
///   expiringAgreements   days
///   agreementDetail      id (required)
///   pharmacyCompliance   pharmacy_id (required)
///   complianceReport     start_date, end_date (both required, yyyy-MM-dd)
///   routingCandidates    latitude, longitude
///   routingStatistics    start_date, end_date
///   systemLogs           lines
class AdminMiddleware {
  AdminMiddleware({required this.api});

  final AdminApi api;

  List<Middleware<AppState>> get middleware => [
        TypedMiddleware<AppState, FetchAdminResourceAction>(_handleFetch),
        TypedMiddleware<AppState, AdminMutationAction>(_handleMutation),
      ];

  Future<void> _handleFetch(
    Store<AppState> store,
    FetchAdminResourceAction action,
    NextDispatcher next,
  ) async {
    next(action);

    try {
      final data = await _load(action.resource, action.params);
      store.dispatch(
          AdminResourceLoadedAction(action.resource, action.params, data));
    } catch (error) {
      _reportUnauthorized(store, error);
      store.dispatch(AdminResourceFailedAction(
          action.resource, action.params, _message(error)));
    }
  }

  Future<dynamic> _load(AdminResource resource, Map<String, dynamic> p) {
    int? asInt(String key) =>
        p[key] == null ? null : int.tryParse(p[key].toString());
    String? asString(String key) {
      final value = p[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    String required(String key) {
      final value = asString(key);
      if (value == null) throw ValidationFailure('$key is required.');
      return value;
    }

    switch (resource) {
      case AdminResource.profile:
        return api.getProfile();
      case AdminResource.sessions:
        return api.getSessions();
      case AdminResource.activityLog:
        return api.getActivityLog(limit: asInt('limit') ?? 50);

      case AdminResource.dashboardSummary:
        return api.dashboardSummary();
      case AdminResource.dashboardActivity:
        return api.dashboardActivity(range: asString('range') ?? 'monthly');
      case AdminResource.recentUsers:
        return api.recentUsers(
          role: asString('role') ?? 'all',
          limit: asInt('limit') ?? 10,
        );
      case AdminResource.patients:
        return api.listPatients(
          limit: asInt('limit') ?? 200,
          offset: asInt('offset') ?? 0,
          status: asString('status'),
        );
      case AdminResource.doctors:
        return api.listDoctors(
          limit: asInt('limit') ?? 200,
          offset: asInt('offset') ?? 0,
          status: asString('status'),
        );
      case AdminResource.accountDetail:
        final id = required('id');
        switch (required('role')) {
          case 'patient':
            return api.getPatient(id);
          case 'doctor':
            return api.getDoctor(id);
          case 'pharmacy':
            return api.getPharmacy(id);
          default:
            throw const ValidationFailure('Unknown account type.');
        }

      case AdminResource.pharmacies:
        return api.listPharmacies(
          limit: asInt('limit') ?? 200,
          offset: asInt('offset') ?? 0,
          status: asString('status'),
        );

      case AdminResource.securityDashboard:
        return api.securityDashboard(hours: asInt('hours') ?? 24);
      case AdminResource.userLocations:
        return api.userLocations(
          userId: required('user_id'),
          days: asInt('days') ?? 30,
        );

      case AdminResource.groups:
        final q = asString('q');
        if (q != null) return api.searchGroups(q);
        return api.listGroups(
          tier: asString('tier'),
          isActive: p['is_active'] != false,
        );
      case AdminResource.groupDetail:
        return api.getGroup(required('id'));

      case AdminResource.agreements:
        return api.listAgreements(
          status: asString('status'),
          entityType: asString('entity_type'),
        );
      case AdminResource.expiringAgreements:
        return api.expiringAgreements(days: asInt('days') ?? 30);
      case AdminResource.agreementDetail:
        return api.getAgreement(required('id'));

      case AdminResource.complianceDashboard:
        return api.complianceDashboard();
      case AdminResource.pharmacyCompliance:
        return api.pharmacyCompliance(required('pharmacy_id'));
      case AdminResource.complianceReport:
        return api.complianceReport(
          startDate: required('start_date'),
          endDate: required('end_date'),
        );
      case AdminResource.routingCandidates:
        return api.routingCandidates(
          latitude: double.tryParse('${p['latitude']}') ?? 0,
          longitude: double.tryParse('${p['longitude']}') ?? 0,
        );
      case AdminResource.routingStatistics:
        return api.routingStatistics(
          startDate: asString('start_date'),
          endDate: asString('end_date'),
        );
      case AdminResource.routingByTier:
        return api.routingByTier();

      case AdminResource.systemLogs:
        return api.systemLogs(lines: asInt('lines') ?? 100);
    }
  }

  Future<void> _handleMutation(
    Store<AppState> store,
    AdminMutationAction action,
    NextDispatcher next,
  ) async {
    next(action);

    if (store.state.adminState.isPending(action.key)) {
      action.completer?.completeError(
          const ServerFailure('That is already in progress.'));
      return;
    }

    store.dispatch(AdminMutationStartedAction(action.key));
    try {
      final result = await _mutate(action);
      action.completer?.complete(result);
      _refresh(store, action.refreshes);
    } catch (error) {
      _reportUnauthorized(store, error);
      action.completer?.completeError(
          error is Failure ? error : ServerFailure(_message(error)));
    } finally {
      store.dispatch(AdminMutationFinishedAction(action.key));
    }
  }

  Future<dynamic> _mutate(AdminMutationAction action) {
    if (action is UpdateAdminProfileAction) {
      return api.updateProfile(action.fields);
    }
    if (action is SetPharmacyStatusAction) {
      return api.setPharmacyStatus(action.pharmacyId, action.status);
    }
    if (action is SetAccountStatusAction) {
      switch (action.role) {
        case 'patient':
          return api.setPatientStatus(action.id, action.status);
        case 'doctor':
          return api.setDoctorStatus(action.id, action.status);
        default:
          return api.setPharmacyStatus(action.id, action.status);
      }
    }
    if (action is CreateGroupAction) return api.createGroup(action.body);
    if (action is UpdateGroupAction) {
      return api.updateGroup(action.groupId, action.body);
    }
    if (action is AddPharmacyToGroupAction) {
      return api.addPharmacyToGroup(action.groupId, action.pharmacyId,
          isPrimary: action.isPrimary);
    }
    if (action is RemovePharmacyFromGroupAction) {
      return api.removePharmacyFromGroup(action.groupId, action.pharmacyId);
    }
    if (action is CreateAgreementAction) return api.createAgreement(action.body);
    if (action is UpdateAgreementAction) {
      return api.updateAgreement(action.agreementId, action.body);
    }
    if (action is ActivateAgreementAction) {
      return api.activateAgreement(action.agreementId);
    }
    if (action is SuspendAgreementAction) {
      return api.suspendAgreement(action.agreementId);
    }
    if (action is AutoCancelExpiredAppointmentsAction) {
      return api.autoCancelExpiredAppointments(
          timeoutMinutes: action.timeoutMinutes);
    }
    if (action is RevertPrescriptionClaimAction) {
      return api.revertPrescriptionClaim(action.prescriptionId,
          reason: action.reason);
    }
    if (action is TestStripeConnectionAction) return api.testStripe();

    throw UnsupportedError('No handler for ${action.runtimeType}');
  }

  /// Reloads resources a write may have changed — only those a screen has
  /// already loaded, and with the same params, so filters and the open detail
  /// view survive the refresh.
  void _refresh(Store<AppState> store, List<AdminResource> resources) {
    for (final resource in resources) {
      final current = store.state.adminState.of(resource);
      if (current.isIdle) continue;
      store.dispatch(
          FetchAdminResourceAction(resource, params: current.params));
    }
  }

  /// A 401 means the 7-day admin token is gone; with no refresh token the
  /// only way on is to sign in again.
  void _reportUnauthorized(Store<AppState> store, Object error) {
    if (error is UnauthorizedFailure && store.state.authState.isAuthenticated) {
      store.dispatch(const SessionExpiredAction());
    }
  }

  static String _message(Object error) =>
      error is Failure ? error.message : 'Something went wrong. Please try again.';
}
