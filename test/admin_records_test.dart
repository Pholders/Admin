import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/core/error/failures.dart';
import 'package:pholders_admin/core/network/admin_api.dart';
import 'package:pholders_admin/core/network/api_client.dart';
import 'package:pholders_admin/screens/all_orders_screen.dart';
import 'package:pholders_admin/screens/appointments_screen.dart';
import 'package:pholders_admin/screens/billing_payments_screen.dart';
import 'package:pholders_admin/screens/prescriptions_screen.dart';
import 'package:pholders_admin/screens/reviews_screen.dart';
import 'package:pholders_admin/screens/security_alerts_screen.dart';
import 'package:pholders_admin/screens/support_tickets_screen.dart';
import 'package:pholders_admin/store.dart';
import 'package:pholders_admin/widgets/admin/admin_format.dart';
import 'package:redux/redux.dart';

/// Answers with the example bodies from the backend's admin-records guide.
class _RecordsApi extends AdminApi {
  _RecordsApi() : super(apiClient: ApiClient(), secureStorage: const FlutterSecureStorage());

  final gets = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final writes = <String>[];
  final bodies = <String, Object?>{};

  bool replyEmailSent = true;

  /// A full page of 50 rows per list, to make the table taller than the
  /// window.
  bool fullPage = false;
  String ticketStatus = 'open';

  static const _order = {
    'id': 42, 'status': 'ready', 'payment_type': 'medical_aid', 'fulfillment_type': 'pickup',
    'total_amount': 350.5, 'patient_responsibility': 50, 'prescription_id': 17,
    'prescription_number': 'RX-2026-000017', 'patient_id': 8, 'patient_name': 'Thandi Nkosi',
    'patient_email': 'thandi@example.com', 'pharmacy_id': 3, 'pharmacy_name': 'Greenside Pharmacy',
    'created_at': '2026-11-08T09:14:02.000Z', 'updated_at': '2026-11-08T11:40:10.000Z',
    'completed_at': null, 'cancelled_at': null,
  };
  static const _prescription = {
    'id': 17, 'prescription_number': 'RX-2026-000017', 'signature_status': 'signed', 'state': 'active',
    'is_revoked': false, 'is_dispensed': false, 'claimed': true, 'claimed_at': '2026-11-08T09:00:00Z',
    'claim_expires_at': '2026-11-09T09:00:00Z', 'claimed_by_pharmacy_id': '3',
    'claimed_by_pharmacy_name': 'Greenside Pharmacy', 'item_count': 2, 'appointment_id': 27,
    'patient_id': 8, 'patient_name': 'Thandi Nkosi', 'doctor_id': 5, 'doctor_name': 'Sipho Dlamini',
    'created_at': '2026-11-07T10:00:00Z',
  };
  static const _alert = {
    'id': 77, 'user_id': 8, 'user_type': 'patient', 'email': 'thandi@example.com',
    'alert_type': 'IMPOSSIBLE_TRAVEL', 'severity': 'CRITICAL', 'risk_score': 90,
    'alert_message': 'Login from Lagos 20 minutes after Johannesburg', 'status': 'unreviewed',
    'location_data': {'city': 'Lagos'}, 'device_data': {'browser': 'Chrome'}, 'email_sent': true,
    'created_at': '2026-11-08T09:14:02.000Z',
  };

