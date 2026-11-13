/// Redux actions for the admin data slice.
///
/// Reads go through one generic [FetchAdminResourceAction]. Writes each get a
/// typed [AdminMutationAction] so the payload a screen can send is checked at
/// compile time. As with auth, the network work lives in middleware.
library;

import 'dart:async';

import '../state/admin_state.dart';

// ─── Reads ────────────────────────────────────────────────────────────────────

/// Loads [resource] from the API. [params] are the endpoint's query or path
/// values (see the admin middleware for which keys each resource reads).
class FetchAdminResourceAction {
  final AdminResource resource;
  final Map<String, dynamic> params;

  const FetchAdminResourceAction(this.resource, {this.params = const {}});
}

class AdminResourceLoadedAction {
  final AdminResource resource;
  final Map<String, dynamic> params;
  final dynamic data;

  const AdminResourceLoadedAction(this.resource, this.params, this.data);
}

class AdminResourceFailedAction {
  final AdminResource resource;
  final Map<String, dynamic> params;
  final String error;

  const AdminResourceFailedAction(this.resource, this.params, this.error);
}

/// Forgets a loaded resource, e.g. a detail view that was closed.
class ClearAdminResourceAction {
  final AdminResource resource;

  const ClearAdminResourceAction(this.resource);
}

// ─── Writes ───────────────────────────────────────────────────────────────────

/// Base class for every admin write.
///
/// [completer], when given, completes with the response `data` on success or
/// with the error on failure — this is how a dialog awaits its own submit and
/// shows the server's message. After a success the middleware reloads every
/// resource in [refreshes] that has already been fetched, with the params it
/// was last fetched with.
abstract class AdminMutationAction {
  final Completer<dynamic>? completer;

  const AdminMutationAction({this.completer});

  /// Identifies this operation in `AdminState.pendingMutations`.
  String get key;

  List<AdminResource> get refreshes => const [];
}

class AdminMutationStartedAction {
  final String key;
  const AdminMutationStartedAction(this.key);
}

class AdminMutationFinishedAction {
  final String key;
  const AdminMutationFinishedAction(this.key);
}

// Account

class UpdateAdminProfileAction extends AdminMutationAction {
  /// Any of `first_name`, `last_name`, `phone`. The server ignores `email`.
  final Map<String, dynamic> fields;

  const UpdateAdminProfileAction(this.fields, {super.completer});

  @override
  String get key => 'profile.update';

  @override
  List<AdminResource> get refreshes =>
      const [AdminResource.profile, AdminResource.activityLog];
}

// Pharmacies

/// [status] is one of `active`, `suspended`, `blocked`, `pending`.
class SetPharmacyStatusAction extends AdminMutationAction {
  final Object pharmacyId;
  final String status;

  const SetPharmacyStatusAction(this.pharmacyId, this.status,
      {super.completer});

  @override
  String get key => 'pharmacy.$pharmacyId.status';

  @override
  List<AdminResource> get refreshes => const [
        AdminResource.pharmacies,
        AdminResource.recentUsers,
        AdminResource.dashboardSummary,
      ];
}

/// Approves, suspends, blocks or reopens any account. [role] is `patient`,
/// `doctor` or `pharmacy`; [status] is `active`, `suspended`, `blocked` or
/// `pending`. For patients and doctors, leaving `active` also signs the
/// account out everywhere (the server revokes its sessions).
class SetAccountStatusAction extends AdminMutationAction {
  static const roles = {'patient', 'doctor', 'pharmacy'};

  final String role;
  final Object id;
  final String status;

  SetAccountStatusAction(this.role, this.id, this.status, {super.completer})
      : assert(roles.contains(role), 'Unknown role $role');

  @override
  String get key => 'account.$role.$id.status';

  @override
  List<AdminResource> get refreshes => const [
        AdminResource.patients,
        AdminResource.doctors,
        AdminResource.pharmacies,
        AdminResource.accountDetail,
        AdminResource.recentUsers,
        AdminResource.dashboardSummary,
      ];
}

