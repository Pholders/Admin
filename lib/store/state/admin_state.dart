import 'package:equatable/equatable.dart';

/// Every read-only admin endpoint the app loads into the store.
///
/// One generic slot per endpoint keeps the slice small: adding an endpoint
/// means one enum value here and one case in the admin middleware, not a new
/// state class, reducer and action family each time.
enum AdminResource {
  // Your account
  profile,
  sessions,
  activityLog,

  // Dashboard
  dashboardSummary,
  dashboardActivity,
  recentUsers,

  // Accounts
  pharmacies,
  patients,
  doctors,

  /// One patient or doctor, for the View dialog.
  accountDetail,

  // Security
  securityDashboard,
  userLocations,

  // Partnership groups
  groups,
  groupDetail,

  // Partnership agreements
  agreements,
  expiringAgreements,
  agreementDetail,

  // Compliance & claim routing
  complianceDashboard,
  pharmacyCompliance,
  complianceReport,
  routingCandidates,
  routingStatistics,
  routingByTier,

  // System
  systemLogs,
}

enum LoadStatus { idle, loading, success, failure }

/// The state of one endpoint: what was asked for ([params]), and what came
/// back ([data]) or why it didn't ([error]).
///
/// [data] is the response's `data` field as decoded JSON. It is kept as-is
/// rather than mapped onto model classes because several of these payloads
/// are raw SQL rows whose columns change with the backend's queries.
class RemoteData extends Equatable {
  final LoadStatus status;
  final dynamic data;
  final String? error;
  final Map<String, dynamic> params;
  final DateTime? updatedAt;

  const RemoteData({
    this.status = LoadStatus.idle,
    this.data,
    this.error,
    this.params = const {},
    this.updatedAt,
  });

  static const RemoteData idle = RemoteData();

  bool get isIdle => status == LoadStatus.idle;
  bool get isLoading => status == LoadStatus.loading;
  bool get hasError => status == LoadStatus.failure;

  /// True once any response has arrived — stays true during a reload, so a
  /// screen can keep showing the previous data under a progress indicator.
  bool get hasData => updatedAt != null;

  @override
  List<Object?> get props => [status, data, error, params, updatedAt];
}

/// Admin data loaded from the API, plus which write operations are in flight.
class AdminState extends Equatable {
  final Map<AdminResource, RemoteData> resources;

  /// Keys of mutations currently running (see `AdminMutationAction.key`), so a
  /// button can show a spinner and refuse a double submit.
  final Set<String> pendingMutations;

  const AdminState({
    this.resources = const {},
    this.pendingMutations = const {},
  });

  factory AdminState.initial() => const AdminState();

  RemoteData of(AdminResource resource) =>
      resources[resource] ?? RemoteData.idle;

  bool isPending(String mutationKey) => pendingMutations.contains(mutationKey);

  AdminState withResource(AdminResource resource, RemoteData value) =>
      AdminState(
        resources: {...resources, resource: value},
        pendingMutations: pendingMutations,
      );

  AdminState withPending(Set<String> pending) =>
      AdminState(resources: resources, pendingMutations: pending);

  @override
  List<Object?> get props => [resources, pendingMutations];
}
