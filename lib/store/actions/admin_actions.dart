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
