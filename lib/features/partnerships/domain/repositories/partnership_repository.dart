import '../entities/claim_routing.dart';
import '../entities/compliance.dart';
import '../entities/pharmacy_agreement.dart';
import '../entities/pharmacy_group.dart';

/// Every admin-role pharmacy endpoint the backend exposes.
///
/// All of them live under `/users/partnerships/...` and are guarded by
/// `requireRole('admin')`. Implementations throw a `Failure` — never a
/// `DioException` — so callers only ever handle one error type.
abstract class PartnershipRepository {
  // ─── Groups ───────────────────────────────────────────────────────────────

  /// `GET /users/partnerships/groups`
  ///
  /// [isActive] null means "every group", which costs two requests: the
  /// backend coerces the filter with `is_active: req.query.is_active ===
  /// 'true'`, producing a boolean on every call, and the model then applies
  /// it unconditionally. So omitting the parameter does not disable the
  /// filter — it silently asks for *inactive* groups. Active and inactive
  /// are fetched separately and merged.
  Future<List<PharmacyGroup>> getGroups({
    String? tier,
    bool? isActive = true,
    int limit = 50,
    int offset = 0,
  });

  /// `GET /users/partnerships/groups/:groupId` — group, members and stats.
  Future<PharmacyGroupDetail> getGroupDetail(int groupId);

  /// Groups whose name or parent company contains [term], case-insensitively.
  ///
  /// Matched client-side rather than through
  /// `GET /users/partnerships/groups/search`: that route is registered *after*
  /// `/partnerships/groups/:groupId`, and Express matches in declaration
  /// order, so the request is handled by `getGroupById` with
  /// `groupId = 'search'` and dies casting it to an integer. Once the route
  /// order is fixed on the server this can call the endpoint instead.
  Future<List<PharmacyGroup>> searchGroups(String term);

  /// `POST /users/partnerships/groups`. [tier] must be premium/standard/basic.
  Future<PharmacyGroup> createGroup({
    required String groupName,
    required String tier,
    String? parentCompany,
    String? description,
    double? commissionRate,
  });

  /// `PUT /users/partnerships/groups/:groupId` — only non-null fields change.
  Future<PharmacyGroup> updateGroup(
    int groupId, {
    String? groupName,
    String? parentCompany,
    String? tier,
    String? description,
    double? commissionRate,
    bool? isActive,
  });

  /// `POST /users/partnerships/groups/:groupId/pharmacies`
  Future<void> addPharmacyToGroup({
    required int groupId,
    required int pharmacyId,
    bool isPrimary = true,
  });

  /// `DELETE /users/partnerships/groups/:groupId/pharmacies/:pharmacyId`
  Future<void> removePharmacyFromGroup({
    required int groupId,
    required int pharmacyId,
  });

  /// Every pharmacy the admin can see, with its group and tier, plus the
  /// full group list.
  ///
  /// Assembled client-side by walking each group's membership: the API has no
  /// endpoint that lists pharmacies directly. A pharmacy belonging to no
  /// group is therefore invisible here.
  Future<PharmacyDirectory> getPharmacyDirectory();

  // ─── Agreements ───────────────────────────────────────────────────────────

  /// `GET /users/partnerships/agreements`
  Future<List<PharmacyAgreement>> getAgreements({
    String? entityType,
    String? status,
    int? pharmacyOrGroupId,
    int limit = 50,
    int offset = 0,
  });

  /// `GET /users/partnerships/agreements/:agreementId` — with compliance.
  Future<PharmacyAgreementDetail> getAgreementDetail(int agreementId);

  /// Active agreements whose `end_date` falls within the next [days].
  ///
  /// Derived from [getAgreements] for the same reason [searchGroups] is
  /// derived: `/partnerships/agreements/expiring` is registered after
  /// `/partnerships/agreements/:agreementId` and is therefore unreachable.
  Future<List<PharmacyAgreement>> getExpiringAgreements({int days = 30});

  /// `POST /users/partnerships/agreements`
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
  });

  /// `PUT /users/partnerships/agreements/:agreementId`
  Future<PharmacyAgreement> updateAgreement(
    int agreementId, {
    double? commissionRate,
    double? serviceFee,
    int? claimResponseTimeHours,
    int? dispensingTimeHours,
    String? paymentTerms,
    String? status,
    DateTime? endDate,
  });

  /// `POST /users/partnerships/agreements/:agreementId/activate`
  Future<PharmacyAgreement> activateAgreement(int agreementId);

  /// `POST /users/partnerships/agreements/:agreementId/suspend`
  Future<PharmacyAgreement> suspendAgreement(int agreementId);

  // ─── Compliance ───────────────────────────────────────────────────────────

  /// `GET /users/partnerships/compliance/dashboard`
  Future<ComplianceDashboard> getComplianceDashboard();

  /// `GET /users/partnerships/compliance/pharmacy/:pharmacyId`
  Future<PharmacyComplianceStatus> getPharmacyCompliance(int pharmacyId);

  /// `GET /users/partnerships/compliance/report` — both dates are required
  /// by the backend, which answers 400 if either is missing.
  Future<List<ComplianceReportRow>> getComplianceReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  // ─── Claim routing ────────────────────────────────────────────────────────

  /// `GET /users/partnerships/routing/statistics`
  Future<RoutingStatistics> getRoutingStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// `GET /users/partnerships/routing/by-tier`
  Future<List<TierRoutingStats>> getRoutingByTier();

  /// `GET /users/partnerships/routing/candidates`
  Future<List<CandidatePharmacy>> getCandidatePharmacies({
    double latitude = 0,
    double longitude = 0,
  });
}
