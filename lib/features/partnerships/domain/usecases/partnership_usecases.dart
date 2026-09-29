import '../../../../core/usecases/usecase.dart';
import '../entities/claim_routing.dart';
import '../entities/compliance.dart';
import '../entities/partnership_overview.dart';
import '../entities/pharmacy_agreement.dart';
import '../entities/pharmacy_group.dart';
import '../repositories/partnership_repository.dart';

/// Loads the Pharmacies directory — every pharmacy, with its group and tier.
class LoadPharmacyDirectoryUseCase
    implements UseCase<PharmacyDirectory, NoParams> {
  const LoadPharmacyDirectoryUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyDirectory> call(NoParams params) =>
      repository.getPharmacyDirectory();
}

/// Loads the Partnerships screen in one go.
///
/// The five calls are independent, so they run together rather than in
/// sequence — on a cold-started Render dyno, serialising them would stack
/// five timeouts.
class LoadPartnershipOverviewUseCase
    implements UseCase<PartnershipOverview, NoParams> {
  const LoadPartnershipOverviewUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PartnershipOverview> call(NoParams params) async {
    final results = await Future.wait([
      repository.getGroups(isActive: null),
      repository.getAgreements(),
      repository.getComplianceDashboard(),
      repository.getRoutingStatistics(),
      repository.getRoutingByTier(),
    ]);

    final agreements = results[1] as List<PharmacyAgreement>;

    return PartnershipOverview(
      groups: results[0] as List<PharmacyGroup>,
      agreements: agreements,
      // Derived from the agreements already in hand — the dedicated
      // `/agreements/expiring` route is shadowed by `/agreements/:id`.
      expiringAgreements: _expiringWithin(agreements, 30),
      compliance: results[2] as ComplianceDashboard,
      routing: results[3] as RoutingStatistics,
      routingByTier: results[4] as List<TierRoutingStats>,
    );
  }

  static List<PharmacyAgreement> _expiringWithin(
    List<PharmacyAgreement> agreements,
    int days,
  ) {
    final expiring = agreements.where((a) {
      if (a.status != 'active') return false;
      final remaining = a.daysUntilExpiry;
      return remaining != null && remaining >= 0 && remaining <= days;
    }).toList();

    expiring.sort((a, b) => a.endDate!.compareTo(b.endDate!));
    return expiring;
  }
}

class GetGroupDetailUseCase implements UseCase<PharmacyGroupDetail, int> {
  const GetGroupDetailUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyGroupDetail> call(int groupId) =>
      repository.getGroupDetail(groupId);
}

class CreateGroupParams {
  const CreateGroupParams({
    required this.groupName,
    required this.tier,
    this.parentCompany,
    this.description,
    this.commissionRate,
  });

  final String groupName;
  final String tier;
  final String? parentCompany;
  final String? description;
  final double? commissionRate;
}

class CreateGroupUseCase implements UseCase<PharmacyGroup, CreateGroupParams> {
  const CreateGroupUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyGroup> call(CreateGroupParams params) => repository.createGroup(
        groupName: params.groupName,
        tier: params.tier,
        parentCompany: params.parentCompany,
        description: params.description,
        commissionRate: params.commissionRate,
      );
}

class UpdateGroupParams {
  const UpdateGroupParams({
    required this.groupId,
    this.groupName,
    this.parentCompany,
    this.tier,
    this.description,
    this.commissionRate,
    this.isActive,
  });

  final int groupId;
  final String? groupName;
  final String? parentCompany;
  final String? tier;
  final String? description;
  final double? commissionRate;
  final bool? isActive;
}

class UpdateGroupUseCase implements UseCase<PharmacyGroup, UpdateGroupParams> {
  const UpdateGroupUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyGroup> call(UpdateGroupParams params) =>
      repository.updateGroup(
        params.groupId,
        groupName: params.groupName,
        parentCompany: params.parentCompany,
        tier: params.tier,
        description: params.description,
        commissionRate: params.commissionRate,
        isActive: params.isActive,
      );
}

class GroupMembershipParams {
  const GroupMembershipParams({
    required this.groupId,
    required this.pharmacyId,
    this.isPrimary = true,
  });

  final int groupId;
  final int pharmacyId;
  final bool isPrimary;
}

class AssignPharmacyToGroupUseCase
    implements UseCase<void, GroupMembershipParams> {
  const AssignPharmacyToGroupUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<void> call(GroupMembershipParams params) =>
      repository.addPharmacyToGroup(
        groupId: params.groupId,
        pharmacyId: params.pharmacyId,
        isPrimary: params.isPrimary,
      );
}

