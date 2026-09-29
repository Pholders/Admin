import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/features/partnerships/data/models/claim_routing_model.dart';
import 'package:pholders_admin/features/partnerships/data/models/compliance_model.dart';
import 'package:pholders_admin/features/partnerships/data/models/pharmacy_agreement_model.dart';
import 'package:pholders_admin/features/partnerships/data/models/pharmacy_group_model.dart';
import 'package:pholders_admin/features/partnerships/domain/entities/pharmacy_agreement.dart';

void main() {
  group('partnership mappers — Postgres string numerics', () {
    // node-postgres serialises DECIMAL, BIGINT and every COUNT/AVG aggregate
    // as a string to avoid precision loss. These payloads are shaped exactly
    // as the API returns them, quotes included.
    test('a group parses counts and rates that arrive as strings', () {
      final group = PharmacyGroupMapper.fromJson({
        'id': 3,
        'group_name': 'Clicks Group',
        'parent_company': 'Clicks Retailers',
        'tier': 'premium',
        'total_pharmacies': 4,
        'pharmacy_count': '7',
        'commission_rate': '12.50',
        'total_claims_handled': '108',
        'total_revenue': '48250.75',
        'is_active': true,
        'created_at': '2026-03-12T08:14:22.104Z',
      });

      expect(group.pharmacyCount, 7);
      expect(group.commissionRate, 12.5);
      expect(group.totalClaimsHandled, 108);
      expect(group.totalRevenue, 48250.75);
      expect(group.createdAt, isNotNull);
    });

    test('a group falls back to the denormalised count', () {
      // A freshly created group comes back from POST without the computed
      // pharmacy_count the list query adds.
      final group = PharmacyGroupMapper.fromJson({
        'id': 9,
        'group_name': 'Basic',
        'tier': 'basic',
        'total_pharmacies': 2,
      });

      expect(group.pharmacyCount, 2);
    });

    test('an agreement parses its decimal terms', () {
      final agreement = PharmacyAgreementMapper.fromJson({
        'id': 11,
        'pharmacy_or_group_id': 3,
        'entity_type': 'group',
        'status': 'active',
        'commission_rate': '8.00',
        'service_fee': '150.00',
        'claim_response_time_hours': 24,
        'dispensing_time_hours': 48,
        'start_date': '2026-01-01T00:00:00.000Z',
        'end_date': '2026-12-31T00:00:00.000Z',
        'auto_renew': false,
      });

      expect(agreement.commissionRate, 8.0);
      expect(agreement.serviceFee, 150.0);
      expect(agreement.isGroupAgreement, isTrue);
      expect(agreement.endDate, isNotNull);
    });

    test('routing statistics parse aggregate strings', () {
      final stats = RoutingStatisticsMapper.fromJson({
        'total_routes': '40',
        'accepted_count': '30',
        'rejected_count': '6',
        'pending_count': '4',
        'avg_response_time': '1820.5',
        'min_response_time': '45',
        'max_response_time': '7200',
      });

      expect(stats.totalRoutes, 40);
      expect(stats.acceptanceRate, 75);
      expect(stats.averageResponseSeconds, 1820.5);
    });
  });

  group('partnership mappers — empty and partial payloads', () {
    test('an unscored compliance dashboard reads as zeros, not a crash', () {
      // With no rows in agreement_compliance every aggregate comes back null,
      // and getTopPerformers currently fails server-side and returns [].
      final dashboard = ComplianceDashboardMapper.fromJson({
        'summary': {
          'total_agreements': null,
          'active_agreements': null,
          'avg_compliance_score': null,
        },
        'topPerformers': <dynamic>[],
        'lowPerformers': <dynamic>[],
      });

      expect(dashboard.summary.totalAgreements, 0);
      expect(dashboard.summary.averageComplianceScore, isNull);
      expect(dashboard.topPerformers, isEmpty);
    });

    test('a performer row is read from either list shape', () {
      // Low performers select ppm.pharmacy_id; top performers select p.id.
      final low = PharmacyPerformanceMapper.fromJson({
        'pharmacy_id': 5,
        'pharmacy_name': 'Corner Pharmacy',
        'overall_score': '62.40',
      });
      final top = PharmacyPerformanceMapper.fromJson({
        'id': 6,
        'pharmacy_name': 'Main Street Pharmacy',
      });

      expect(low!.pharmacyId, 5);
      expect(low.overallScore, 62.4);
      expect(top!.pharmacyId, 6);
      expect(top.overallScore, isNull);
    });

    test('a group detail with no members still parses', () {
      final detail = PharmacyGroupDetailMapper.fromJson({
        'id': 2,
        'group_name': 'Standard',
        'tier': 'standard',
        'pharmacies': <dynamic>[],
        'statistics': {'active_pharmacies': '0'},
      });

      expect(detail.pharmacies, isEmpty);
      expect(detail.statistics.activePharmacies, 0);
    });

    test('a trend point without a month is dropped', () {
      expect(ComplianceTrendPointMapper.fromJson({'total_claims': 3}), isNull);
    });
  });

  group('PharmacyAgreement.daysUntilExpiry', () {
    test('is null for an open-ended agreement', () {
      const agreement = PharmacyAgreement(
        id: 1,
        pharmacyOrGroupId: 1,
        entityType: 'pharmacy',
        status: 'active',
        commissionRate: 10,
      );

      expect(agreement.daysUntilExpiry, isNull);
    });

    test('counts whole days and ignores the time of day', () {
      final agreement = PharmacyAgreement(
        id: 1,
        pharmacyOrGroupId: 1,
        entityType: 'pharmacy',
        status: 'active',
        commissionRate: 10,
        // A DATE column parses to midnight; the comparison must not report
        // 6 days just because "now" is late in the afternoon.
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(agreement.daysUntilExpiry, 7);
    });

    test('is negative once the end date has passed', () {
      final agreement = PharmacyAgreement(
        id: 1,
        pharmacyOrGroupId: 1,
        entityType: 'pharmacy',
        status: 'active',
        commissionRate: 10,
        endDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(agreement.daysUntilExpiry, -3);
    });
  });
}
