import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/features/partnerships/domain/entities/claim_routing.dart';
import 'package:pholders_admin/features/partnerships/domain/entities/compliance.dart';
import 'package:pholders_admin/features/partnerships/domain/entities/partnership_overview.dart';
import 'package:pholders_admin/features/partnerships/domain/entities/pharmacy_group.dart';
import 'package:pholders_admin/features/partnerships/domain/usecases/partnership_usecases.dart';
import 'package:pholders_admin/store.dart';

const _emptyOverview = PartnershipOverview(
  groups: [],
  agreements: [],
  expiringAgreements: [],
  compliance: ComplianceDashboard(
    summary: ComplianceSummary(),
    topPerformers: [],
    lowPerformers: [],
  ),
  routing: RoutingStatistics(),
  routingByTier: [],
);

void main() {
  group('partnershipsReducer — loading', () {
    test('a directory load clears a previous error before retrying', () {
      final nextState = partnershipsReducer(
        const PartnershipsState(directoryError: 'Could not reach the server'),
        const LoadPharmacyDirectoryAction(),
      );

      expect(nextState.isLoadingDirectory, isTrue);
      expect(nextState.directoryError, isNull);
    });

    test('a failed load still marks the directory as having been tried', () {
      final nextState = partnershipsReducer(
        const PartnershipsState(isLoadingDirectory: true),
        const PharmacyDirectoryFailedAction('Session expired'),
      );

      // Without this the screen cannot tell "not asked yet" from "asked and
      // it failed", and would sit on a spinner forever.
      expect(nextState.hasLoadedDirectory, isTrue);
      expect(nextState.isLoadingDirectory, isFalse);
      expect(nextState.directoryError, 'Session expired');
    });

    test('directory and overview loads do not disturb each other', () {
      final withOverview = partnershipsReducer(
        PartnershipsState.initial(),
        const PartnershipOverviewLoadedAction(_emptyOverview),
      );
      final thenLoadingDirectory = partnershipsReducer(
        withOverview,
        const LoadPharmacyDirectoryAction(),
      );

      expect(thenLoadingDirectory.overview, isNotNull);
      expect(thenLoadingDirectory.isLoadingOverview, isFalse);
      expect(thenLoadingDirectory.isLoadingDirectory, isTrue);
    });
  });

  group('partnershipsReducer — mutations', () {
    test('starting a mutation clears the last banner', () {
      final nextState = partnershipsReducer(
        const PartnershipsState(actionError: 'Pharmacy not found'),
        const AssignPharmacyToGroupAction(
          GroupMembershipParams(groupId: 1, pharmacyId: 2),
        ),
      );

      expect(nextState.isMutating, isTrue);
      expect(nextState.actionError, isNull);
      expect(nextState.actionMessage, isNull);
    });

    test('a success reports without leaving the spinner up', () {
      final nextState = partnershipsReducer(
        const PartnershipsState(isMutating: true),
        const PartnershipActionSucceededAction('Agreement activated.'),
      );

      expect(nextState.isMutating, isFalse);
      expect(nextState.actionMessage, 'Agreement activated.');
      expect(nextState.actionError, isNull);
    });

    test('a failure surfaces the API message', () {
      final nextState = partnershipsReducer(
        const PartnershipsState(isMutating: true),
        const PartnershipActionFailedAction('Pharmacy already in group'),
      );

      expect(nextState.isMutating, isFalse);
      expect(nextState.actionError, 'Pharmacy already in group');
    });
  });

  group('partnershipsReducer — session boundaries', () {
    test('signing out drops every loaded record', () {
      const loaded = PartnershipsState(
        directory: PharmacyDirectory(
          groups: [PharmacyGroup(id: 1, groupName: 'Premium', tier: 'premium')],
          entries: [],
        ),
        overview: _emptyOverview,
      );

      final afterLogout = partnershipsReducer(loaded, const LogoutAction());

      // The next admin must not see the previous one's data flash on screen.
      expect(afterLogout.directory.groups, isEmpty);
      expect(afterLogout.overview, isNull);
      expect(afterLogout.hasLoadedDirectory, isFalse);
    });

    test('an expired session clears the slice the same way', () {
      const loaded = PartnershipsState(overview: _emptyOverview);

      final afterExpiry =
          partnershipsReducer(loaded, const SessionExpiredAction());

      expect(afterExpiry.overview, isNull);
    });
  });
}