class RemovePharmacyFromGroupUseCase
    implements UseCase<void, GroupMembershipParams> {
  const RemovePharmacyFromGroupUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<void> call(GroupMembershipParams params) =>
      repository.removePharmacyFromGroup(
        groupId: params.groupId,
        pharmacyId: params.pharmacyId,
      );
}

class MovePharmacyParams {
  const MovePharmacyParams({
    required this.pharmacyId,
    required this.fromGroupId,
    required this.toGroupId,
  });

  final int pharmacyId;
  final int fromGroupId;
  final int toGroupId;
}

/// Moves a pharmacy from one group to another.
///
/// The API has no move endpoint, so this is an add followed by a remove — in
/// that order deliberately. `pharmacy_group_members` is unique per
/// (pharmacy, group) rather than per pharmacy, so the pharmacy can hold both
/// memberships for the moment between the two calls. If the remove then
/// fails the pharmacy sits in two groups, which the directory tolerates; the
/// reverse order would drop it out of every group and out of the admin's
/// view entirely.
class MovePharmacyToGroupUseCase implements UseCase<void, MovePharmacyParams> {
  const MovePharmacyToGroupUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<void> call(MovePharmacyParams params) async {
    await repository.addPharmacyToGroup(
      groupId: params.toGroupId,
      pharmacyId: params.pharmacyId,
    );
    await repository.removePharmacyFromGroup(
      groupId: params.fromGroupId,
      pharmacyId: params.pharmacyId,
    );
  }
}

class CreateAgreementParams {
  const CreateAgreementParams({
    required this.pharmacyOrGroupId,
    required this.entityType,
    required this.commissionRate,
    this.agreementType,
    this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.serviceFee,
    this.minimumMonthlyTransactions,
    this.claimResponseTimeHours,
    this.dispensingTimeHours,
    this.paymentTerms,
  });

  final int pharmacyOrGroupId;
  final String entityType;
  final double commissionRate;
  final String? agreementType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final double? serviceFee;
  final int? minimumMonthlyTransactions;
  final int? claimResponseTimeHours;
  final int? dispensingTimeHours;
  final String? paymentTerms;
}

class CreateAgreementUseCase
    implements UseCase<PharmacyAgreement, CreateAgreementParams> {
  const CreateAgreementUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyAgreement> call(CreateAgreementParams params) =>
      repository.createAgreement(
        pharmacyOrGroupId: params.pharmacyOrGroupId,
        entityType: params.entityType,
        commissionRate: params.commissionRate,
        agreementType: params.agreementType,
        startDate: params.startDate,
        endDate: params.endDate,
        autoRenew: params.autoRenew,
        serviceFee: params.serviceFee,
        minimumMonthlyTransactions: params.minimumMonthlyTransactions,
        claimResponseTimeHours: params.claimResponseTimeHours,
        dispensingTimeHours: params.dispensingTimeHours,
        paymentTerms: params.paymentTerms,
      );
}

/// Moves an agreement between `active` and `suspended`.
///
/// These are separate POST routes rather than a status field, because the
/// server also stamps `activated_at` / clears it when suspending.
class SetAgreementStatusParams {
  const SetAgreementStatusParams({
    required this.agreementId,
    required this.activate,
  });

  final int agreementId;

  /// True activates, false suspends.
  final bool activate;
}

class SetAgreementStatusUseCase
    implements UseCase<PharmacyAgreement, SetAgreementStatusParams> {
  const SetAgreementStatusUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyAgreement> call(SetAgreementStatusParams params) =>
      params.activate
          ? repository.activateAgreement(params.agreementId)
          : repository.suspendAgreement(params.agreementId);
}

class GetAgreementDetailUseCase
    implements UseCase<PharmacyAgreementDetail, int> {
  const GetAgreementDetailUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyAgreementDetail> call(int agreementId) =>
      repository.getAgreementDetail(agreementId);
}

class GetPharmacyComplianceUseCase
    implements UseCase<PharmacyComplianceStatus, int> {
  const GetPharmacyComplianceUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<PharmacyComplianceStatus> call(int pharmacyId) =>
      repository.getPharmacyCompliance(pharmacyId);
}

class ComplianceReportParams {
  const ComplianceReportParams({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;
}

class GetComplianceReportUseCase
    implements UseCase<List<ComplianceReportRow>, ComplianceReportParams> {
  const GetComplianceReportUseCase(this.repository);

  final PartnershipRepository repository;

  @override
  Future<List<ComplianceReportRow>> call(ComplianceReportParams params) =>
      repository.getComplianceReport(
        startDate: params.startDate,
        endDate: params.endDate,
      );
}