// Partnership groups

/// [body]: `group_name` (required), `tier` (`premium`/`standard`/`basic`,
/// required), `parent_company`, `description`, `commission_rate`.
class CreateGroupAction extends AdminMutationAction {
  final Map<String, dynamic> body;

  const CreateGroupAction(this.body, {super.completer});

  @override
  String get key => 'group.create';

  @override
  List<AdminResource> get refreshes => const [AdminResource.groups];
}

/// [body]: any of the create fields, plus `is_active`.
class UpdateGroupAction extends AdminMutationAction {
  final Object groupId;
  final Map<String, dynamic> body;

  const UpdateGroupAction(this.groupId, this.body, {super.completer});

  @override
  String get key => 'group.$groupId.update';

  @override
  List<AdminResource> get refreshes =>
      const [AdminResource.groups, AdminResource.groupDetail];
}

class AddPharmacyToGroupAction extends AdminMutationAction {
  final Object groupId;
  final Object pharmacyId;
  final bool isPrimary;

  const AddPharmacyToGroupAction(this.groupId, this.pharmacyId,
      {this.isPrimary = true, super.completer});

  @override
  String get key => 'group.$groupId.add';

  @override
  List<AdminResource> get refreshes =>
      const [AdminResource.groups, AdminResource.groupDetail];
}

class RemovePharmacyFromGroupAction extends AdminMutationAction {
  final Object groupId;
  final Object pharmacyId;

  const RemovePharmacyFromGroupAction(this.groupId, this.pharmacyId,
      {super.completer});

  @override
  String get key => 'group.$groupId.remove.$pharmacyId';

  @override
  List<AdminResource> get refreshes =>
      const [AdminResource.groups, AdminResource.groupDetail];
}

// Partnership agreements

/// [body]: `pharmacy_or_group_id`, `entity_type` (`pharmacy`/`group`),
/// `commission_rate` and `start_date` are required; optional are
/// `agreement_type`, `end_date`, `auto_renew`, `service_fee`,
/// `minimum_monthly_transactions`, `claim_response_time_hours`,
/// `dispensing_time_hours`, `payment_terms`.
class CreateAgreementAction extends AdminMutationAction {
  final Map<String, dynamic> body;

  const CreateAgreementAction(this.body, {super.completer});

  @override
  String get key => 'agreement.create';

  @override
  List<AdminResource> get refreshes =>
      const [AdminResource.agreements, AdminResource.expiringAgreements];
}

/// [body]: any of `commission_rate`, `service_fee`,
/// `claim_response_time_hours`, `dispensing_time_hours`, `payment_terms`,
/// `status`, `end_date`.
class UpdateAgreementAction extends AdminMutationAction {
  final Object agreementId;
  final Map<String, dynamic> body;

  const UpdateAgreementAction(this.agreementId, this.body, {super.completer});

  @override
  String get key => 'agreement.$agreementId.update';

  @override
  List<AdminResource> get refreshes => const [
        AdminResource.agreements,
        AdminResource.expiringAgreements,
        AdminResource.agreementDetail,
      ];
}

class ActivateAgreementAction extends AdminMutationAction {
  final Object agreementId;

  const ActivateAgreementAction(this.agreementId, {super.completer});

  @override
  String get key => 'agreement.$agreementId.status';

  @override
  List<AdminResource> get refreshes => const [
        AdminResource.agreements,
        AdminResource.expiringAgreements,
        AdminResource.agreementDetail,
        AdminResource.complianceDashboard,
      ];
}

class SuspendAgreementAction extends AdminMutationAction {
  final Object agreementId;

  const SuspendAgreementAction(this.agreementId, {super.completer});

  @override
  String get key => 'agreement.$agreementId.status';

  @override
  List<AdminResource> get refreshes => const [
        AdminResource.agreements,
        AdminResource.expiringAgreements,
        AdminResource.agreementDetail,
        AdminResource.complianceDashboard,
      ];
}

// Maintenance

