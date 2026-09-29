import 'package:equatable/equatable.dart';

import 'claim_routing.dart';
import 'compliance.dart';
import 'pharmacy_agreement.dart';
import 'pharmacy_group.dart';

/// Everything the Partnerships screen shows, gathered in one pass.
///
/// The backend has no combined endpoint, so this is assembled from five
/// parallel calls. Each part is independently nullable-free but may be empty:
/// a fresh deployment with no agreements yet still renders.
class PartnershipOverview extends Equatable {
  const PartnershipOverview({
    required this.groups,
    required this.agreements,
    required this.expiringAgreements,
    required this.compliance,
    required this.routing,
    required this.routingByTier,
  });

  final List<PharmacyGroup> groups;
  final List<PharmacyAgreement> agreements;

  /// Active agreements ending within 30 days, soonest first.
  final List<PharmacyAgreement> expiringAgreements;

  final ComplianceDashboard compliance;
  final RoutingStatistics routing;
  final List<TierRoutingStats> routingByTier;

  int get activeAgreementCount =>
      agreements.where((a) => a.status == 'active').length;

  int get pendingAgreementCount =>
      agreements.where((a) => a.status == 'pending').length;

  int get suspendedAgreementCount =>
      agreements.where((a) => a.status == 'suspended').length;

  /// Live membership total across every group.
  int get pharmacyCount =>
      groups.fold(0, (sum, group) => sum + group.pharmacyCount);

  @override
  List<Object?> get props => [
        groups,
        agreements,
        expiringAgreements,
        compliance,
        routing,
        routingByTier,
      ];
}
