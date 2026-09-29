import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/pharmacy_agreement.dart';

extension PharmacyAgreementMapper on PharmacyAgreement {
  static PharmacyAgreement fromJson(Map<String, dynamic> json) {
    return PharmacyAgreement(
      id: asInt(json['id']),
      pharmacyOrGroupId: asInt(json['pharmacy_or_group_id']),
      entityType: asString(json['entity_type'], fallback: 'pharmacy'),
      status: asString(json['status'], fallback: 'pending'),
      commissionRate: asDouble(json['commission_rate']),
      agreementType: asStringOrNull(json['agreement_type']),
      startDate: asDate(json['start_date']),
      endDate: asDate(json['end_date']),
      autoRenew: asBool(json['auto_renew']),
      serviceFee: asDoubleOrNull(json['service_fee']),
      minimumMonthlyTransactions:
          asIntOrNull(json['minimum_monthly_transactions']),
      claimResponseTimeHours: asIntOrNull(json['claim_response_time_hours']),
      dispensingTimeHours: asIntOrNull(json['dispensing_time_hours']),
      paymentTerms: asStringOrNull(json['payment_terms']),
      entityName: asStringOrNull(json['entity_name']),
      createdAt: asDate(json['created_at']),
    );
  }
}

extension AgreementComplianceAverageMapper on AgreementComplianceAverage {
  static AgreementComplianceAverage fromJson(Map<String, dynamic> json) {
    return AgreementComplianceAverage(
      averageCompliance: asDoubleOrNull(json['avg_compliance']),
      averageResponseCompliance:
          asDoubleOrNull(json['avg_response_compliance']),
      averageDispensingCompliance:
          asDoubleOrNull(json['avg_dispensing_compliance']),
      minCompliance: asDoubleOrNull(json['min_compliance']),
      maxCompliance: asDoubleOrNull(json['max_compliance']),
      recordCount: asInt(json['record_count']),
    );
  }
}

extension ComplianceTrendPointMapper on ComplianceTrendPoint {
  /// Returns null for a row with no `month_date` — the column is NOT NULL, so
  /// that only happens if the shape changes, and a point without a month
  /// cannot be plotted.
  static ComplianceTrendPoint? fromJson(Map<String, dynamic> json) {
    final month = asDate(json['month_date']);
    if (month == null) return null;

    return ComplianceTrendPoint(
      monthDate: month,
      totalClaims: asInt(json['total_claims']),
      claimsAccepted: asInt(json['claims_accepted']),
      complianceScore: asDoubleOrNull(json['compliance_score']),
      responseTimeCompliance: asDoubleOrNull(json['response_time_compliance']),
      dispensingTimeCompliance:
          asDoubleOrNull(json['dispensing_time_compliance']),
    );
  }
}

extension PharmacyAgreementDetailMapper on PharmacyAgreementDetail {
  /// The agreement's own columns sit at the top level, with `compliance` and
  /// `trends` nested beside them.
  static PharmacyAgreementDetail fromJson(Map<String, dynamic> json) {
    return PharmacyAgreementDetail(
      agreement: PharmacyAgreementMapper.fromJson(json),
      compliance: AgreementComplianceAverageMapper.fromJson(
          asObject(json['compliance'])),
      trends: asObjectList(json['trends'])
          .map(ComplianceTrendPointMapper.fromJson)
          .whereType<ComplianceTrendPoint>()
          .toList(),
      complianceRecords: asInt(json['compliance_records']),
    );
  }
}
