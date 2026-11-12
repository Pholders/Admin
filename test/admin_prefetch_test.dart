import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/core/network/admin_api.dart';
import 'package:pholders_admin/core/network/api_client.dart';
import 'package:pholders_admin/screens/account_screen.dart';
import 'package:pholders_admin/screens/agreements_screen.dart';
import 'package:pholders_admin/screens/all_orders_screen.dart';
import 'package:pholders_admin/screens/appointments_screen.dart';
import 'package:pholders_admin/screens/billing_payments_screen.dart';
import 'package:pholders_admin/screens/claim_routing_screen.dart';
import 'package:pholders_admin/screens/compliance_screen.dart';
import 'package:pholders_admin/screens/dashboard_screen.dart';
import 'package:pholders_admin/screens/doctors_screen.dart';
import 'package:pholders_admin/screens/partner_groups_screen.dart';
import 'package:pholders_admin/screens/patients_screen.dart';
import 'package:pholders_admin/screens/pharmacies_screen.dart';
import 'package:pholders_admin/screens/prescriptions_screen.dart';
import 'package:pholders_admin/screens/reviews_screen.dart';
import 'package:pholders_admin/screens/security_alerts_screen.dart';
import 'package:pholders_admin/screens/security_screens.dart';
import 'package:pholders_admin/screens/support_tickets_screen.dart';
import 'package:pholders_admin/store.dart';
import 'package:redux/redux.dart';

/// Answers every GET with an empty body of the right shape, and counts them.
class _CountingApi extends AdminApi {
  _CountingApi() : super(apiClient: ApiClient(), secureStorage: const FlutterSecureStorage());

  final gets = <String>[];

  static const _lists = ['/partnerships/groups', '/partnerships/agreements', '/activity-log', '/routing/by-tier'];

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    gets.add('$path ${query ?? {}}');
    if (_lists.any(path.endsWith)) return <dynamic>[];
    return <String, dynamic>{'total': 0};
  }
}

Store<AppState> _store(_CountingApi api, {bool signedIn = true}) => Store<AppState>(
      appReducer,
      initialState: AppState(
        authState: signedIn
            ? const AuthState(token: 't', role: 'admin', userName: 'Ada')
            : AuthState.initial(),
        navigationState: const NavigationState(),
      ),
      middleware: AdminMiddleware(api: api).middleware,
    );

Future<void> _pump(WidgetTester tester, Store<AppState> store, Widget screen) async {
  tester.view.physicalSize = const Size(1920, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(StoreProvider<AppState>(
    store: store,
    child: MaterialApp(
      key: UniqueKey(),
      theme: ThemeData(platform: TargetPlatform.windows),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.7)),
        child: child!,
      ),
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('the prefetch loads every startup resource once, and only when signed in', () async {
    final api = _CountingApi();
    _store(api, signedIn: false).dispatch(const PrefetchAdminDataAction());
    await Future<void>.delayed(Duration.zero);
    expect(api.gets, isEmpty);

    final store = _store(api)..dispatch(const PrefetchAdminDataAction());
    await Future<void>.delayed(Duration.zero);
    expect(api.gets, hasLength(adminStartupLoads.length));
    for (final (resource, _) in adminStartupLoads) {
      expect(store.state.adminState.of(resource).hasData, isTrue, reason: '$resource');
    }
  });

  test('signing in starts the prefetch', () async {
    final api = _CountingApi();
    _store(api, signedIn: false)
        .dispatch(const LoginSuccessAction(token: 't', role: 'admin', userName: 'Ada'));
    await Future<void>.delayed(Duration.zero);
    expect(api.gets, hasLength(adminStartupLoads.length));
  });

  testWidgets('after the prefetch, opening any screen makes no new request', (tester) async {
    final api = _CountingApi();
    final store = _store(api)..dispatch(const PrefetchAdminDataAction());
    await tester.pump();
    final before = api.gets.length;

    const screens = <Widget>[
      DashboardScreen(), PatientsScreen(), DoctorsScreen(), PharmaciesScreen(), ReviewsScreen(),
      AppointmentsScreen(), PrescriptionsScreen(), AllOrdersScreen(), BillingPaymentsScreen(),
      PartnerGroupsScreen(), AgreementsScreen(), ComplianceScreen(), ClaimRoutingScreen(),
      SecurityAlertsScreen(), SecurityOverviewScreen(), SupportTicketsScreen(), AccountScreen(),
    ];
    for (final screen in screens) {
      await _pump(tester, store, screen);
      expect(api.gets.sublist(before), isEmpty, reason: '${screen.runtimeType} fetched again');
    }

    // The Security Alerts tabs too.
    await _pump(tester, store, const SecurityAlertsScreen());
    await tester.tap(find.text('Suspicious accounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily report'));
    await tester.pumpAndSettle();
    expect(api.gets.sublist(before), isEmpty);
  });
}
