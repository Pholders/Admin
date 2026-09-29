import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/compliance.dart';

extension ComplianceSummaryMapper on ComplianceSummary {
  static ComplianceSummary fromJson(Map<String, dynamic> json) {
    return ComplianceSummary(
      totalAgreements: asInt(json['total_agreements']),
      activeAgreements: asInt(json['active_agreements']),
      suspendedAgreements: asInt(json['suspended_agreements']),
      averageComplianceScore: asDoubleOrNull(json['avg_compliance_score']),
      excellentCount: asInt(json['excellent_count']),
      goodCount: asInt(json['good_count']),
      poorCount: asInt(json['poor_count']),
    );
  }
}

extension PharmacyPerformanceMapper on PharmacyPerformance {
  /// Reads a row from either performer list.
  ///
  /// The two queries name the pharmacy's id differently — top performers
  /// select `p.id`, low performers select `ppm.pharmacy_id` — so both keys
  /// are accepted. Rows without either are dropped by the caller.
  static PharmacyPerformance? fromJson(Map<String, dynamic> json) {
    final id = asIntOrNull(json['pharmacy_id']) ?? asIntOrNull(json['id']);
    if (id == null) return null;

    return PharmacyPerformance(
      pharmacyId: id,
      pharmacyName:
          asString(json['pharmacy_name'], fallback: 'Unnamed pharmacy'),
      groupName: asStringOrNull(json['group_name']),
      overallScore: asDoubleOrNull(json['overall_score']),
      acceptanceRate: asDoubleOrNull(json['acceptance_rate']),
      onTimeResponseRate: asDoubleOrNull(json['on_time_response_rate']),
      onTimeDispensingRate: asDoubleOrNull(json['on_time_dispensing_rate']),
      totalClaimsAccepted: asIntOrNull(json['total_claims_accepted']),
      totalClaimsRouted: asIntOrNull(json['total_claims_routed']),
    );
  }
}

extension ComplianceDashboardMapper on ComplianceDashboard {
  static ComplianceDashboard fromJson(Map<String, dynamic> json) {
    List<PharmacyPerformance> performers(Object? raw) => asObjectList(raw)
        .map(PharmacyPerformanceMapper.fromJson)
        .whereType<PharmacyPerformance>()
        .toList();

    return ComplianceDashboard(
      // `summary` is null whenever the dashboard query fails or nothing has
      // been scored — an empty summary renders as zeros rather than crashing.
      summary: ComplianceSummaryMapper.fromJson(asObject(json['summary'])),
      topPerformers: performers(json['topPerformers']),
      lowPerformers: performers(json['lowPerformers']),
    );
  }
}

extension PharmacyAgreementComplianceMapper on PharmacyAgreementCompliance {
  static PharmacyAgreementCompliance fromJson(Map<String, dynamic> json) {
    return PharmacyAgreementCompliance(
      agreementId: asInt(json['agreementId']),
      agreementType: asStringOrNull(json['agreementType']),
      averageCompliance: asDoubleOrNull(json['avg_compliance']),
      recordCount: asInt(json['record_count']),
    );
  }
}

extension PharmacyComplianceStatusMapper on PharmacyComplianceStatus {
  /// This endpoint is hand-assembled in the controller rather than selected,
  /// so its keys are camelCase — except the compliance aggregates spread in
  /// from SQL, which stay snake_case.
  static PharmacyComplianceStatus fromJson(Map<String, dynamic> json) {
    return PharmacyComplianceStatus(
      pharmacyId: asInt(json['pharmacyId']),
      status: asString(json['status'], fallback: 'unknown'),
      overallCompliance: asDoubleOrNull(json['overallCompliance']),
      agreementCount: asInt(json['agreementCount']),
      agreements: asObjectList(json['agreements'])
          .map(PharmacyAgreementComplianceMapper.fromJson)
          .toList(),
    );
  }
}

extension ComplianceReportRowMapper on ComplianceReportRow {
  static ComplianceReportRow fromJson(Map<String, dynamic> json) {
    return ComplianceReportRow(
      agreementId: asInt(json['agreement_id']),
      entityType: asString(json['entity_type'], fallback: 'pharmacy'),
      status: asString(json['status'], fallback: 'unknown'),
      entityName: asStringOrNull(json['entity_name']),
      complianceScore: asDoubleOrNull(json['compliance_score']),
      totalClaims: asInt(json['total_claims']),
      claimsAccepted: asInt(json['claims_accepted']),
      onTimeResponses: asInt(json['on_time_responses']),
      onTimeDispensed: asInt(json['on_time_dispensed']),
      monthDate: asDate(json['month_date']),
    );
  }
}
