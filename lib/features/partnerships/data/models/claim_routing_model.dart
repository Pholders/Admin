import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/claim_routing.dart';

extension RoutingStatisticsMapper on RoutingStatistics {
  static RoutingStatistics fromJson(Map<String, dynamic> json) {
    return RoutingStatistics(
      totalRoutes: asInt(json['total_routes']),
      acceptedCount: asInt(json['accepted_count']),
      rejectedCount: asInt(json['rejected_count']),
      pendingCount: asInt(json['pending_count']),
      averageResponseSeconds: asDoubleOrNull(json['avg_response_time']),
      minResponseSeconds: asIntOrNull(json['min_response_time']),
      maxResponseSeconds: asIntOrNull(json['max_response_time']),
    );
  }
}

extension TierRoutingStatsMapper on TierRoutingStats {
  static TierRoutingStats fromJson(Map<String, dynamic> json) {
    return TierRoutingStats(
      tier: asString(json['tier'], fallback: 'basic'),
      totalRoutes: asInt(json['total_routes']),
      accepted: asInt(json['accepted']),
      rejected: asInt(json['rejected']),
      acceptanceRate: asIntOrNull(json['acceptance_rate']),
    );
  }
}

extension CandidatePharmacyMapper on CandidatePharmacy {
  static CandidatePharmacy fromJson(Map<String, dynamic> json) {
    return CandidatePharmacy(
      id: asInt(json['id']),
      pharmacyName:
          asString(json['pharmacy_name'], fallback: 'Unnamed pharmacy'),
      tier: asStringOrNull(json['tier']),
      groupId: asIntOrNull(json['group_id']),
      isPrimary: asBool(json['is_primary']),
      commissionRate: asDoubleOrNull(json['commission_rate']),
      claimResponseTimeHours: asIntOrNull(json['claim_response_time_hours']),
      dispensingTimeHours: asIntOrNull(json['dispensing_time_hours']),
      agreementId: asIntOrNull(json['agreement_id']),
      deliveryAvailable: asBool(json['delivery_available']),
      distance: asDoubleOrNull(json['distance']),
    );
  }
}
