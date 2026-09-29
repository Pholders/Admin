import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/pharmacy_group.dart';

/// Maps `pharmacy_groups` rows onto [PharmacyGroup].
extension PharmacyGroupMapper on PharmacyGroup {
  static PharmacyGroup fromJson(Map<String, dynamic> json) {
    return PharmacyGroup(
      id: asInt(json['id']),
      groupName: asString(json['group_name'], fallback: 'Unnamed group'),
      tier: asString(json['tier'], fallback: 'basic'),
      parentCompany: asStringOrNull(json['parent_company']),
      description: asStringOrNull(json['description']),
      totalPharmacies: asInt(json['total_pharmacies']),
      // Only the list/detail/search queries compute this; fall back to the
      // denormalised column so a group created via POST still shows a count.
      pharmacyCount:
          asIntOrNull(json['pharmacy_count']) ?? asInt(json['total_pharmacies']),
      commissionRate: asDoubleOrNull(json['commission_rate']),
      totalClaimsHandled: asInt(json['total_claims_handled']),
      totalRevenue: asDouble(json['total_revenue']),
      isActive: asBool(json['is_active'], fallback: true),
      createdAt: asDate(json['created_at']),
    );
  }
}

/// Maps a `pharmacies` row joined to its `pharmacy_group_members` row.
extension GroupPharmacyMapper on GroupPharmacy {
  static GroupPharmacy fromJson(Map<String, dynamic> json) {
    return GroupPharmacy(
      id: asInt(json['id']),
      pharmacyName:
          asString(json['pharmacy_name'], fallback: 'Unnamed pharmacy'),
      email: asString(json['email']),
      status: asString(json['status'], fallback: 'unknown'),
      firstName: asStringOrNull(json['first_name']),
      lastName: asStringOrNull(json['last_name']),
      phone: asStringOrNull(json['phone']),
      licenseNumber: asStringOrNull(json['license_number']),
      city: asStringOrNull(json['city']),
      province: asStringOrNull(json['province']),
      address: asStringOrNull(json['address']),
      deliveryAvailable: asBool(json['delivery_available']),
      is24Hours: asBool(json['is_24_hours']),
      isPrimary: asBool(json['is_primary']),
      joinedAt: asDate(json['joined_at']),
      createdAt: asDate(json['created_at']),
    );
  }
}

extension PharmacyGroupStatsMapper on PharmacyGroupStats {
  static PharmacyGroupStats fromJson(Map<String, dynamic> json) {
    return PharmacyGroupStats(
      activePharmacies: asInt(json['active_pharmacies']),
      activeAgreements: asInt(json['active_agreements']),
      totalClaims: asInt(json['total_claims']),
      totalRevenue: asDouble(json['total_revenue']),
      commissionRate: asDoubleOrNull(json['commission_rate']),
    );
  }
}

extension PharmacyGroupDetailMapper on PharmacyGroupDetail {
  /// The detail endpoint spreads the group's own columns at the top level and
  /// nests `pharmacies` and `statistics` alongside them.
  static PharmacyGroupDetail fromJson(Map<String, dynamic> json) {
    return PharmacyGroupDetail(
      group: PharmacyGroupMapper.fromJson(json),
      pharmacies: asObjectList(json['pharmacies'])
          .map(GroupPharmacyMapper.fromJson)
          .toList(),
      statistics: PharmacyGroupStatsMapper.fromJson(asObject(json['statistics'])),
    );
  }
}