/// Cancels appointments whose payment has been pending longer than
/// [timeoutMinutes] (the server accepts 5–1440).
class AutoCancelExpiredAppointmentsAction extends AdminMutationAction {
  final int timeoutMinutes;

  const AutoCancelExpiredAppointmentsAction(
      {this.timeoutMinutes = 30, super.completer});

  @override
  String get key => 'maintenance.autoCancel';
}

/// Undoes a pharmacy's claim on a prescription. The server requires [reason].
class RevertPrescriptionClaimAction extends AdminMutationAction {
  final String prescriptionId;
  final String reason;

  const RevertPrescriptionClaimAction(this.prescriptionId,
      {required this.reason, super.completer});

  @override
  String get key => 'maintenance.revertClaim';
}

/// Completes with the raw body, `{success, message, error?}`. A failed Stripe
/// connection completes normally with `success: false` rather than as an
/// error, since that is the answer the admin asked for.
class TestStripeConnectionAction extends AdminMutationAction {
  const TestStripeConnectionAction({super.completer});

  @override
  String get key => 'maintenance.stripeTest';
}

// ─── Admin records ────────────────────────────────────────────────────────────

/// Loads one record for a detail dialog and hands it back through
/// [completer] instead of the store (see [AdminRecordKind]). A 401 still ends
/// the session.
class FetchAdminRecordAction {
  final AdminRecordKind kind;
  final Object id;
  final Completer<dynamic> completer;

  FetchAdminRecordAction(this.kind, this.id, this.completer);
}

const _alertResources = [
  AdminResource.securityAlerts,
  AdminResource.securityAlertStats,
  AdminResource.suspiciousUsers,
  AdminResource.securityReport,
];

/// Changes a ticket's [status] and/or [priority]; at least one is required.
/// Completes with the updated ticket, replies included.
class UpdateTicketAction extends AdminMutationAction {
  static const statuses = ['open', 'in_progress', 'resolved', 'closed'];
  static const priorities = ['low', 'normal', 'high', 'urgent'];

  final Object ticketId;
  final String? status;
  final String? priority;

  UpdateTicketAction(this.ticketId,
      {this.status, this.priority, super.completer})
      : assert(status != null || priority != null,
            'Send a status or a priority'),
        assert(status == null || statuses.contains(status)),
        assert(priority == null || priorities.contains(priority));

  @override
  String get key => 'ticket.$ticketId.update';

  @override
  List<AdminResource> get refreshes => const [AdminResource.supportTickets];
}

/// Emails [message] to the ticket's address. Completes with
/// `{email_sent, ticket}`; `email_sent: false` means the reply was saved but
/// not emailed — it must not be resent, which would save a duplicate.
class ReplyToTicketAction extends AdminMutationAction {
  static const maxLength = 5000;

  final Object ticketId;
  final String message;

  const ReplyToTicketAction(this.ticketId, this.message, {super.completer});

  @override
  String get key => 'ticket.$ticketId.reply';

  @override
  List<AdminResource> get refreshes => const [AdminResource.supportTickets];
}

/// Hides a review from the doctor's public page (and their rating), or shows
/// it again. [reason] is required when hiding.
class SetReviewVisibilityAction extends AdminMutationAction {
  static const maxReasonLength = 500;

  final Object reviewId;
  final bool hidden;
  final String? reason;

  SetReviewVisibilityAction(this.reviewId,
      {required this.hidden, this.reason, super.completer})
      : assert(!hidden || (reason != null && reason.trim().isNotEmpty),
            'A reason is required to hide a review');

  @override
  String get key => 'review.$reviewId';

  @override
  List<AdminResource> get refreshes => const [AdminResource.reviews];
}

/// Permanent. Prefer [SetReviewVisibilityAction].
class DeleteReviewAction extends AdminMutationAction {
  final Object reviewId;

  const DeleteReviewAction(this.reviewId, {super.completer});

  @override
  String get key => 'review.$reviewId';

  @override
  List<AdminResource> get refreshes => const [AdminResource.reviews];
}

