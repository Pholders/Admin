import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

/// Agreement compliance: the dashboard summary, top and low performers, a
/// per-pharmacy lookup, and a date-range report.
class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Compliance',
      body: PinnedPage(
          sections: true,
          header: [
            ScreenTitle(
              title: 'Compliance',
              subtitle: 'How partners are meeting their agreement SLAs',
              actions: [
                SecondaryButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () => loadAdmin(context, AdminResource.complianceDashboard, force: true),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          body: (_) => const Column(children: [
            _Dashboard(),
            SizedBox(height: 18),
            _PharmacyLookup(),
            SizedBox(height: 18),
            _Report(),
          ]),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.complianceDashboard,
      load: const {},
      builder: (context, data) {
        final d = mapOf(data.data);
        // The summary aggregates only the latest month of compliance records,
        // so it is all nulls until the first month has been recorded.
        final s = mapOf(d['summary']);
        String count(String key) => formatValue(numOf(s[key]) ?? 0);
        return AsyncContent(
          data: data,
          onRetry: () => reloadAdmin(context, AdminResource.complianceDashboard),
          builder: (_) => Column(
            children: [
              StatGrid(stats: [
                StatCardData(label: 'Agreements', value: count('total_agreements'), icon: Icons.handshake_outlined),
                StatCardData(label: 'Active', value: count('active_agreements'), icon: Icons.check_circle_outline),
                StatCardData(label: 'Suspended', value: count('suspended_agreements'), icon: Icons.pause_circle_outline),
                StatCardData(label: 'Avg Score', value: percent(s['avg_compliance_score']), icon: Icons.speed_outlined),
              ]),
              const SizedBox(height: 14),
              StatGrid(perRow: 3, stats: [
                StatCardData(label: 'Excellent (90+)', value: count('excellent_count'), icon: Icons.emoji_events_outlined),
                StatCardData(label: 'Good (80–89)', value: count('good_count'), icon: Icons.thumb_up_alt_outlined),
                StatCardData(label: 'Poor (below 80)', value: count('poor_count'), icon: Icons.warning_amber_outlined),
              ]),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, c) {
                final top = SectionCard(
                  title: 'Top Performers',
                  child: RecordTable(rows: recordsOf(d['topPerformers']), emptyMessage: 'No performance data yet.'),
                );
                final low = SectionCard(
                  title: 'Needs Attention',
                  child: RecordTable(rows: recordsOf(d['lowPerformers']), emptyMessage: 'No performance data yet.'),
                );
                if (c.maxWidth < 1000) return Column(children: [top, const SizedBox(height: 18), low]);
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: top),
                  const SizedBox(width: 18),
                  Expanded(child: low),
                ]);
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PharmacyLookup extends StatefulWidget {
  const _PharmacyLookup();

  @override
  State<_PharmacyLookup> createState() => _PharmacyLookupState();
}

class _PharmacyLookupState extends State<_PharmacyLookup> {
  String? _pharmacyId;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Pharmacy Compliance',
      subtitle: 'Overall score across a pharmacy\'s agreements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 420,
            child: AdminResourceBuilder(
              resource: AdminResource.pharmacies,
              load: pharmacyListParams,
              builder: (context, data) => AdminDropdown<String>(
                value: _pharmacyId,
                hint: data.hasData ? 'Choose a pharmacy' : 'Loading pharmacies…',
                items: [
                  for (final p in recordsOf(data.data, ['pharmacies']))
                    ('${p['id']}', '${p['pharmacy_name'] ?? 'Pharmacy #${p['id']}'}'),
                ],
                onChanged: (v) {
                  setState(() => _pharmacyId = v);
                  if (v != null) {
                    loadAdmin(context, AdminResource.pharmacyCompliance, params: {'pharmacy_id': v});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          AdminResourceBuilder(
            resource: AdminResource.pharmacyCompliance,
            builder: (context, data) => AsyncContent(
              data: data,
              idleMessage: 'Choose a pharmacy to see its compliance.',
              onRetry: () => reloadAdmin(context, AdminResource.pharmacyCompliance),
              builder: (raw) {
                final c = mapOf(raw);
                final status = c['status']?.toString();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (status != null) StatusBadge(status: humanize(status)),
                    const SizedBox(height: 12),
                    KeyValueGrid(
                      values: c,
                      exclude: const {'status', 'pharmacyId'},
                      formatters: const {'overallCompliance': percent},
                    ),
                    if (recordsOf(c['agreements']).isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const SubHeading('By Agreement'),
                      RecordTable(rows: recordsOf(c['agreements'])),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Report extends StatefulWidget {
  const _Report();

  @override
  State<_Report> createState() => _ReportState();
}

class _ReportState extends State<_Report> {
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month - 3, 1);
  DateTime _end = DateTime.now();
  String? _error;

  void _run() {
    if (_end.isBefore(_start)) {
      setState(() => _error = 'The end date must be on or after the start date.');
      return;
    }
    setState(() => _error = null);
    loadAdmin(context, AdminResource.complianceReport,
        params: {'start_date': apiDate(_start), 'end_date': apiDate(_end)}, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Compliance Report',
      subtitle: 'Monthly compliance records between two dates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 200,
                child: LabeledField(
                    label: 'From',
                    child: AdminDateInput(value: _start, onChanged: (d) => setState(() => _start = d ?? _start))),
              ),
              SizedBox(
                width: 200,
                child: LabeledField(
                    label: 'To',
                    child: AdminDateInput(value: _end, onChanged: (d) => setState(() => _end = d ?? _end))),
              ),
              PrimaryButton(label: 'Run Report', icon: Icons.play_arrow_rounded, onPressed: _run),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorPanel(message: _error!, compact: true),
          ],
          const SizedBox(height: 16),
          AdminResourceBuilder(
            resource: AdminResource.complianceReport,
            builder: (context, data) => AsyncContent(
              data: data,
              idleMessage: 'Pick a date range and run the report.',
              onRetry: () => reloadAdmin(context, AdminResource.complianceReport),
              builder: (raw) => RecordTable(
                rows: recordsOf(raw),
                maxAutoColumns: 10,
                emptyMessage: 'No compliance records in this period.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
