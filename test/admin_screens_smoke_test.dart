import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/core/network/admin_api.dart';
import 'package:pholders_admin/core/network/api_client.dart';
import 'package:pholders_admin/screens/account_screen.dart';
import 'package:pholders_admin/screens/admin_tools_screen.dart';
import 'package:pholders_admin/screens/agreements_screen.dart';
import 'package:pholders_admin/screens/claim_routing_screen.dart';
import 'package:pholders_admin/screens/compliance_screen.dart';
import 'package:pholders_admin/screens/dashboard_screen.dart';
import 'package:pholders_admin/screens/doctors_screen.dart';
import 'package:pholders_admin/screens/patients_screen.dart';
import 'package:pholders_admin/screens/pharmacies_screen.dart';
import 'package:pholders_admin/screens/partner_groups_screen.dart';
import 'package:pholders_admin/screens/help_center_screen.dart';
import 'package:pholders_admin/screens/returns_screen.dart';
import 'package:pholders_admin/screens/security_screens.dart';
import 'package:pholders_admin/screens/tracking_screen.dart';
import 'package:pholders_admin/store.dart';
import 'package:pholders_admin/widgets/dashboard/stat_card.dart';
import 'package:redux/redux.dart';

/// Serves response bodies shaped like the backend's, keyed by path.
class _CannedApi extends AdminApi {
  _CannedApi()
      : super(apiClient: ApiClient(), secureStorage: const FlutterSecureStorage());

  static const _pharmacy = {
    'id': 7,
    'pharmacy_name': 'HealthPlus Pharmacy',
    'email': 'ops@healthplus.test',
    'city': 'Johannesburg',
    'province': 'Gauteng',
    'status': 'active',
    'password_hash': 'MUST-NOT-RENDER',
    'created_at': '2026-03-12T08:30:00.000Z',
  };
  static const _group = {
    'id': 3,
    'group_name': 'Gauteng Network',
    'parent_company': 'HealthPlus Holdings',
    'tier': 'premium',
    'commission_rate': '12.50',
    'total_claims_handled': 40,
    'total_revenue': '18200.00',
    'is_active': true,
    'pharmacy_count': '1',
    'created_at': '2026-01-02T10:00:00.000Z',
  };
  static const _agreement = {
    'id': 11,
    'pharmacy_or_group_id': 3,
    'entity_type': 'group',
    'agreement_type': 'dispensing',
    'start_date': '2026-01-01',
    'end_date': '2026-12-31',
    'auto_renew': false,
    'commission_rate': '10.00',
    'service_fee': '25.00',
    'status': 'active',
  };

  final posted = <String>[];
  final patched = <String>[];
  final queries = <String, Map<String, dynamic>?>{};

  static final _patients = [
    {'id': 21, 'first_name': 'Thandi', 'last_name': 'Nkosi', 'email': 'thandi@example.test', 'phone': '+27 82 000 0001', 'city': 'Durban', 'suburb': 'Umhlanga', 'status': 'active', 'email_verified': true, 'account_frozen': false, 'avatar_url': null, 'created_at': DateTime.now().toUtc().toIso8601String()},
    {'id': 22, 'first_name': 'Pieter', 'last_name': 'van Wyk', 'email': 'pieter@example.test', 'phone': null, 'city': 'Pretoria', 'suburb': null, 'status': 'suspended', 'email_verified': false, 'account_frozen': false, 'avatar_url': null, 'created_at': '2026-01-10T08:00:00Z'},
  ];
  static const _doctors = [
    {'id': 31, 'first_name': 'Naledi', 'last_name': 'Mokoena', 'email': 'naledi@clinic.test', 'hpcsa_number': 'MP0123456', 'specialization': 'Paediatrics', 'clinic_name': 'Sandton Kids Clinic', 'city': 'Johannesburg', 'suburb': 'Sandton', 'rating': 4.6, 'review_count': 12, 'profile_image': null, 'status': 'pending', 'email_verified': true, 'created_at': '2026-11-04T09:05:00Z'},
  ];

