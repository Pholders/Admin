import '../../../../core/error/failures.dart';
import '../../../../core/network/authenticated_api.dart';
import '../../domain/entities/claim_routing.dart';
import '../../domain/entities/compliance.dart';
import '../../domain/entities/pharmacy_agreement.dart';
import '../../domain/entities/pharmacy_group.dart';
import '../../domain/repositories/partnership_repository.dart';
import '../models/claim_routing_model.dart';
import '../models/compliance_model.dart';
import '../models/pharmacy_agreement_model.dart';
import '../models/pharmacy_group_model.dart';

class PartnershipRepositoryImpl implements PartnershipRepository {
  PartnershipRepositoryImpl({required this.api});

  final AuthenticatedApi api;

  static const _base = '/users/partnerships';

  /// Postgres `DATE` columns are written as plain `YYYY-MM-DD`; sending a
  /// full ISO timestamp makes the server store the UTC day, which can be the
  /// day before the one the admin picked.
  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  /// Drops null entries so a partial update never blanks a column.
  static Map<String, dynamic> _body(Map<String, dynamic> fields) => {
        for (final entry in fields.entries)
          if (entry.value != null) entry.key: entry.value,
      };

  // ─── Groups ───────────────────────────────────────────────────────────────

  @override
  Future<List<PharmacyGroup>> getGroups({
    String? tier,
    bool? isActive = true,
    int limit = 50,
    int offset = 0,
  }) async {
    if (isActive == null) {
      // See the interface: the server always applies the is_active filter, so
      // "all groups" is the union of the two possible values.
      final both = await Future.wait([
        getGroups(tier: tier, isActive: true, limit: limit, offset: offset),
        getGroups(tier: tier, isActive: false, limit: limit, offset: offset),
      ]);
      return [...both.first, ...both.last];
    }

    final response = await api.get(
      '$_base/groups',
      queryParameters: {
        if (tier != null) 'tier': tier,
        'is_active': isActive.toString(),
        'limit': limit,
        'offset': offset,
      },
      fallbackError: 'Could not load pharmacy groups.',
    );

    return response.dataList.map(PharmacyGroupMapper.fromJson).toList();
  }

  @override
  Future<PharmacyGroupDetail> getGroupDetail(int groupId) async {
    final response = await api.get(
      '$_base/groups/$groupId',
      fallbackError: 'Could not load that pharmacy group.',
    );
    return PharmacyGroupDetailMapper.fromJson(response.dataObject);
  }

  @override
  Future<List<PharmacyGroup>> searchGroups(String term) async {
    final needle = term.trim().toLowerCase();
    final groups = await getGroups(isActive: null);
    if (needle.isEmpty) return groups;

    return groups
        .where((g) =>
            g.groupName.toLowerCase().contains(needle) ||
            (g.parentCompany?.toLowerCase().contains(needle) ?? false))
        .toList();
  }

  @override
  Future<PharmacyGroup> createGroup({
    required String groupName,
    required String tier,
    String? parentCompany,
    String? description,
    double? commissionRate,
  }) async {
    final response = await api.post(
      '$_base/groups',
      data: _body({
        'group_name': groupName,
        // Required by the controller's validator even when unchanged — it
        // rejects anything outside premium/standard/basic, null included.
        'tier': tier,
        'parent_company': parentCompany,
        'description': description,
        'commission_rate': commissionRate,
      }),
      fallbackError: 'Could not create that pharmacy group.',
    );
    return PharmacyGroupMapper.fromJson(response.dataObject);
  }

  @override
  Future<PharmacyGroup> updateGroup(
    int groupId, {
    String? groupName,
    String? parentCompany,
    String? tier,
    String? description,
    double? commissionRate,
    bool? isActive,
  }) async {
    final response = await api.put(
      '$_base/groups/$groupId',
      data: _body({
        'group_name': groupName,
        'parent_company': parentCompany,
        'tier': tier,
        'description': description,
        'commission_rate': commissionRate,
        'is_active': isActive,
      }),
      fallbackError: 'Could not update that pharmacy group.',
    );
    return PharmacyGroupMapper.fromJson(response.dataObject);
  }