/// Marks an alert `verified_legit`, `verified_threat` or `dismissed`.
/// `verified_threat` signs the account out of every device and emails its
/// owner. Completes with the updated alert plus `sessions_revoked`.
class ReviewSecurityAlertAction extends AdminMutationAction {
  static const statuses = ['verified_legit', 'verified_threat', 'dismissed'];

  final Object alertId;
  final String status;
  final String? adminNotes;
  final String? actionTaken;

  ReviewSecurityAlertAction(this.alertId,
      {required this.status,
      this.adminNotes,
      this.actionTaken,
      super.completer})
      : assert(statuses.contains(status));

  @override
  String get key => 'alert.$alertId.review';

  @override
  List<AdminResource> get refreshes => _alertResources;
}

/// Reviews up to [maxIds] alerts at once. Completes with
/// `{updated_count, not_found, sessions_revoked}`.
class BulkReviewSecurityAlertsAction extends AdminMutationAction {
  static const maxIds = 200;

  final List<Object> alertIds;
  final String status;
  final String? actionReason;

  BulkReviewSecurityAlertsAction(this.alertIds,
      {required this.status, this.actionReason, super.completer})
      : assert(alertIds.isNotEmpty && alertIds.length <= maxIds),
        assert(ReviewSecurityAlertAction.statuses.contains(status));

  @override
  String get key => 'alert.bulkReview';

  @override
  List<AdminResource> get refreshes => _alertResources;
}

// ─── Startup ──────────────────────────────────────────────────────────────────

/// Loads every screen's first view at once, so tables are already filled when
/// the admin opens them. Dispatched when the app starts with a saved session
/// (which includes a browser refresh) and after signing in.
///
/// Always refetches, even resources already in the store.
class PrefetchAdminDataAction {
  const PrefetchAdminDataAction();
}

/// What [PrefetchAdminDataAction] loads. Each entry's params must equal what
/// its screen first asks for, or the screen fetches again when it opens
/// (`test/admin_prefetch_test.dart` checks this).
///
/// Left out on purpose: detail views (fetched when opened; a prescription
/// open is audit-logged), and lookups that need input first (login
/// locations, compliance report, routing candidates, system logs).
const adminStartupLoads = <(AdminResource, Map<String, dynamic>)>[
  // Dashboard
  (AdminResource.dashboardSummary, {}),
  (AdminResource.dashboardActivity, {'range': 'monthly'}),
  (AdminResource.recentUsers, {'role': 'all', 'limit': 6}),

  // Accounts
  (AdminResource.patients, {'limit': 200, 'offset': 0}),
  (AdminResource.doctors, {'limit': 200, 'offset': 0}),
  (AdminResource.pharmacies, {'limit': 200, 'offset': 0}),
  (AdminResource.reviews, {'limit': 50, 'offset': 0}),

  // Records
  (AdminResource.appointments, {'limit': 50, 'offset': 0}),
  (AdminResource.prescriptions, {'limit': 50, 'offset': 0}),
  (AdminResource.orders, {'limit': 50, 'offset': 0}),
  (AdminResource.payments, {'limit': 50, 'offset': 0}),

  // Partnerships
  (AdminResource.groups, {'is_active': true}),
  (AdminResource.agreements, {}),
  (AdminResource.complianceDashboard, {}),
  (AdminResource.routingStatistics, {}),
  (AdminResource.routingByTier, {}),

  // Security
  (AdminResource.securityAlertStats, {}),
  (AdminResource.securityAlerts, {'status': 'unreviewed', 'limit': 50, 'offset': 0}),
  (AdminResource.suspiciousUsers, {'hours': 24, 'threshold': 3}),
  (AdminResource.securityReport, {}),
  (AdminResource.securityDashboard, {'hours': 24}),

  // Support
  (AdminResource.supportTickets, {'limit': 50, 'offset': 0}),

  // My account
  (AdminResource.profile, {}),
  (AdminResource.sessions, {}),
  (AdminResource.activityLog, {'limit': 50}),
];