  @override
  Future<dynamic> patch(String path, {Object? body}) async {
    patched.add('$path ${(body as Map)['status']}');
    return {'ok': true};
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    queries[path] = query;
    if (path.endsWith('/admin/patients')) return {'total': 2, 'limit': 200, 'offset': 0, 'patients': _patients};
    if (path.endsWith('/admin/patients/22')) return {..._patients[1], 'gender': 'male', 'nationality': 'South African'};
    if (path.endsWith('/admin/doctors')) return {'total': 1, 'limit': 200, 'offset': 0, 'doctors': _doctors};
    if (path.endsWith('/admin/doctors/31')) return {..._doctors[0], 'bio': 'Paediatrician', 'consultation_fee': '650.00'};
    if (path.endsWith('/admin/dashboard/summary')) {
      return {
        'counts': {'patients': 2, 'doctors': 1, 'pharmacies': 1, 'total_users': 4, 'active_prescriptions': 7, 'orders_today': 3},
        'revenue': {'amount': 20450.5, 'currency': 'ZAR', 'period': 'month', 'by_method': {'stripe': 20450.5}},
        'alerts': {
          'pending_verifications': {'count': 1, 'pharmacies': 0, 'doctors': 1, 'latest_at': '2026-11-04T09:05:00Z'},
          'failed_payments': {'count': 0, 'window_days': 7, 'latest_at': null},
          'flagged_prescriptions': null,
        },
      };
    }
    if (path.endsWith('/admin/dashboard/activity')) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final daily = query?['range'] == 'daily';
      return {
        'range': query?['range'],
        'buckets': [
          for (var i = 0; i < (daily ? 30 : 12); i++)
            {'label': daily ? '${i + 1} Oct' : months[i], 'start': '2026-01-01', 'prescriptions': i * 3, 'orders': i},
        ],
      };
    }
    if (path.endsWith('/admin/users/recent')) {
      final role = query?['role'];
      final users = [
        {'id': 31, 'role': 'doctor', 'name': 'Naledi Mokoena', 'email': 'naledi@clinic.test', 'status': 'pending', 'profile_image': null, 'created_at': '2026-11-04T09:05:00Z'},
        {'id': 21, 'role': 'patient', 'name': 'Thandi Nkosi', 'email': 'thandi@example.test', 'status': 'active', 'profile_image': null, 'created_at': '2026-11-03T09:05:00Z'},
      ];
      return {'role': role, 'users': [for (final u in users) if (role == 'all' || u['role'] == role) u]};
    }
    if (path.endsWith('/admin/profile')) {
      return {'id': 1, 'first_name': 'Ada', 'last_name': 'Admin', 'email': 'ada@pholders.test', 'status': 'active', 'created_at': '2025-06-01T00:00:00Z'};
    }
    if (path.endsWith('/admin/sessions')) {
      return {'count': 1, 'sessions': [{'id': 9, 'ip_address': '10.0.0.1', 'device_info': 'Edge on Windows', 'created_at': '2026-11-05T08:00:00Z', 'last_activity_at': '2026-11-05T09:00:00Z', 'expires_at': '2026-11-12T08:00:00Z'}]};
    }
    if (path.endsWith('/admin/activity-log')) {
      return [{'id': 1, 'event_type': 'pharmacy_status_changed', 'status': 'success', 'ip_address': '10.0.0.1', 'created_at': '2026-11-05T08:00:00Z'}];
    }
    // Shapes from the backend team's captured responses: decimals as strings.
    if (path.endsWith('/admin/pharmacies')) {
      return {
        'total': 1,
        'limit': 200,
        'offset': 0,
        'pharmacies': [
          {
            ..._pharmacy,
            'first_name': 'Alice',
            'last_name': 'Johnson',
            'phone': '+27110001001',
            'license_number': 'SEED-PHARM-0001',
            'is_24_hours': true,
            'delivery_available': true,
            'delivery_radius': '5.00',
            'email_verified': false,
          }..remove('password_hash'),
        ],
      };
    }
    if (path.endsWith('/admin/pharmacies/7')) {
      return {
        ...(Map<String, dynamic>.from(_pharmacy)..remove('password_hash')),
        'latitude': '-26.05650000',
        'longitude': '28.02270000',
        'services': ['prescription_filling', 'home_delivery'],
        'delivery_radius': '5.00',
      };
    }
    if (path.endsWith('/security/dashboard')) {
      return {
        'summary': {'total_logins': 120, 'failed_attempts': 9, 'impossible_travels': 1, 'unique_locations': 3, 'unique_ips': 40},
        'alerts': {'impossible_travels': 1, 'suspicious_locations': 1},
        'impossible_travels': [{'email': 'x@y.test', 'country': 'ZA', 'city': 'Durban'}],
        'suspicious_locations': [{'country': 'ZA', 'city': 'Durban', 'isp': 'ISP', 'attempt_count': '5', 'failed_attempts': '4', 'emails': ['x@y.test'], 'last_attempt': '2026-11-05T07:00:00Z'}],
      };
    }
    if (path.endsWith('/security/user-locations')) {
      return {'user_id': '1', 'days': 30, 'locations': [{'country': 'ZA', 'city': 'Cape Town', 'timezone': 'Africa/Johannesburg', 'login_count': '4', 'first_login': '2026-10-01T00:00:00Z', 'last_login': '2026-11-01T00:00:00Z'}]};
    }
    if (path.contains('/partnerships/groups/3')) {
      return {..._group, 'pharmacies': [{..._pharmacy, 'is_primary': true, 'joined_at': '2026-02-01T00:00:00Z'}], 'statistics': {'active_pharmacies': '1', 'active_agreements': '1'}};
    }
    if (path.contains('/partnerships/groups')) return [_group];
    if (path.contains('/agreements/11')) {
      return {..._agreement, 'entity_name': 'Gauteng Network', 'compliance': {'avg_compliance': '91.5'}, 'trends': [{'month_date': '2026-10-01', 'compliance_score': '92'}]};
    }
    if (path.contains('/agreements')) return [_agreement];
    if (path.endsWith('/compliance/dashboard')) {
      return {
        'summary': {'total_agreements': '4', 'active_agreements': '3', 'avg_compliance_score': '88.4', 'excellent_count': '1'},
        'topPerformers': [{'id': 7, 'pharmacy_name': 'HealthPlus Pharmacy', 'group_name': 'Gauteng Network'}],
        'lowPerformers': <dynamic>[],
      };
    }
    if (path.contains('/compliance/pharmacy/')) {
      return {'pharmacyId': '7', 'overallCompliance': 91, 'agreementCount': 1, 'agreements': [{'agreementId': 11, 'avg_compliance': 91}], 'status': 'excellent'};
    }
    if (path.endsWith('/compliance/report')) return [{'agreement_id': 11, 'entity_type': 'group', 'entity_name': 'Gauteng Network'}];
    if (path.endsWith('/routing/statistics')) {
      return {'total_routes': '20', 'accepted_count': '15', 'pending_count': '2', 'rejected_count': '3', 'avg_response_time': '540.5', 'min_response_time': '30', 'max_response_time': '7200'};
    }
    if (path.endsWith('/routing/by-tier')) return [{'tier': 'premium', 'total_routes': '12', 'accepted': '10', 'rejected': '2', 'acceptance_rate': 83}];
    if (path.endsWith('/routing/candidates')) return [{'id': 7, 'pharmacy_name': 'HealthPlus Pharmacy', 'distance': 0.02}];
    if (path.endsWith('/system/logs')) {
      return [{'timestamp': '2026-11-05T08:00:00Z', 'level': 'info', 'message': 'Server started', 'port': 5000}, {'raw': 'plain line'}];
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    posted.add(path);
    if (path.contains('auto-cancel')) return {'cancelledCount': 2, 'timeoutMinutes': 30};
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> getRaw(String path, {Map<String, dynamic>? query}) async =>
      {'success': false, 'message': 'Stripe API connection failed', 'error': 'Invalid API key'};
}

Future<(Store<AppState>, _CannedApi)> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(1920, 1080),
  _CannedApi? withApi,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = withApi ?? _CannedApi();
  final store = Store<AppState>(
    appReducer,
    initialState: const AppState(
      authState: AuthState(token: 't', role: 'admin', userName: 'Ada'),
      navigationState: NavigationState(),
    ),
    middleware: AdminMiddleware(api: api).middleware,
  );
  await tester.pumpWidget(StoreProvider<AppState>(
    store: store,
    // The test font draws every glyph as a full em square, roughly 1.8× the
    // width of the app's Inter. At 0.7 it is still wider than Inter, so a
    // layout that fits here fits in the app, without the shared TopBar's
    // search field overflowing on every screen.
    child: MaterialApp(
      // Lay out as the app does in a desktop browser on Windows. Tests
      // otherwise assume a phone: roomier density and 48px touch targets on
      // every icon button, which makes rows wider than they really are.
      theme: ThemeData(platform: TargetPlatform.windows),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.7)),
        child: child!,
      ),
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
  return (store, api);
}

