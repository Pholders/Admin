import 'package:equatable/equatable.dart';

/// A pharmacy group — the tier a pharmacy belongs to.
///
/// Mirrors the `pharmacy_groups` row returned by
/// `GET /users/partnerships/groups`. `pharmacyCount` is the live
/// `COUNT(DISTINCT member)` the query computes; `totalPharmacies` is the
/// denormalised column, which the backend only refreshes on membership
/// changes — prefer `pharmacyCount` when showing a number.
class PharmacyGroup extends Equatable {
  const PharmacyGroup({
    required this.id,
    required this.groupName,
    required this.tier,
    this.parentCompany,
    this.description,
    this.totalPharmacies = 0,
    this.pharmacyCount = 0,
    this.commissionRate,
    this.totalClaimsHandled = 0,
    this.totalRevenue = 0,
    this.isActive = true,
    this.createdAt,
  });

  final int id;
  final String groupName;

  /// One of `premium`, `standard`, `basic` — enforced by a CHECK constraint.
  final String tier;

  final String? parentCompany;
  final String? description;
  final int totalPharmacies;
  final int pharmacyCount;
  final double? commissionRate;
  final int totalClaimsHandled;
  final double totalRevenue;
  final bool isActive;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        groupName,
        tier,
        parentCompany,
        description,
        totalPharmacies,
        pharmacyCount,
        commissionRate,
        totalClaimsHandled,
        totalRevenue,
        isActive,
        createdAt,
      ];
}

/// A pharmacy as it appears inside a group.
///
/// `GET /users/partnerships/groups/:groupId` selects `p.*` from `pharmacies`
/// joined to the membership row, so this carries the full pharmacy record
/// plus [isPrimary] and [joinedAt] from `pharmacy_group_members`.
class GroupPharmacy extends Equatable {
  const GroupPharmacy({
    required this.id,
    required this.pharmacyName,
    required this.email,
    required this.status,
    this.firstName,
    this.lastName,
    this.phone,
    this.licenseNumber,
    this.city,
    this.province,
    this.address,
    this.deliveryAvailable = false,
    this.is24Hours = false,
    this.isPrimary = false,
    this.joinedAt,
    this.createdAt,
  });

  final int id;
  final String pharmacyName;
  final String email;

  /// `active`, `pending_verification`, `inactive` — the `pharmacies.status`
  /// column. Not a partnership status.
  final String status;

  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? licenseNumber;
  final String? city;
  final String? province;
  final String? address;
  final bool deliveryAvailable;
  final bool is24Hours;
  final bool isPrimary;
  final DateTime? joinedAt;
  final DateTime? createdAt;

  /// The owner/contact name, falling back to the email's local part.
  String get contactName {
    final parts = [firstName, lastName]
        .map((p) => p?.trim() ?? '')
        .where((p) => p.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    return email.split('@').first;
  }

  @override
  List<Object?> get props => [
        id,
        pharmacyName,
        email,
        status,
        firstName,
        lastName,
        phone,
        licenseNumber,
        city,
        province,
        address,
        deliveryAvailable,
        is24Hours,
        isPrimary,
        joinedAt,
        createdAt,
      ];
}

/// Aggregate counters for one group, from the group detail endpoint's
/// `statistics` object.
class PharmacyGroupStats extends Equatable {
  const PharmacyGroupStats({
    this.activePharmacies = 0,
    this.activeAgreements = 0,
    this.totalClaims = 0,
    this.totalRevenue = 0,
    this.commissionRate,
  });

  final int activePharmacies;
  final int activeAgreements;
  final int totalClaims;
  final double totalRevenue;
  final double? commissionRate;

  @override
  List<Object?> get props => [
        activePharmacies,
        activeAgreements,
        totalClaims,
        totalRevenue,
        commissionRate,
      ];
}

/// The full payload of `GET /users/partnerships/groups/:groupId`.
class PharmacyGroupDetail extends Equatable {
  const PharmacyGroupDetail({
    required this.group,
    required this.pharmacies,
    required this.statistics,
  });

  final PharmacyGroup group;
  final List<GroupPharmacy> pharmacies;
  final PharmacyGroupStats statistics;

  @override
  List<Object?> get props => [group, pharmacies, statistics];
}

/// One row of the Pharmacies directory: a pharmacy plus the group it sits in.
///
/// There is no admin endpoint that lists pharmacies on their own, so the
/// directory is assembled from group membership. A pharmacy that belongs to
/// no group cannot appear here — see
/// `PartnershipRepository.getPharmacyDirectory`.
class PharmacyDirectoryEntry extends Equatable {
  const PharmacyDirectoryEntry({
    required this.pharmacy,
    required this.groupId,
    required this.groupName,
    required this.tier,
  });

  final GroupPharmacy pharmacy;
  final int groupId;
  final String groupName;
  final String tier;

  int get id => pharmacy.id;

  @override
  List<Object?> get props => [pharmacy, groupId, groupName, tier];
}

/// What the Pharmacies screen loads in one pass.
///
/// [groups] is every group, including ones with no members yet — building
/// the directory already fetches them, so carrying them here spares the
/// screen a second round of requests when it needs somewhere to move a
/// pharmacy to.
class PharmacyDirectory extends Equatable {
  const PharmacyDirectory({required this.groups, required this.entries});

  const PharmacyDirectory.empty()
      : groups = const [],
        entries = const [];

  final List<PharmacyGroup> groups;
  final List<PharmacyDirectoryEntry> entries;

  @override
  List<Object?> get props => [groups, entries];
}