  Map<String, dynamic> _ticket() => {
        'id': 12, 'patient_id': null, 'email': 'visitor@example.com', 'first_name': 'Sam', 'last_name': 'Visitor',
        'category': 'billing', 'subject': 'Charged twice', 'status': ticketStatus, 'priority': 'normal',
        'reply_count': 0, 'created_at': '2026-11-08T09:14:02.000Z',
        'message': 'I was charged twice.\nPlease help.', 'ip_address': '102.0.0.1', 'user_agent': 'Mozilla/5.0',
        'replies': <dynamic>[],
      };

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final body = await _get(path, query);
    if (!fullPage || body is! Map || body['total'] == null) return body;
    final key = body.keys.firstWhere((k) => body[k] is List);
    final row = Map<String, dynamic>.from((body[key] as List).first as Map);
    return {
      ...body,
      'total': 500,
      key: [for (var i = 1; i <= 50; i++) {...row, 'id': i, 'patient_name': 'Row $i', 'prescription_number': 'RX-$i'}],
    };
  }

  Future<dynamic> _get(String path, Map<String, dynamic>? query) async {
    gets.add(path);
    queries[path] = query;
    const base = '/users/admin';
    if (path == '$base/orders') return {'total': 137, 'limit': 50, 'offset': 0, 'orders': [_order]};
    if (path == '$base/orders/42') {
      return {
        ..._order,
        'pharmacy_notes': 'Out of stock, ordered in',
        'status_history': [
          {'id': 1, 'from_status': null, 'to_status': 'pending', 'actor_type': 'patient', 'actor_id': 8, 'created_at': '2026-11-08T09:14:02Z'},
          {'id': 2, 'from_status': 'pending', 'to_status': 'accepted', 'actor_type': 'pharmacy', 'actor_id': 3, 'created_at': '2026-11-08T09:20:00Z'},
        ],
      };
    }
    if (path == '$base/payments') {
      return {
        'total': 38, 'limit': 50, 'offset': 0,
        'totals': {
          'currency': 'ZAR',
          'by_status': {'completed': {'count': 30, 'amount': 15400}, 'failed': {'count': 3, 'amount': 1500}},
        },
        'payments': [
          {'id': 91, 'amount': 500, 'payment_method': 'stripe', 'payment_status': 'completed', 'appointment_id': 27,
           'patient_id': 8, 'patient_name': 'Thandi Nkosi', 'patient_email': 'thandi@example.com',
           'doctor_id': 5, 'doctor_name': 'Sipho Dlamini', 'created_at': '2026-11-08T09:14:02Z'},
        ],
      };
    }
    if (path == '$base/appointments') {
      return {'total': 1, 'limit': 50, 'offset': 0, 'appointments': [
        {'id': 27, 'appointment_date': '2026-11-12', 'time_period': 'morning', 'time_slot': '09:30', 'status': 'scheduled',
         'consultation_fee': 500, 'payment_status': 'completed', 'payment_method': 'stripe', 'doctor_accepted': true,
         'patient_id': 8, 'patient_name': 'Thandi Nkosi', 'doctor_id': 5, 'doctor_name': 'Sipho Dlamini',
         'created_at': '2026-11-08T09:14:02Z'},
      ]};
    }
    if (path == '$base/prescriptions') return {'total': 1, 'limit': 50, 'offset': 0, 'prescriptions': [_prescription]};
    if (path == '$base/prescriptions/17') {
      return {..._prescription, 'orders': [{'id': 42, 'status': 'ready', 'pharmacy_id': 3, 'pharmacy_name': 'Greenside Pharmacy', 'created_at': '2026-11-08T09:14:02Z'}]};
    }
    if (path == '$base/support/tickets') {
      final t = _ticket()..remove('message')..remove('replies');
      return {'total': 1, 'limit': 50, 'offset': 0, 'tickets': [t]};
    }
    if (path == '$base/support/tickets/12') return _ticket();
    if (path == '$base/reviews') {
      return {'total': 1, 'limit': 50, 'offset': 0, 'reviews': [
        {'id': 4, 'rating': 1, 'review_text': 'Rude and late', 'is_verified': false, 'is_hidden': false,
         'doctor_id': 5, 'doctor_name': 'Sipho Dlamini', 'patient_id': 8, 'patient_name': 'Thandi Nkosi',
         'created_at': '2026-11-08T09:14:02Z'},
      ]};
    }
    if (path == '$base/security/alerts/stats') {
      return {
        'last_24_hours': {'total': 5, 'unreviewed': 4, 'critical': 2, 'high': 1, 'affected_users': 3},
        'last_7_days': {'total': 21, 'unreviewed': 9, 'critical': 4, 'high': 6, 'affected_users': 11},
        'unreviewed_critical_or_high': 7,
      };
    }
    if (path == '$base/security/alerts') {
      return {'total': 2, 'limit': 50, 'offset': 0, 'alerts': [_alert, {..._alert, 'id': 78, 'severity': 'HIGH', 'alert_type': 'NEW_DEVICE'}]};
    }
    if (path == '$base/security/suspicious-users') {
      return {'hours': 24, 'threshold': 3, 'count': 1, 'users': [
        {'user_id': 8, 'user_type': 'patient', 'email': 'thandi@example.com', 'alert_count': 4, 'critical_count': 3,
         'avg_risk_score': 85, 'latest_alert': '2026-11-08T09:14:02Z', 'alert_types': ['IMPOSSIBLE_TRAVEL', 'NEW_DEVICE']},
      ]};
    }
    if (path == '$base/security/report') {
      return {
        'period': {'from': '2026-10-29', 'to': '2026-10-31'},
        'report': [{'date': '2026-10-31', 'alert_type': 'NEW_DEVICE', 'severity': 'MEDIUM', 'count': 3, 'confirmed_threats': 0, 'avg_risk_score': 40}],
      };
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    writes.add('POST $path');
    bodies[path] = body;
    if (path.endsWith('/replies')) {
      if (ticketStatus == 'closed') {
        throw const ServerFailure('Ticket is closed. Reopen it before replying.');
      }
      ticketStatus = 'in_progress';
      return {
        'email_sent': replyEmailSent,
        'ticket': {
          ..._ticket(),
          'replies': [
            {'id': 3, 'admin_id': 1, 'admin_name': 'Admin User', 'message': (body as Map)['message'],
             'email_sent': replyEmailSent, 'created_at': '2026-11-09T08:00:00Z'},
          ],
        },
      };
    }
    if (path.endsWith('/bulk-review')) return {'updated_count': 2, 'not_found': <int>[], 'sessions_revoked': 0};
    if (path.endsWith('/review')) return {..._alert, 'status': (body as Map)['status'], 'sessions_revoked': 2};
    return {'ok': true};
  }

  @override
  Future<dynamic> patch(String path, {Object? body}) async {
    writes.add('PATCH $path');
    bodies[path] = body;
    if (path.contains('/support/tickets/')) {
      final b = body as Map;
      if (b['status'] != null) ticketStatus = '${b['status']}';
      return _ticket();
    }
    return {'id': 4, 'is_hidden': (body as Map)['hidden']};
  }

  @override
  Future<dynamic> delete(String path) async {
    writes.add('DELETE $path');
    return {'id': 4};
  }
}