/// Scrolls [finder] into view, taps it, and waits for the result.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Partner Groups lists groups and opens the detail', (tester) async {
    await _pump(tester, const PartnerGroupsScreen());
    expect(find.text('Gauteng Network'), findsOneWidget);
    expect(find.text('12.5%'), findsWidgets);

    await _tap(tester, find.text('Gauteng Network'));
    expect(find.text('Member Pharmacies (1)'), findsOneWidget);
    expect(find.text('HealthPlus Pharmacy'), findsOneWidget);
    expect(find.textContaining('MUST-NOT-RENDER'), findsNothing);

    await _tap(tester, find.text('Edit Group'));
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('New Group dialog validates before sending', (tester) async {
    await _pump(tester, const PartnerGroupsScreen());
    await _tap(tester, find.text('New Group'));
    await _tap(tester, find.text('Create Group'));
    expect(find.text('Group name is required.'), findsOneWidget);
  });

  testWidgets('Agreements shows party names, detail, and the create form', (tester) async {
    final (_, api) = await _pump(tester, const AgreementsScreen());
    expect(find.text('#11'), findsOneWidget);
    expect(find.text('Gauteng Network'), findsOneWidget, reason: 'name resolved from the group list');

    await _tap(tester, find.byTooltip('Suspend'));
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Suspend'));
    expect(api.posted, ['/users/partnerships/agreements/11/suspend']);

    await _tap(tester, find.text('#11'));
    expect(find.text('Monthly Trend'), findsOneWidget);
    await _tap(tester, find.text('Done'));

    await _tap(tester, find.text('New Agreement'));
    await _tap(tester, find.text('Create Agreement'));
    expect(find.text('Choose the pharmacy.'), findsOneWidget);
  });

  testWidgets('Compliance renders the dashboard and a pharmacy lookup', (tester) async {
    await _pump(tester, const ComplianceScreen());
    expect(find.text('88.4%'), findsOneWidget);
    expect(find.text('Top Performers'), findsOneWidget);

    await _tap(tester, find.byType(DropdownButton<String>));
    await _tap(tester, find.text('HealthPlus Pharmacy').last);
    expect(find.text('Excellent'), findsOneWidget);

    await _tap(tester, find.text('Run Report'));
    // Once in Top Performers, once in the report.
    expect(find.text('Gauteng Network'), findsNWidgets(2));
  });

  testWidgets('Claim Routing renders statistics, tiers and candidates', (tester) async {
    await _pump(tester, const ClaimRoutingScreen());
    expect(find.text('15 (75%)'), findsOneWidget);
    expect(find.text('9 min'), findsOneWidget);
    expect(find.text('83%'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '-26.2');
    await tester.enterText(find.byType(TextField).at(1), '28.04');
    await _tap(tester, find.text('Find Candidates'));
    expect(find.text('HealthPlus Pharmacy'), findsOneWidget);
  });

  testWidgets('Security screens render alerts and a user lookup', (tester) async {
    await _pump(tester, const SecurityOverviewScreen());
    expect(find.textContaining('impossible-travel'), findsOneWidget);
    expect(find.text('Durban, ZA'), findsOneWidget);

    await _pump(tester, const LoginLocationsScreen());
    await tester.enterText(find.byType(TextField), '1');
    await _tap(tester, find.text('Look Up'));
    expect(find.text('Cape Town, ZA'), findsOneWidget);
  });

  testWidgets('My Account renders profile, sessions and activity', (tester) async {
    await _pump(tester, const AccountScreen());
    expect(find.text('Ada Admin'), findsOneWidget);
    expect(find.text('Edge on Windows'), findsOneWidget);
    expect(find.text('Pharmacy Status Changed'), findsOneWidget);
  });

  testWidgets('Admin Tools runs actions and shows logs', (tester) async {
    final (_, api) = await _pump(tester, const AdminToolsScreen());

    await _tap(tester, find.text('Run Now'));
    await _tap(tester, find.text('Cancel Appointments'));
    expect(api.posted, ['/appointments/auto-cancel-expired']);
    expect(find.textContaining('Cancelled 2 appointment'), findsOneWidget);

    await _tap(tester, find.text('Test Connection'));
    expect(find.text('Stripe API connection failed — Invalid API key'), findsOneWidget);

    await _tap(tester, find.text('Load Logs'));
    expect(find.textContaining('Server started', findRichText: true), findsOneWidget);
  });

  testWidgets('Dashboard shows live figures, chart ranges, recent users and alerts', (tester) async {
    final (_, api) = await _pump(tester, const DashboardScreen());
    expect(find.text('7'), findsWidgets, reason: 'active prescriptions');
    expect(find.textContaining('R20'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('Doctors 1'), findsOneWidget);
    expect(find.text('Naledi Mokoena'), findsOneWidget);
    expect(find.text('1 waiting · 1 doctor'), findsOneWidget);
    expect(find.text('Flagged prescriptions'), findsNothing, reason: 'backend sends null');

    await _tap(tester, find.text('Daily'));
    expect(api.queries['/users/admin/dashboard/activity'], {'range': 'daily'});

    await _tap(tester, find.text('Patients').last);
    expect(find.text('Naledi Mokoena'), findsNothing);
    expect(find.text('Thandi Nkosi'), findsOneWidget);
  });

  testWidgets('Dashboard: clicking the Doctors card opens Doctors', (tester) async {
    final (store, _) = await _pump(tester, const DashboardScreen());
    expect(find.text('View all'), findsNothing);
    await _tap(tester, find.text('Doctors').first);
    expect(store.state.navigationState.currentRoute, 'doctors');
  });

  testWidgets('Recent users: approving a pending doctor calls the status endpoint', (tester) async {
    final (_, api) = await _pump(tester, const DashboardScreen());
    await _tap(tester, find.byTooltip('Actions').first);
    await _tap(tester, find.text('Verify (Approve)'));
    expect(api.patched, ['/users/admin/doctors/31/status active']);
  });

  testWidgets('Patients lists real accounts, filters, and opens the record', (tester) async {
    final (_, api) = await _pump(tester, const PatientsScreen());
    expect(api.queries['/users/admin/patients'], containsPair('limit', 200));
    expect(api.queries['/users/admin/patients']?['status'], isNull, reason: 'status filters client-side');
    expect(find.text('Thandi Nkosi'), findsOneWidget);
    expect(find.text('Umhlanga, Durban'), findsOneWidget);
    expect(find.text('Maria Wilson'), findsNothing, reason: 'sample rows are gone');

    // The cards are the controls now; no link text under the numbers.
    expect(find.textContaining('View '), findsNothing);
    StatCardData card(String label) =>
        tester.widget<StatCard>(find.ancestor(of: find.text(label), matching: find.byType(StatCard))).data;
    expect(card('Total Patients').selected, isTrue, reason: 'nothing filtered yet');

    await _tap(tester, find.text('Suspended/Blocked'));
    expect(card('Suspended/Blocked').selected, isTrue);
    expect(card('Total Patients').selected, isFalse);
    expect(find.text('Thandi Nkosi'), findsNothing);
    expect(find.text('Pieter van Wyk'), findsOneWidget);

    await _tap(tester, find.text('Suspended/Blocked'));
    expect(find.text('Thandi Nkosi'), findsOneWidget, reason: 'a second click clears the filter');

    await _tap(tester, find.text('Active Patients'));
    expect(find.text('Pieter van Wyk'), findsNothing);
    await _tap(tester, find.text('Total Patients'));
    expect(find.text('Pieter van Wyk'), findsOneWidget, reason: 'Total shows everyone');

    await _tap(tester, find.text('Pieter van Wyk'));
    expect(find.textContaining('audit trail'), findsOneWidget);
    expect(find.text('South African'), findsOneWidget, reason: 'full record loaded');
    await _tap(tester, find.text('Reactivate').last);
    expect(api.patched, ['/users/admin/patients/22/status active']);
  });

  testWidgets('Doctors: rejecting a pending doctor asks first, then blocks', (tester) async {
    final (_, api) = await _pump(tester, const DoctorsScreen());
    expect(find.text('Naledi Mokoena'), findsOneWidget);
    expect(find.text('4.6 ★ (12)'), findsOneWidget);

    await _tap(tester, find.byTooltip('Actions'));
    await _tap(tester, find.text('Reject'));
    expect(find.textContaining('signed out on every device'), findsOneWidget);
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Reject'));
    expect(api.patched, ['/users/admin/doctors/31/status blocked']);
  });

  testWidgets('Patients: header, stats and column headings stay put while rows scroll', (tester) async {
    await _pump(tester, const PatientsScreen(), withApi: _ManyPatientsApi());
    await _expectPinnedWhileRowsScroll(
      tester,
      pinned: [
        find.text('Manage patient accounts and permissions'),
        find.text('Total Patients'),
        find.text('Date Joined'),
      ],
      dragFrom: find.text('Patient 3'),
    );
  });

  testWidgets('Pharmacies: header, stats and column headings stay put while rows scroll', (tester) async {
    await _pump(tester, const PharmaciesScreen(), size: const Size(1920, 800), withApi: _ManyPharmaciesApi());
    await _expectPinnedWhileRowsScroll(
      tester,
      pinned: [
        find.text('Manage pharmacy accounts and permissions'),
        find.text('Total Pharmacies'),
        find.text('Joined On'),
      ],
      dragFrom: find.text('Pharmacy 3'),
    );
  });

  testWidgets('Pharmacies lists real accounts, opens the record, and suspends', (tester) async {
    final (_, api) = await _pump(tester, const PharmaciesScreen());
    expect(api.queries['/users/admin/pharmacies'], containsPair('limit', 200));
    expect(find.text('HealthPlus Pharmacy'), findsOneWidget);
    expect(find.text('SEED-PHARM-0001'), findsOneWidget);
    expect(find.text('Delivers within 5 km'), findsOneWidget, reason: '"5.00" read as a number');

    await _tap(tester, find.text('HealthPlus Pharmacy'));
    expect(find.text('Prescription Filling'), findsOneWidget, reason: 'services from the View endpoint');
    expect(find.text('-26.05650'), findsOneWidget);
    expect(find.textContaining('MUST-NOT-RENDER'), findsNothing);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Suspend'));
    expect(find.textContaining('signed out'), findsNothing,
        reason: "the pharmacy status endpoint doesn't revoke sessions");
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Suspend'));
    expect(api.patched, ['/users/admin/pharmacies/7/status suspended']);
  });

  testWidgets('Partner Groups: header, filters and column headings stay put while rows scroll', (tester) async {
    await _pump(tester, const PartnerGroupsScreen(), withApi: _ManyRowsApi());
    await _expectPinnedWhileRowsScroll(
      tester,
      pinned: [find.text('Pharmacy groups, their tiers and members'), find.text('All tiers'), find.text('Commission')],
      dragFrom: find.text('Group 3'),
    );
  });

  testWidgets('Agreements: header, filters and column headings stay put while rows scroll', (tester) async {
    await _pump(tester, const AgreementsScreen(), withApi: _ManyRowsApi());
    await _expectPinnedWhileRowsScroll(
      tester,
      pinned: [find.text('Partnership agreements with pharmacies and groups'), find.text('Expiring soon'), find.text('Agreement')],
      dragFrom: find.text('#1003'),
    );
  });

  testWidgets('Login Locations: the lookup form and headings stay put while rows scroll', (tester) async {
    await _pump(tester, const LoginLocationsScreen(), withApi: _ManyRowsApi());
    await tester.enterText(find.byType(TextField).last, '1');
    await _tap(tester, find.text('Look Up'));
    await _expectPinnedWhileRowsScroll(
      tester,
      pinned: [find.text('Look Up'), find.text('Time Zone')],
      dragFrom: find.text('City 3, ZA'),
    );
  });

  testWidgets('Security Overview: the title stays put while its sections scroll', (tester) async {
    await _pump(tester, const SecurityOverviewScreen(), withApi: _ManyRowsApi());
    await _expectPinnedWhileRowsScroll(
      tester,
      pinned: [find.text('Sign-in activity and location alerts from the audit log'), find.text('Last 24 hours')],
      dragFrom: find.text('user3@y.test'),
    );
  });

  testWidgets('Returns, Tracking and Help Center lay out with their headers pinned', (tester) async {
    for (final (screen, title, row) in const [
      (ReturnsScreen(), 'Manage returned prescription orders', 'Return ID'),
      (TrackingScreen(), 'Track delivery status of prescription orders', null),
      (HelpCenterScreen(), 'Manage frequently asked questions', null),
    ]) {
      await _pump(tester, screen, size: const Size(1920, 760));
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType} laid out');
      final before = tester.getTopLeft(find.text(title));
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text(title)), before, reason: '${screen.runtimeType} title stayed put');
      if (row != null) expect(find.text(row), findsOneWidget, reason: 'column headings still shown');
    }
  });

  testWidgets('A short window scrolls the whole page instead of pinning', (tester) async {
    await _pump(tester, const PatientsScreen(), size: const Size(1920, 560), withApi: _ManyPatientsApi());
    expect(find.ancestor(of: find.text('Patient 1'), matching: find.byType(ListView)), findsNothing,
        reason: 'no separate row scroller on a short window');
    expect(find.ancestor(of: find.text('Patient 1'), matching: find.byType(SingleChildScrollView)),
        findsWidgets);
  });

  for (final (name, screen, row, viewOnly) in [
    ('Patients', const PatientsScreen() as Widget, 'Pieter van Wyk', 'South African'),
    ('Doctors', const DoctorsScreen(), 'Naledi Mokoena', 'Paediatrician'),
    ('Pharmacies', const PharmaciesScreen(), 'HealthPlus Pharmacy', 'Prescription Filling'),
  ]) {
    testWidgets('$name: a row opens its details in place of the table; Back restores it', (tester) async {
      await _pump(tester, screen);
      final total = find.text('Total $name');
      expect(total, findsOneWidget);

      await _tap(tester, find.text(row));
      expect(find.byType(Dialog), findsNothing, reason: 'no pop-up');
      expect(find.text(viewOnly), findsOneWidget, reason: 'full record shown');
      expect(total, findsNothing, reason: 'the table and its stats are replaced');

      await _tap(tester, find.text('Back to list'));
      expect(total, findsOneWidget);
      expect(find.text(viewOnly), findsNothing);
      expect(find.text(row), findsOneWidget);

      // The View button opens it the same way.
      await _tap(tester, find.byTooltip('View').first);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Back to list'), findsOneWidget);
    });
  }
}