  @override
  Future<void> addPharmacyToGroup({
    required int groupId,
    required int pharmacyId,
    bool isPrimary = true,
  }) async {
    await api.post(
      '$_base/groups/$groupId/pharmacies',
      data: {'pharmacy_id': pharmacyId, 'is_primary': isPrimary},
      fallbackError: 'Could not add that pharmacy to the group.',
    );
  }

  @override
  Future<void> removePharmacyFromGroup({
    required int groupId,
    required int pharmacyId,
  }) async {
    await api.delete(
      '$_base/groups/$groupId/pharmacies/$pharmacyId',
      fallbackError: 'Could not remove that pharmacy from the group.',
    );
  }

  @override
  Future<PharmacyDirectory> getPharmacyDirectory() async {
    final groups = await getGroups(isActive: null);
    if (groups.isEmpty) return const PharmacyDirectory.empty();

    final details = await Future.wait(
      groups.map((group) => getGroupDetail(group.id)),
    );

    // A pharmacy may hold membership in more than one group
    // (`pharmacy_group_members` is unique per pair, not per pharmacy). The
    // first group wins so the directory shows one row per pharmacy.
    final seen = <int>{};
    final directory = <PharmacyDirectoryEntry>[];

    for (final detail in details) {
      for (final pharmacy in detail.pharmacies) {
        if (!seen.add(pharmacy.id)) continue;
        directory.add(PharmacyDirectoryEntry(
          pharmacy: pharmacy,
          groupId: detail.group.id,
          groupName: detail.group.groupName,
          tier: detail.group.tier,
        ));
      }
    }

    directory.sort((a, b) =>
        a.pharmacy.pharmacyName.toLowerCase().compareTo(
              b.pharmacy.pharmacyName.toLowerCase(),
            ));
    return PharmacyDirectory(groups: groups, entries: directory);
  }

  // ─── Agreements ───────────────────────────────────────────────────────────

