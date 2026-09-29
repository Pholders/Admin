/// Redux actions for the pharmacy partnership state slice.
///
/// Actions only describe an event — the network work lives in
/// [PartnershipMiddleware].
library;

import '../../features/partnerships/domain/entities/partnership_overview.dart';
import '../../features/partnerships/domain/entities/pharmacy_group.dart';
import '../../features/partnerships/domain/usecases/partnership_usecases.dart';

// ─── Pharmacy directory ──────────────────────────────────────────────────────

/// Loads every pharmacy visible to the admin, with its group and tier.
class LoadPharmacyDirectoryAction {
  const LoadPharmacyDirectoryAction();
}

class PharmacyDirectoryLoadedAction {
  const PharmacyDirectoryLoadedAction(this.directory);

  final PharmacyDirectory directory;
}

class PharmacyDirectoryFailedAction {
  const PharmacyDirectoryFailedAction(this.errorMessage);

  final String errorMessage;
}

// ─── Partnership overview ────────────────────────────────────────────────────

class LoadPartnershipOverviewAction {
  const LoadPartnershipOverviewAction();
}

class PartnershipOverviewLoadedAction {
  const PartnershipOverviewLoadedAction(this.overview);

  final PartnershipOverview overview;
}

class PartnershipOverviewFailedAction {
  const PartnershipOverviewFailedAction(this.errorMessage);

  final String errorMessage;
}

// ─── Mutations ───────────────────────────────────────────────────────────────

class CreatePharmacyGroupAction {
  const CreatePharmacyGroupAction(this.params);

  final CreateGroupParams params;
}

class UpdatePharmacyGroupAction {
  const UpdatePharmacyGroupAction(this.params);

  final UpdateGroupParams params;
}

class AssignPharmacyToGroupAction {
  const AssignPharmacyToGroupAction(this.params);

  final GroupMembershipParams params;
}

class MovePharmacyToGroupAction {
  const MovePharmacyToGroupAction(this.params);

  final MovePharmacyParams params;
}

class RemovePharmacyFromGroupAction {
  const RemovePharmacyFromGroupAction(this.params);

  final GroupMembershipParams params;
}

class CreateAgreementAction {
  const CreateAgreementAction(this.params);

  final CreateAgreementParams params;
}

class SetAgreementStatusAction {
  const SetAgreementStatusAction(this.params);

  final SetAgreementStatusParams params;
}

/// A mutation landed. The middleware reloads whatever it invalidated —
/// membership changes the directory, agreement changes the overview.
class PartnershipActionSucceededAction {
  const PartnershipActionSucceededAction(this.message);

  final String message;
}

class PartnershipActionFailedAction {
  const PartnershipActionFailedAction(this.errorMessage);

  final String errorMessage;
}

/// Dismisses the success/error banner once it has been shown.
class ClearPartnershipMessagesAction {
  const ClearPartnershipMessagesAction();
}