/// Drags the table's rows and checks they scrolled while [pinned] did not
/// move.
Future<void> _expectPinnedWhileRowsScroll(
  WidgetTester tester, {
  required List<Finder> pinned,
  required Finder dragFrom,
}) async {
  final before = [for (final f in pinned) tester.getTopLeft(f)];
  // The nearest vertical scroller around a row: the table's own row list,
  // or on a page of sections, the scroller they share. (A table also has a
  // horizontal scroller, and the sidebar a ListView, so neither the first
  // match nor the type alone will do.)
  final rows = tester
      .stateList<ScrollableState>(find.ancestor(of: dragFrom, matching: find.byType(Scrollable)))
      .firstWhere((s) => s.position.axis == Axis.vertical);

  await tester.drag(dragFrom, const Offset(0, -250));
  await tester.pumpAndSettle();

  expect(rows.position.pixels, greaterThan(0), reason: 'the rows scrolled');
  for (var i = 0; i < pinned.length; i++) {
    expect(tester.getTopLeft(pinned[i]), before[i], reason: '${pinned[i]} stayed put');
  }
}

class _ManyPharmaciesApi extends _CannedApi {
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path.endsWith('/admin/pharmacies')) {
      return {
        'total': 40,
        'pharmacies': [
          for (var i = 1; i <= 40; i++)
            {
              'id': 100 + i,
              'pharmacy_name': 'Pharmacy $i',
              'first_name': 'Owner',
              'last_name': '$i',
              'email': 'ph$i@example.test',
              'city': 'Johannesburg',
              'status': 'active',
              'created_at': '2026-10-01T00:00:00Z',
            },
        ],
      };
    }
    return super.get(path, query: query);
  }
}