  @override
  Future<List<PharmacyAgreement>> getAgreements({
    String? entityType,
    String? status,
    int? pharmacyOrGroupId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await api.get(
      '$_base/agreements',
      queryParameters: {
        if (entityType != null) 'entity_type': entityType,
        if (status != null) 'status': status,
        if (pharmacyOrGroupId != null)
          'pharmacy_or_group_id': pharmacyOrGroupId,
        'limit': limit,
        'offset': offset,
      },
      fallbackError: 'Could not load partnership agreements.',
    );
    return response.dataList.map(PharmacyAgreementMapper.fromJson).toList();
  }

  @override
  Future<PharmacyAgreementDetail> getAgreementDetail(int agreementId) async {
    final response = await api.get(
      '$_base/agreements/$agreementId',
      fallbackError: 'Could not load that agreement.',
    );
    return PharmacyAgreementDetailMapper.fromJson(response.dataObject);
  }

  @override
  Future<List<PharmacyAgreement>> getExpiringAgreements({
    int days = 30,
  }) async {
    final active = await getAgreements(status: 'active');
    final expiring = active.where((a) {
      final remaining = a.daysUntilExpiry;
      // Open-ended agreements never expire; already-expired ones are the
      // server's `getExpiredAgreements` case, not this one.
      return remaining != null && remaining >= 0 && remaining <= days;
    }).toList();

    expiring.sort((a, b) => a.endDate!.compareTo(b.endDate!));
    return expiring;
  }

  @override
  Future<PharmacyAgreement> createAgreement({
    required int pharmacyOrGroupId,
    required String entityType,
    required double commissionRate,
    String? agreementType,
    DateTime? startDate,
    DateTime? endDate,
    bool autoRenew = false,
    double? serviceFee,
    int? minimumMonthlyTransactions,
    int? claimResponseTimeHours,
    int? dispensingTimeHours,
    String? paymentTerms,
  }) async {
    final response = await api.post(
      '$_base/agreements',
      data: _body({
        'pharmacy_or_group_id': pharmacyOrGroupId,
        'entity_type': entityType,
        'commission_rate': commissionRate,
        'agreement_type': agreementType,
        // `start_date` is NOT NULL with no default, so an omitted date makes
        // the insert fail — default to today rather than surfacing a 500.
        'start_date': _date(startDate ?? DateTime.now()),
        'end_date': endDate == null ? null : _date(endDate),
        'auto_renew': autoRenew,
        'service_fee': serviceFee,
        'minimum_monthly_transactions': minimumMonthlyTransactions,
        'claim_response_time_hours': claimResponseTimeHours,
        'dispensing_time_hours': dispensingTimeHours,
        'payment_terms': paymentTerms,
      }),
      fallbackError: 'Could not create that agreement.',
    );
    return PharmacyAgreementMapper.fromJson(response.dataObject);
  }

  @override
  Future<PharmacyAgreement> updateAgreement(
    int agreementId, {
    double? commissionRate,
    double? serviceFee,
    int? claimResponseTimeHours,
    int? dispensingTimeHours,
    String? paymentTerms,
    String? status,
    DateTime? endDate,
  }) async {
    final response = await api.put(
      '$_base/agreements/$agreementId',
      data: _body({
        'commission_rate': commissionRate,
        'service_fee': serviceFee,
        'claim_response_time_hours': claimResponseTimeHours,
        'dispensing_time_hours': dispensingTimeHours,
        'payment_terms': paymentTerms,
        'status': status,
        'end_date': endDate == null ? null : _date(endDate),
      }),
      fallbackError: 'Could not update that agreement.',
    );
    return PharmacyAgreementMapper.fromJson(response.dataObject);
  }

  @override
  Future<PharmacyAgreement> activateAgreement(int agreementId) async {
    final response = await api.post(
      '$_base/agreements/$agreementId/activate',
      fallbackError: 'Could not activate that agreement.',
    );
    return PharmacyAgreementMapper.fromJson(response.dataObject);
  }

  @override
  Future<PharmacyAgreement> suspendAgreement(int agreementId) async {
    final response = await api.post(
      '$_base/agreements/$agreementId/suspend',
      fallbackError: 'Could not suspend that agreement.',
    );
    return PharmacyAgreementMapper.fromJson(response.dataObject);
  }

  // ─── Compliance ───────────────────────────────────────────────────────────

  @override
  Future<ComplianceDashboard> getComplianceDashboard() async {
    final response = await api.get(
      '$_base/compliance/dashboard',
      fallbackError: 'Could not load the compliance dashboard.',
    );
    return ComplianceDashboardMapper.fromJson(response.dataObject);
  }

  @override
  Future<PharmacyComplianceStatus> getPharmacyCompliance(
    int pharmacyId,
  ) async {
    final response = await api.get(
      '$_base/compliance/pharmacy/$pharmacyId',
      fallbackError: 'Could not load compliance for that pharmacy.',
    );
    return PharmacyComplianceStatusMapper.fromJson(response.dataObject);
  }

  @override
  Future<List<ComplianceReportRow>> getComplianceReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (endDate.isBefore(startDate)) {
      throw const ValidationFailure(
          'The end date must fall on or after the start date.');
    }

    final response = await api.get(
      '$_base/compliance/report',
      queryParameters: {
        'start_date': _date(startDate),
        'end_date': _date(endDate),
      },
      fallbackError: 'Could not load the compliance report.',
    );
    return response.dataList.map(ComplianceReportRowMapper.fromJson).toList();
  }

  // ─── Claim routing ────────────────────────────────────────────────────────

  @override
  Future<RoutingStatistics> getRoutingStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await api.get(
      '$_base/routing/statistics',
      queryParameters: {
        if (startDate != null) 'start_date': _date(startDate),
        if (endDate != null) 'end_date': _date(endDate),
      },
      fallbackError: 'Could not load routing statistics.',
    );
    return RoutingStatisticsMapper.fromJson(response.dataObject);
  }

  @override
  Future<List<TierRoutingStats>> getRoutingByTier() async {
    final response = await api.get(
      '$_base/routing/by-tier',
      fallbackError: 'Could not load routing by tier.',
    );
    return response.dataList.map(TierRoutingStatsMapper.fromJson).toList();
  }

  @override
  Future<List<CandidatePharmacy>> getCandidatePharmacies({
    double latitude = 0,
    double longitude = 0,
  }) async {
    final response = await api.get(
      '$_base/routing/candidates',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      },
      fallbackError: 'Could not load candidate pharmacies.',
    );
    return response.dataList.map(CandidatePharmacyMapper.fromJson).toList();
  }
}
