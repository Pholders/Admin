import 'package:equatable/equatable.dart';

/// Headline numbers on `GET /users/partnerships/compliance/dashboard`.
///
/// Every field is computed over the single most recent `month_date` in
/// `agreement_compliance`, so an empty compliance table yields all-null
/// aggregates rather than zeros — hence the nullable score.
class ComplianceSummary extends Equatable {
  const ComplianceSummary({
    this.totalAgreements = 0,
    this.activeAgreements = 0,
    this.suspendedAgreements = 0,
    this.averageComplianceScore,
    this.excellentCount = 0,
    this.goodCount = 0,
    this.poorCount = 0,
  });

  final int totalAgreements;
  final int activeAgreements;
  final int suspendedAgreements;

  /// Mean `compliance_score` for the latest month, or null when nothing has
  /// been scored yet.
  final double? averageComplianceScore;

  /// Score ≥ 90.
  final int excellentCount;

  /// Score 80–89.
  final int goodCount;

  /// Score < 80.
  final int poorCount;

  @override
  List<Object?> get props => [
        totalAgreements,
        activeAgreements,
        suspendedAgreements,
        averageComplianceScore,
        excellentCount,
        goodCount,
        poorCount,
      ];
}

/// A pharmacy in the dashboard's top/low performer lists.
///
/// The two lists are not symmetric on the server: low performers carry the
/// full metric set, while the top-performers query only projects the
/// pharmacy and its group. Fields absent from one list stay null.
class PharmacyPerformance extends Equatable {
  const PharmacyPerformance({
    required this.pharmacyId,
    required this.pharmacyName,
    this.groupName,
    this.overallScore,
    this.acceptanceRate,
    this.onTimeResponseRate,
    this.onTimeDispensingRate,
    this.totalClaimsAccepted,
    this.totalClaimsRouted,
  });

  final int pharmacyId;
  final String pharmacyName;
  final String? groupName;
  final double? overallScore;
  final double? acceptanceRate;
  final double? onTimeResponseRate;
  final double? onTimeDispensingRate;
  final int? totalClaimsAccepted;
  final int? totalClaimsRouted;

  @override
  List<Object?> get props => [
        pharmacyId,
        pharmacyName,
        groupName,
        overallScore,
        acceptanceRate,
        onTimeResponseRate,
        onTimeDispensingRate,
        totalClaimsAccepted,
        totalClaimsRouted,
      ];
}

/// The full payload of `GET /users/partnerships/compliance/dashboard`.
class ComplianceDashboard extends Equatable {
  const ComplianceDashboard({
    required this.summary,
    required this.topPerformers,
    required this.lowPerformers,
  });

  final ComplianceSummary summary;
  final List<PharmacyPerformance> topPerformers;

  /// Pharmacies scoring below 70 — the backend's own threshold.
  final List<PharmacyPerformance> lowPerformers;

  @override
  List<Object?> get props => [summary, topPerformers, lowPerformers];
}

/// Compliance for one agreement of one pharmacy, from
/// `GET /users/partnerships/compliance/pharmacy/:pharmacyId`.
class PharmacyAgreementCompliance extends Equatable {
  const PharmacyAgreementCompliance({
    required this.agreementId,
    this.agreementType,
    this.averageCompliance,
    this.recordCount = 0,
  });

  final int agreementId;
  final String? agreementType;
  final double? averageCompliance;
  final int recordCount;

  @override
  List<Object?> get props =>
      [agreementId, agreementType, averageCompliance, recordCount];
}

/// One pharmacy's overall compliance standing.
///
/// When the pharmacy has no agreements the backend answers
/// `{status: 'no_agreements', pharmacyId}` with no scores at all — that case
/// is [hasAgreements] == false, not a zero score.
class PharmacyComplianceStatus extends Equatable {
  const PharmacyComplianceStatus({
    required this.pharmacyId,
    required this.status,
    this.overallCompliance,
    this.agreementCount = 0,
    this.agreements = const [],
  });

  final int pharmacyId;

  /// `excellent` (≥90), `good` (≥80), `fair` (≥70), `poor`, or
  /// `no_agreements`.
  final String status;

  final double? overallCompliance;
  final int agreementCount;
  final List<PharmacyAgreementCompliance> agreements;

  bool get hasAgreements => status != 'no_agreements' && agreementCount > 0;

  @override
  List<Object?> get props =>
      [pharmacyId, status, overallCompliance, agreementCount, agreements];
}

/// One row of `GET /users/partnerships/compliance/report`.
class ComplianceReportRow extends Equatable {
  const ComplianceReportRow({
    required this.agreementId,
    required this.entityType,
    required this.status,
    this.entityName,
    this.complianceScore,
    this.totalClaims = 0,
    this.claimsAccepted = 0,
    this.onTimeResponses = 0,
    this.onTimeDispensed = 0,
    this.monthDate,
  });

  final int agreementId;
  final String entityType;
  final String status;
  final String? entityName;
  final double? complianceScore;
  final int totalClaims;
  final int claimsAccepted;
  final int onTimeResponses;
  final int onTimeDispensed;
  final DateTime? monthDate;

  @override
  List<Object?> get props => [
        agreementId,
        entityType,
        status,
        entityName,
        complianceScore,
        totalClaims,
        claimsAccepted,
        onTimeResponses,
        onTimeDispensed,
        monthDate,
      ];
}