class _ManyPatientsApi extends _CannedApi {
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path.endsWith('/admin/patients')) {
      return {
        'total': 60,
        'patients': [
          for (var i = 1; i <= 60; i++)
            {
              'id': i,
              'first_name': 'Patient',
              'last_name': '$i',
              'email': 'p$i@example.test',
              'status': 'active',
              'email_verified': true,
              'created_at': '2026-10-01T00:00:00Z',
            },
        ],
      };
    }
    return super.get(path, query: query);
  }
}

/// Long lists for the pinned-layout tests.
class _ManyRowsApi extends _CannedApi {
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path.endsWith('/partnerships/groups')) {
      return [
        for (var i = 1; i <= 40; i++)
          {..._CannedApi._group, 'id': i, 'group_name': 'Group $i'},
      ];
    }
    if (path.endsWith('/partnerships/agreements')) {
      return [
        for (var i = 1; i <= 40; i++) {..._CannedApi._agreement, 'id': 1000 + i},
      ];
    }
    if (path.endsWith('/security/dashboard')) {
      final base = Map<String, dynamic>.from(await super.get(path, query: query) as Map);
      return {
        ...base,
        'impossible_travels': [
          for (var i = 1; i <= 30; i++) {'email': 'user$i@y.test', 'country': 'ZA', 'city': 'Durban'},
        ],
      };
    }
    if (path.endsWith('/security/user-locations')) {
      return {
        'locations': [
          for (var i = 1; i <= 40; i++)
            {'country': 'ZA', 'city': 'City $i', 'timezone': 'Africa/Johannesburg', 'login_count': '$i'},
        ],
      };
    }
    return super.get(path, query: query);
  }
}
