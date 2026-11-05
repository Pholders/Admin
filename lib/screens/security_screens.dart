import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

const _windows = [(24, 'Last 24 hours'), (72, '3 days'), (168, '7 days'), (720, '30 days')];

/// Sign-in activity across the platform, with impossible-travel and
/// suspicious-location alerts.
class SecurityOverviewScreen extends StatefulWidget {
  const SecurityOverviewScreen({super.key});

  @override
  State<SecurityOverviewScreen> createState() => _SecurityOverviewScreenState();
}

class _SecurityOverviewScreenState extends State<SecurityOverviewScreen> {
  int _hours = 24;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Security Overview',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(
              title: 'Security Overview',
              subtitle: 'Sign-in activity and location alerts from the audit log',
              actions: [
                SecondaryButton(
                    label: 'Refresh',
                    icon: Icons.refresh,
                    onPressed: () => reloadAdmin(context, AdminResource.securityDashboard)),
              ],
            ),
            const SizedBox(height: 18),
            FilterPills<int>(
              options: _windows,
              selected: _hours,
              onSelected: (v) {
                setState(() => _hours = v);
                loadAdmin(context, AdminResource.securityDashboard, params: {'hours': v});
              },
            ),
            const SizedBox(height: 18),
            AdminResourceBuilder(
              resource: AdminResource.securityDashboard,
              load: {'hours': _hours},
              builder: (context, data) => AsyncContent(
                data: data,
                onRetry: () => reloadAdmin(context, AdminResource.securityDashboard),
                builder: (raw) => _Dashboard(data: mapOf(raw)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Dashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = mapOf(data['summary']);
    final alerts = mapOf(data['alerts']);
    String n(dynamic v) => formatValue(numOf(v) ?? 0);
    final travelCount = numOf(alerts['impossible_travels']) ?? 0;
    final suspiciousCount = numOf(alerts['suspicious_locations']) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (travelCount > 0 || suspiciousCount > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.alertBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.alertIcon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${formatNumber(travelCount)} impossible-travel and '
                  '${formatNumber(suspiciousCount)} suspicious-location alerts in this period.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
        ],
        StatGrid(perRow: 5, stats: [
          StatCardData(label: 'Sign-ins', value: n(s['total_logins']), icon: Icons.login),
          StatCardData(label: 'Failed Attempts', value: n(s['failed_attempts']), icon: Icons.gpp_bad_outlined),
          StatCardData(label: 'Impossible Travel', value: n(s['impossible_travels']), icon: Icons.flight_outlined),
          StatCardData(label: 'Countries', value: n(s['unique_locations']), icon: Icons.public),
          StatCardData(label: 'Unique IPs', value: n(s['unique_ips']), icon: Icons.lan_outlined),
        ]),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Impossible Travel',
          subtitle: 'Accounts that signed in from places too far apart for the time between',
          child: RecordTable(
            rows: recordsOf(data['impossible_travels']),
            maxAutoColumns: 9,
            emptyMessage: 'No impossible-travel alerts in this period.',
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Suspicious Locations',
          subtitle: 'Locations with repeated failed sign-ins',
          child: RecordTable(
            rows: recordsOf(data['suspicious_locations']),
            emptyMessage: 'No suspicious locations in this period.',
            columns: [
              RecordColumn('Location',
                  width: 200,
                  cell: (r) => CellText(
                      [r['city'], r['country']].where((v) => v != null).join(', ').ifEmpty('Unknown'),
                      strong: true,
                      subtitle: r['isp']?.toString())),
              const RecordColumn('Attempts', field: 'attempt_count', width: 100),
              const RecordColumn('Failed', field: 'failed_attempts', width: 90),
              const RecordColumn('Accounts', field: 'emails', width: 280),
              const RecordColumn('Last Attempt', field: 'last_attempt', width: 160),
            ],
          ),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

/// Where one user has signed in from.
class LoginLocationsScreen extends StatefulWidget {
  const LoginLocationsScreen({super.key});

  @override
  State<LoginLocationsScreen> createState() => _LoginLocationsScreenState();
}

class _LoginLocationsScreenState extends State<LoginLocationsScreen> {
  final _userId = TextEditingController();
  int _days = 30;
  String? _error;

  @override
  void dispose() {
    _userId.dispose();
    super.dispose();
  }

  void _search() {
    final id = _userId.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Enter a user ID.');
      return;
    }
    setState(() => _error = null);
    loadAdmin(context, AdminResource.userLocations, params: {'user_id': id, 'days': _days}, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Login Locations',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle(
              title: 'Login Locations',
              subtitle: 'Where a user has signed in from, grouped by city',
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: 220,
                        child: LabeledField(
                          label: 'User ID',
                          required: true,
                          child: AdminTextInput(
                              controller: _userId, hint: 'e.g. 42', onSubmitted: (_) => _search()),
                        ),
                      ),
                      LabeledField(
                        label: 'Period',
                        child: FilterPills<int>(
                          options: const [(7, '7 days'), (30, '30 days'), (90, '90 days'), (365, '1 year')],
                          selected: _days,
                          onSelected: (v) {
                            setState(() => _days = v);
                            if (_userId.text.trim().isNotEmpty) _search();
                          },
                        ),
                      ),
                      PrimaryButton(label: 'Look Up', icon: Icons.search, onPressed: _search),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    ErrorPanel(message: _error!, compact: true),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    'User IDs are shared across patients, doctors, pharmacies and admins in the audit log.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  AdminResourceBuilder(
                    resource: AdminResource.userLocations,
                    builder: (context, data) => AsyncContent(
                      data: data,
                      idleMessage: 'Enter a user ID to see where they have signed in from.',
                      onRetry: () => reloadAdmin(context, AdminResource.userLocations),
                      builder: (raw) => RecordTable(
                        rows: recordsOf(raw, ['locations']),
                        emptyMessage: 'No sign-ins recorded for this user in this period.',
                        columns: [
                          RecordColumn('Location',
                              width: 240,
                              cell: (r) => CellText(
                                  [r['city'], r['country']].where((v) => v != null).join(', ').ifEmpty('Unknown'),
                                  strong: true)),
                          const RecordColumn('Time Zone', field: 'timezone', width: 170),
                          const RecordColumn('Sign-ins', field: 'login_count', width: 100),
                          const RecordColumn('First Seen', field: 'first_login', width: 170),
                          const RecordColumn('Last Seen', field: 'last_login', width: 170),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