Future<(Store<AppState>, _RecordsApi)> _pump(WidgetTester tester, Widget screen, {_RecordsApi? api}) async {
  tester.view.physicalSize = const Size(1920, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  api ??= _RecordsApi();
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
    child: MaterialApp(
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('formatting', () {
    test('timestamps show in Africa/Johannesburg time, plain dates unshifted', () {
      expect(formatDate('2026-11-08T23:30:00.000Z', withTime: true), '9 Nov 2026, 01:30');
      expect(formatDate('2026-11-12'), '12 Nov 2026');
    });

    test('the security report fills days without alerts with zero', () {
      final days = dailyAlertTotals(
        [
          {'date': '2026-10-31', 'count': 3},
          {'date': '2026-10-31', 'count': 2},
        ],
        from: '2026-10-29',
        to: '2026-10-31',
      );
      expect(days, [('2026-10-29', 0), ('2026-10-30', 0), ('2026-10-31', 5)]);
    });
  });

  testWidgets('Orders: total from the server, filters as query, detail with timeline', (tester) async {
    final (_, api) = await _pump(tester, const AllOrdersScreen());
    expect(api.queries['/users/admin/orders'], {'limit': 50, 'offset': 0});
    expect(find.text('Thandi Nkosi'), findsOneWidget);
    expect(find.textContaining('137 orders'), findsOneWidget, reason: '`total` counts every match');
    expect(find.text(formatRand(350.5)), findsOneWidget);
    expect(find.text('Maria Wilson'), findsNothing, reason: 'sample rows are gone');

    await _tap(tester, find.text('Thandi Nkosi'));
    expect(api.gets, contains('/users/admin/orders/42'));
    expect(find.text('Status history'), findsOneWidget);
    expect(find.text('Out of stock, ordered in'), findsOneWidget);
    expect(find.textContaining('by pharmacy #3'), findsOneWidget);
  });

  testWidgets('Payments: totals cover the filtered set, a missing status counts as 0', (tester) async {
    await _pump(tester, const BillingPaymentsScreen());
    expect(find.text('Completed · 30'), findsOneWidget);
    expect(find.text(formatRand(15400)), findsOneWidget);
    expect(find.text('Pending · 0'), findsOneWidget);
    expect(find.text('Cancelled · 0'), findsOneWidget);
  });

  testWidgets('Appointments: the plain appointment date is not shifted', (tester) async {
    await _pump(tester, const AppointmentsScreen());
    expect(find.text('12 Nov 2026'), findsOneWidget);
    expect(find.text('Morning, 09:30'), findsOneWidget);
  });

  testWidgets('Prescriptions: the audit-logged detail is fetched only on a click', (tester) async {
    final (_, api) = await _pump(tester, const PrescriptionsScreen());
    expect(find.text('RX-2026-000017'), findsOneWidget);
    expect(api.gets.where((p) => p.endsWith('/prescriptions/17')), isEmpty);

    await _tap(tester, find.text('RX-2026-000017'));
    expect(api.gets.where((p) => p.endsWith('/prescriptions/17')), hasLength(1));
    expect(find.textContaining('audit log'), findsWidgets);
    // Its order opens on top.
    await _tap(tester, find.text('#42'));
    expect(api.gets, contains('/users/admin/orders/42'));
  });

  testWidgets('Tickets: reply that could not be emailed warns and is marked', (tester) async {
    final api = _RecordsApi()..replyEmailSent = false;
    await _pump(tester, const SupportTicketsScreen(), api: api);
    expect(find.text('Charged twice'), findsOneWidget);
    expect(find.text('Sam Visitor · visitor@example.com'), findsOneWidget);

    await _tap(tester, find.text('Charged twice'));
    expect(find.text('I was charged twice.\nPlease help.'), findsOneWidget);
    expect(find.textContaining('moves this ticket to In progress'), findsOneWidget);
    expect(find.text('Not signed in'), findsOneWidget, reason: 'no patient_id');

    await tester.enterText(find.byType(TextField).last, 'We refunded the duplicate.');
    await tester.pump();
    await _tap(tester, find.text('Send reply'));
    expect(api.bodies['/users/admin/support/tickets/12/replies'], {'message': 'We refunded the duplicate.'});
    expect(find.text('Reply saved, but the email could not be sent.'), findsOneWidget);
    expect(find.text('Not emailed'), findsOneWidget);
    expect(api.writes.where((w) => w.endsWith('/replies')), hasLength(1), reason: 'never resent');
  });

  testWidgets('Tickets: a closed ticket must be reopened before replying', (tester) async {
    final api = _RecordsApi()..ticketStatus = 'closed';
    await _pump(tester, const SupportTicketsScreen(), api: api);
    await _tap(tester, find.text('Charged twice'));
    expect(find.textContaining('This ticket is closed'), findsOneWidget);
    expect(find.text('Send reply'), findsNothing);

    await _tap(tester, find.text('Closed').last);
    await _tap(tester, find.text('In Progress').last);
    expect(api.bodies['/users/admin/support/tickets/12'], {'status': 'in_progress'});
    expect(find.text('Send reply'), findsOneWidget, reason: 'the reply box is back');
  });

  testWidgets('Reviews: hiding asks for a reason; deleting asks first', (tester) async {
    final (_, api) = await _pump(tester, const ReviewsScreen());
    expect(find.text('Rude and late'), findsOneWidget);

    await _tap(tester, find.byTooltip('Hide'));
    final hide = find.widgetWithText(ElevatedButton, 'Hide review');
    expect(tester.widget<ElevatedButton>(hide).onPressed, isNull, reason: 'reason is required');
    await tester.enterText(find.byType(TextField).last, 'Abusive language');
    await tester.pump();
    await _tap(tester, hide);
    expect(api.bodies['/users/admin/reviews/4/visibility'], {'hidden': true, 'reason': 'Abusive language'});

    await _tap(tester, find.byTooltip('Delete permanently'));
    expect(api.writes.where((w) => w.startsWith('DELETE')), isEmpty);
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Delete permanently'));
    expect(api.writes, contains('DELETE /users/admin/reviews/4'));
  });

  testWidgets('Security alerts: stats, unreviewed first, and a confirmed threat review', (tester) async {
    final (_, api) = await _pump(tester, const SecurityAlertsScreen());
    expect(find.textContaining('7 critical or high alerts'), findsOneWidget);
    expect(api.queries['/users/admin/security/alerts'], containsPair('status', 'unreviewed'));
    expect(find.text('Login from Lagos 20 minutes after Johannesburg'), findsWidgets);

    await _tap(tester, find.text('Impossible Travel'));
    await _tap(tester, find.widgetWithText(DropdownButton<String>, 'Choose an outcome'));
    await _tap(tester, find.text('Threat (sign the account out)').last);
    await _tap(tester, find.text('Save review'));
    expect(find.text('Mark as a threat?'), findsOneWidget, reason: 'a threat signs the account out');
    expect(api.writes, isEmpty);
    await _tap(tester, find.text('Mark as threat'));
    expect(api.bodies['/users/admin/security/alerts/77/review'], {'status': 'verified_threat'});
    expect(find.textContaining('2 sessions signed out'), findsOneWidget);
  });

  testWidgets('Security alerts: bulk dismiss sends the selected ids', (tester) async {
    final (_, api) = await _pump(tester, const SecurityAlertsScreen());
    await _tap(tester, find.text('Select this page'));
    expect(find.text('2 selected'), findsOneWidget);
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Dismiss'));
    await tester.enterText(find.byType(TextField).last, 'Known VPN');
    await _tap(tester, find.text('Continue'));
    expect(api.bodies['/users/admin/security/alerts/bulk-review'],
        {'alertIds': [77, 78], 'status': 'dismissed', 'actionReason': 'Known VPN'});
    expect(find.textContaining('Updated 2 alerts'), findsOneWidget);
  });

  testWidgets('Security alerts: a suspicious account drills into its alerts', (tester) async {
    final (_, api) = await _pump(tester, const SecurityAlertsScreen());
    await _tap(tester, find.text('Suspicious accounts'));
    expect(api.queries['/users/admin/security/suspicious-users'], {'hours': 24, 'threshold': 3});
    await _tap(tester, find.text('thandi@example.com').first);
    expect(api.queries['/users/admin/security/alerts'], {'user_type': 'patient', 'user_id': 8, 'limit': 50, 'offset': 0});

    await _tap(tester, find.text('Daily report'));
    expect(find.textContaining('3 alerts'), findsOneWidget);
  });

  // (title, screen, its first filter's label, a column heading)
  for (final (name, screen, filter, heading) in const [
    ('Doctor Reviews', ReviewsScreen(), 'Rating', 'Written'),
    ('Appointments', AppointmentsScreen(), 'Status', 'Booked'),
    ('Prescriptions', PrescriptionsScreen(), 'State', 'Claimed by'),
    ('All Orders', AllOrdersScreen(), 'Status', 'Created'),
  ]) {
    testWidgets('$name: title, filters and column headings stay put while rows scroll', (tester) async {
      await _pump(tester, screen, api: _RecordsApi()..fullPage = true);
      final pinned = [find.text(name).last, find.text(filter).first, find.text(heading).last];
      Offset at(Finder f) => tester.getTopLeft(f);
      final before = [for (final f in pinned) at(f)];
      final firstRow = find.textContaining(RegExp(r'^(Row 5|RX-5)$')).first;
      final rowBefore = at(firstRow);

      await tester.drag(firstRow, const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(at(firstRow).dy, lessThan(rowBefore.dy), reason: 'the rows scrolled');
      for (var i = 0; i < pinned.length; i++) {
        expect(at(pinned[i]), before[i], reason: '${pinned[i]} must not move');
      }
      expect(find.textContaining('500 '), findsOneWidget, reason: 'page controls stay on screen');
    });
  }

  testWidgets('A short window scrolls the whole record page instead of pinning', (tester) async {
    tester.view.physicalSize = const Size(1920, 560);
    await _pump(tester, const AllOrdersScreen(), api: _RecordsApi()..fullPage = true);
    tester.view.physicalSize = const Size(1920, 560);
    await tester.pumpAndSettle();
    expect(find.ancestor(of: find.text('All Orders').last, matching: find.byType(SingleChildScrollView)),
        findsWidgets);
  });

  testWidgets('Security Alerts: stats, tabs, filters and headings stay put while alert rows scroll', (tester) async {
    await _pump(tester, const SecurityAlertsScreen(), api: _RecordsApi()..fullPage = true);
    final pinned = [find.text('Accounts affected'), find.text('Daily report'), find.text('Severity').first, find.text('Owner said')];
    final before = [for (final f in pinned) tester.getTopLeft(f)];
    final row = find.text('thandi@example.com').at(4);
    final rowBefore = tester.getTopLeft(row);
    await tester.drag(row, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(row).dy, lessThan(rowBefore.dy), reason: 'the rows scrolled');
    for (var i = 0; i < pinned.length; i++) {
      expect(tester.getTopLeft(pinned[i]), before[i], reason: '${pinned[i]} must not move');
    }
  });

  testWidgets('Details replace the table instead of opening a pop-up; Back restores it', (tester) async {
    final (_, api) = await _pump(tester, const AllOrdersScreen());
    // Filter first, so we can check the table comes back as it was left.
    await _tap(tester, find.text('All').first);
    await _tap(tester, find.text('Ready').last);
    expect(api.queries['/users/admin/orders'], containsPair('status', 'ready'));
    final listLoads = api.gets.where((g) => g == '/users/admin/orders').length;

    await _tap(tester, find.text('Thandi Nkosi'));
    expect(find.byType(Dialog), findsNothing, reason: 'no pop-up');
    expect(find.text('Order #42'), findsOneWidget);
    expect(find.text('Status history'), findsOneWidget);
    expect(find.text('Clear filters'), findsNothing, reason: 'the table and its filters are hidden');

    await _tap(tester, find.text('Back to list'));
    expect(find.text('Order #42'), findsNothing);
    expect(find.text('Clear filters'), findsOneWidget, reason: 'the filter is still applied');
    expect(find.text('Thandi Nkosi'), findsOneWidget);
    expect(api.gets.where((g) => g == '/users/admin/orders').length, listLoads,
        reason: 'returning does not reload the list');
  });

  testWidgets('A detail opened from a detail stacks, and Back steps down one level', (tester) async {
    final (_, api) = await _pump(tester, const PrescriptionsScreen());
    await _tap(tester, find.text('RX-2026-000017'));
    await _tap(tester, find.text('#42'));
    expect(find.text('Order #42'), findsOneWidget);

    await _tap(tester, find.text('Back'));
    expect(find.text('Order #42'), findsNothing);
    expect(find.text('Opening a prescription is recorded in the audit log under your name'), findsOneWidget,
        reason: 'back on the prescription');
    expect(api.gets.where((p) => p.endsWith('/prescriptions/17')), hasLength(1),
        reason: 'stepping back does not log a second prescription view');

    await _tap(tester, find.text('Back to list'));
    expect(find.text('Claimed by'), findsOneWidget, reason: 'back on the table');
  });
}
