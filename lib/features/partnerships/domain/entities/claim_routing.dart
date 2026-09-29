import 'package:equatable/equatable.dart';

/// Totals from `GET /users/partnerships/routing/statistics`.
///
/// Counts come straight off `claim_routing_history`; response times are in
/// seconds. A claim with `accepted IS NULL` is still awaiting the pharmacy's
/// answer, which is why pending is its own bucket rather than a rejection.
class RoutingStatistics extends Equatable {
  const RoutingStatistics({
    this.totalRoutes = 0,
    this.acceptedCount = 0,
    this.rejectedCount = 0,
    this.pendingCount = 0,
    this.averageResponseSeconds,
    this.minResponseSeconds,
    this.maxResponseSeconds,
  });

  final int totalRoutes;
  final int acceptedCount;
  final int rejectedCount;
  final int pendingCount;
  final double? averageResponseSeconds;
  final int? minResponseSeconds;
  final int? maxResponseSeconds;

  /// Share of routed claims that were accepted, 0–100. Null with no routes.
  double? get acceptanceRate =>
      totalRoutes == 0 ? null : (acceptedCount / totalRoutes) * 100;

  @override
  List<Object?> get props => [
        totalRoutes,
        acceptedCount,
        rejectedCount,
        pendingCount,
        averageResponseSeconds,
        minResponseSeconds,
        maxResponseSeconds,
      ];
}

/// One tier's routing outcomes, from
/// `GET /users/partnerships/routing/by-tier`.
class TierRoutingStats extends Equatable {
  const TierRoutingStats({
    required this.tier,
    this.totalRoutes = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.acceptanceRate,
  });

  final String tier;
  final int totalRoutes;
  final int accepted;
  final int rejected;

  /// Already a whole-number percentage on the server.
  final int? acceptanceRate;

  @override
  List<Object?> get props =>
      [tier, totalRoutes, accepted, rejected, acceptanceRate];
}

/// A pharmacy eligible to receive a claim, from
/// `GET /users/partnerships/routing/candidates`.
///
/// Only pharmacies with an active agreement and a group membership appear.
/// [distance] is a raw lat/long euclidean value, not kilometres — the
/// backend uses it purely for ranking, so it is shown as a rank, never as a
/// distance.
class CandidatePharmacy extends Equatable {
  const CandidatePharmacy({
    required this.id,
    required this.pharmacyName,
    this.tier,
    this.groupId,
    this.isPrimary = false,
    this.commissionRate,
    this.claimResponseTimeHours,
    this.dispensingTimeHours,
    this.agreementId,
    this.deliveryAvailable = false,
    this.distance,
  });

  final int id;
  final String pharmacyName;
  final String? tier;
  final int? groupId;
  final bool isPrimary;
  final double? commissionRate;
  final int? claimResponseTimeHours;
  final int? dispensingTimeHours;
  final int? agreementId;
  final bool deliveryAvailable;
  final double? distance;

  @override
  List<Object?> get props => [
        id,
        pharmacyName,
        tier,
        groupId,
        isPrimary,
        commissionRate,
        claimResponseTimeHours,
        dispensingTimeHours,
        agreementId,
        deliveryAvailable,
        distance,
      ];
}
