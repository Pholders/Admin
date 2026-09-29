import 'package:equatable/equatable.dart';

/// A partnership agreement with one pharmacy or one group.
///
/// Mirrors a `pharmacy_agreements` row. [entityType] decides what
/// [pharmacyOrGroupId] points at — there is no foreign key, so the id alone
/// is ambiguous without it.
class PharmacyAgreement extends Equatable {
  const PharmacyAgreement({
    required this.id,
    required this.pharmacyOrGroupId,
    required this.entityType,
    required this.status,
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
    this.entityName,
    this.createdAt,
  });

  final int id;
  final int pharmacyOrGroupId;

  /// `pharmacy` or `group`.
  final String entityType;

  /// `pending`, `active`, `suspended`, `expired` or `terminated`.
  final String status;

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

  /// Only the detail endpoint resolves the counterparty's name; the list
  /// endpoint (`GET /partnerships/agreements`) returns the bare row, so this
  /// is null there.
  final String? entityName;

  final DateTime? createdAt;

  bool get isGroupAgreement => entityType == 'group';

  /// Days until [endDate], negative once past. Null for open-ended agreements.
  int? get daysUntilExpiry {
    final end = endDate;
    if (end == null) return null;
    final today = DateTime.now();
    return DateTime(end.year, end.month, end.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  @override
  List<Object?> get props => [
        id,
        pharmacyOrGroupId,
        entityType,
        status,
        commissionRate,
        agreementType,
        startDate,
        endDate,
        autoRenew,
        serviceFee,
        minimumMonthlyTransactions,
        claimResponseTimeHours,
        dispensingTimeHours,
        paymentTerms,
        entityName,
        createdAt,
      ];
}

/// Averaged compliance across every month recorded for one agreement.
class AgreementComplianceAverage extends Equatable {
  const AgreementComplianceAverage({
    this.averageCompliance,
    this.averageResponseCompliance,
    this.averageDispensingCompliance,
    this.minCompliance,
    this.maxCompliance,
    this.recordCount = 0,
  });

  final double? averageCompliance;
  final double? averageResponseCompliance;
  final double? averageDispensingCompliance;
  final double? minCompliance;
  final double? maxCompliance;
  final int recordCount;

  bool get hasData => recordCount > 0 && averageCompliance != null;

  @override
  List<Object?> get props => [
        averageCompliance,
        averageResponseCompliance,
        averageDispensingCompliance,
        minCompliance,
        maxCompliance,
        recordCount,
      ];
}

/// One month of compliance history for an agreement.
class ComplianceTrendPoint extends Equatable {
  const ComplianceTrendPoint({
    required this.monthDate,
    this.totalClaims = 0,
    this.claimsAccepted = 0,
    this.complianceScore,
    this.responseTimeCompliance,
    this.dispensingTimeCompliance,
  });

  final DateTime monthDate;
  final int totalClaims;
  final int claimsAccepted;
  final double? complianceScore;
  final double? responseTimeCompliance;
  final double? dispensingTimeCompliance;

  @override
  List<Object?> get props => [
        monthDate,
        totalClaims,
        claimsAccepted,
        complianceScore,
        responseTimeCompliance,
        dispensingTimeCompliance,
      ];
}

/// The full payload of `GET /users/partnerships/agreements/:agreementId`.
class PharmacyAgreementDetail extends Equatable {
  const PharmacyAgreementDetail({
    required this.agreement,
    required this.compliance,
    required this.trends,
    this.complianceRecords = 0,
  });

  final PharmacyAgreement agreement;
  final AgreementComplianceAverage compliance;

  /// Newest month first — the backend orders `month_date DESC`.
  final List<ComplianceTrendPoint> trends;

  final int complianceRecords;

  @override
  List<Object?> get props =>
      [agreement, compliance, trends, complianceRecords];
}
