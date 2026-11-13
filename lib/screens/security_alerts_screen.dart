import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

enum _Tab { alerts, suspicious, report }

const _alertTypes = [
  'IMPOSSIBLE_TRAVEL', 'NEW_LOCATION', 'NEW_DEVICE', 'PATTERN_ANOMALY',
  'UNUSUAL_COUNTRY_PATTERN', 'TIMEZONE_ANOMALY', 'PASSWORD_CHANGED',
  'MULTIPLE_FAILURES', 'ACCOUNT_LOCKOUT',
];

const _severityColors = <String, Color>{
  'CRITICAL': AppColors.danger,
  'HIGH': Color(0xFFE0577B),
  'MEDIUM': Color(0xFFE0A83C),
  'LOW': Color(0xFF2F80ED),
};

Widget severityBadge(dynamic s) => statusBadge(s, color: _severityColors['$s']);

/// Security alerts raised by the sign-in monitor, from
/// `/admin/security/alerts*`: review them one at a time or in bulk, find
/// accounts under repeated attack, and chart alerts by day.
class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  _Tab _tab = _Tab.alerts;
  bool _week = false;

  /// Unreviewed first: that is the work waiting.
  Map<String, dynamic> _filters = const {'status': 'unreviewed'};
  final Set<int> _selected = {};

  /// `user_id` only means something with `user_type` (a patient and a
  /// doctor can share an id), so it is held back until both are set.
  Map<String, dynamic> get _effectiveFilters =>
      _filters.containsKey('user_id') && !_filters.containsKey('user_type')
          ? ({..._filters}..remove('user_id'))
          : _filters;

  void _setFilters(Map<String, dynamic> next) => setState(() {
        _filters = next;
        _selected.clear();
      });

  void _refresh() {
    reloadAdmin(context, AdminResource.securityAlertStats);
    reloadAdmin(context, switch (_tab) {
      _Tab.alerts => AdminResource.securityAlerts,
      _Tab.suspicious => AdminResource.suspiciousUsers,
      _Tab.report => AdminResource.securityReport,
    });
  }

  /// From a suspicious account to its alerts.
  void _drillInto(Map<String, dynamic> user) => setState(() {
        _tab = _Tab.alerts;
        _filters = {'user_type': user['user_type'], 'user_id': user['user_id']};
        _selected.clear();
      });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Security Alerts',
      body: PinnedPage(
        header: [
          ScreenTitle(
            title: 'Security Alerts',
            subtitle: 'Unusual sign-ins flagged for review, most severe first',
            actions: [SecondaryButton(label: 'Refresh', icon: Icons.refresh, onPressed: _refresh)],
          ),
          const SizedBox(height: 18),
          _StatsHeader(
            week: _week,
            onWindow: (w) => setState(() => _week = w),
            onShowUnreviewed: () => _setFilters({'status': 'unreviewed'}),
          ),
          const SizedBox(height: 18),
          FilterPills<_Tab>(
            options: const [
              (_Tab.alerts, 'Alerts'),
              (_Tab.suspicious, 'Suspicious accounts'),
              (_Tab.report, 'Daily report'),
            ],
            selected: _tab,
            onSelected: (t) => setState(() => _tab = t),
          ),
          const SizedBox(height: 18),
        ],
        body: (pinned) => switch (_tab) {
          _Tab.alerts => _alertsTab(pinned),
          _Tab.suspicious => _SuspiciousTab(onOpen: _drillInto, pinned: pinned),
          // Chart and summary: they scroll together under the header.
          _Tab.report => pinned
              ? const SingleChildScrollView(child: _ReportTab())
              : const _ReportTab(),
        },
      ),
    );
  }

  Widget _alertsTab(bool pinned) {
    final heldBack = !identical(_effectiveFilters, _filters);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RecordFilterBar(
            values: _filters,
            onChanged: _setFilters,
            filters: [
              ChoiceFilter.values('status', 'Status', const ['unreviewed', 'verified_legit', 'verified_threat', 'dismissed']),
              ChoiceFilter('severity', 'Severity', [for (final s in _severityColors.keys) (s, humanize(s.toLowerCase()))], width: 130),
              ChoiceFilter('alert_type', 'Type', [for (final t in _alertTypes) (t, humanize(t.toLowerCase()))], width: 210),
              ChoiceFilter.values('user_type', 'Account type', const ['patient', 'doctor', 'pharmacy', 'admin'], width: 140),
              const IdFilter('user_id', 'User ID'),
              const ChoiceFilter('hours', 'Raised in', [
                ('24', 'Last 24 hours'), ('72', 'Last 3 days'), ('168', 'Last 7 days'), ('720', 'Last 30 days'),
              ], width: 150),
            ],
          ),
          if (heldBack) ...[
            const SizedBox(height: 10),
            const Text('Choose an account type to filter by user ID: patients, doctors and pharmacies can share an id.',
                style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ],
        ]),
      ),
      const SizedBox(height: 18),
      pinned ? Expanded(child: _alertList(pinned)) : _alertList(pinned),
    ]);
  }

  Widget _alertList(bool pinned) => PagedRecordList(
        expand: pinned,
        resource: AdminResource.securityAlerts,
        listKey: 'alerts',
        noun: 'alerts',
        filters: _effectiveFilters,
        onRowTap: (r) => showAlertDetail(context, r),
        header: (_, rows) => _BulkBar(
          selected: _selected,
          pageIds: [for (final r in rows) if (numOf(r['id']) != null) numOf(r['id'])!.toInt()],
          onSelectPage: (ids) => setState(() => _selected.addAll(ids)),
          onClear: () => setState(_selected.clear),
          onDone: () => setState(_selected.clear),
        ),
        columns: [
          RecordColumn('', width: 44, cell: (r) {
            final id = numOf(r['id'])?.toInt();
            return Checkbox(
              value: id != null && _selected.contains(id),
              activeColor: AppColors.primary,
              onChanged: id == null
                  ? null
                  : (v) => setState(() => v == true ? _selected.add(id) : _selected.remove(id)),
            );
          }),
          RecordColumn('Severity', width: 110, cell: (r) => severityBadge(r['severity'])),
          RecordColumn('Alert', width: 300,
              cell: (r) => CellText(humanize('${r['alert_type'] ?? ''}'.toLowerCase()),
                  strong: true, subtitle: r['alert_message']?.toString())),
          RecordColumn('Account', width: 220,
              cell: (r) => CellText(formatValue(r['email']),
                  subtitle: '${humanize('${r['user_type'] ?? ''}')} #${r['user_id'] ?? '—'}')),
          RecordColumn('Risk', width: 70, cell: (r) => CellText(formatValue(r['risk_score']), strong: true)),
          const RecordColumn('Status', field: 'status', width: 140),
          RecordColumn('Owner said', width: 120,
              cell: (r) => CellText(r['user_response'] == null ? '—' : humanize('${r['user_response']}'))),
          RecordColumn('Raised', width: 160, cell: (r) => dateCell(r['created_at'])),
        ],
      );
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final bool week;
  final ValueChanged<bool> onWindow;
  final VoidCallback onShowUnreviewed;

  const _StatsHeader({required this.week, required this.onWindow, required this.onShowUnreviewed});

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.securityAlertStats,
      load: const {},
      builder: (context, data) => AsyncContent(
        data: data,
        onRetry: () => reloadAdmin(context, AdminResource.securityAlertStats),
        builder: (raw) {
          final stats = mapOf(raw);
          final w = mapOf(stats[week ? 'last_7_days' : 'last_24_hours']);
          final waiting = numOf(stats['unreviewed_critical_or_high']) ?? 0;
          String n(String k) => formatNumber(numOf(w[k]) ?? 0);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (waiting > 0) ...[
              Material(
                color: AppColors.alertBackground,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onShowUnreviewed,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.alertIcon),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${formatNumber(waiting)} critical or high alerts are waiting for review (all time).',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            FilterPills<bool>(
              options: const [(false, 'Last 24 hours'), (true, 'Last 7 days')],
              selected: week,
              onSelected: onWindow,
            ),
            const SizedBox(height: 14),
            StatGrid(perRow: 5, stats: [
              StatCardData(label: 'Alerts', value: n('total'), icon: Icons.notifications_none),
              StatCardData(label: 'Unreviewed', value: n('unreviewed'), icon: Icons.pending_actions_outlined),
              StatCardData(label: 'Critical', value: n('critical'), icon: Icons.gpp_maybe_outlined),
              StatCardData(label: 'High', value: n('high'), icon: Icons.priority_high),
              StatCardData(label: 'Accounts affected', value: n('affected_users'), icon: Icons.people_outline),
            ]),
          ]);
        },
      ),
    );
  }
}

// ─── Review ───────────────────────────────────────────────────────────────────

const _reviewLabels = {
  'verified_legit': 'Legitimate (it was the owner)',
  'verified_threat': 'Threat (sign the account out)',
  'dismissed': 'Dismiss',
};

/// `verified_threat` signs the account out of every device and emails its
/// owner; the admin confirms that knowingly.
Future<bool> _confirmThreat(BuildContext context, {bool bulk = false}) => confirmAdmin(
      context,
      title: 'Mark as a threat?',
      message: !bulk
          ? 'This signs the account out of every device and emails its owner.'
          : 'This signs each affected account out of every device and emails each owner once.',
      confirmLabel: 'Mark as threat',
      destructive: true,
    );

Future<void> showAlertDetail(BuildContext context, Map<String, dynamic> alert) =>
    showAdminDetail(context, (_) => _AlertDialog(alert: alert));

class _AlertDialog extends StatefulWidget {
  final Map<String, dynamic> alert;
  const _AlertDialog({required this.alert});

  @override
  State<_AlertDialog> createState() => _AlertDialogState();
}

class _AlertDialogState extends State<_AlertDialog> {
  late String? _status =
      ReviewSecurityAlertAction.statuses.contains(widget.alert['status']) ? '${widget.alert['status']}' : null;
  final _notes = TextEditingController();
  final _action = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    _action.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final status = _status;
    if (status == null) return;
    if (status == 'verified_threat' && !await _confirmThreat(context)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final result = await runAdminMutation(
      context,
      (c) => ReviewSecurityAlertAction(widget.alert['id'],
          status: status, adminNotes: _notes.text.trim(), actionTaken: _action.text.trim(), completer: c),
      successFrom: (data) {
        final revoked = numOf(mapOf(data)['sessions_revoked']) ?? 0;
        return revoked > 0
            ? 'Alert reviewed. ${formatNumber(revoked)} sessions signed out.'
            : 'Alert reviewed.';
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) closeAdminDetail(context);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final reviewed = a['status'] != 'unreviewed';
    return AdminDialog(
      title: humanize('${a['alert_type'] ?? 'Alert'}'.toLowerCase()),
      subtitle: '#${a['id']} · ${a['email'] ?? '—'} · ${humanize('${a['user_type'] ?? ''}')} #${a['user_id'] ?? '—'}',
      width: 820,
      actions: [
        SecondaryButton(label: 'Close', onPressed: () => closeAdminDetail(context)),
        PrimaryButton(
          label: reviewed ? 'Update review' : 'Save review',
          busy: _busy,
          color: _status == 'verified_threat' ? AppColors.danger : AppColors.primary,
          onPressed: _status == null ? null : _submit,
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if ('${a['alert_message'] ?? ''}'.isNotEmpty) ...[
          PlainTextBlock('${a['alert_message']}'),
          const SizedBox(height: 16),
        ],
        FactGrid([
          ('Severity', severityBadge(a['severity'])),
          FactGrid.text('Risk score', a['risk_score']),
          ('Status', statusBadge(a['status'])),
          FactGrid.text('Raised', formatDate(a['created_at'], withTime: true)),
          FactGrid.text('IP address', a['ip_address']),
          FactGrid.text('Owner emailed', a['email_sent']),
          FactGrid.text('Owner said', a['user_response'] == null
              ? 'No answer'
              : '${humanize('${a['user_response']}')}, ${formatDate(a['user_response_at'], withTime: true)}'),
          if (a['requires_user_verification'] == true)
            FactGrid.text('Owner verified', formatDate(a['verified_at'], withTime: true)),
          if (reviewed) ...[
            FactGrid.text('Reviewed', formatDate(a['admin_action_at'], withTime: true)),
            FactGrid.text('Action taken', a['action_taken']),
          ],
        ]),
        if (reviewed && '${a['admin_notes'] ?? ''}'.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          const SubHeading('Review notes'),
          PlainTextBlock('${a['admin_notes']}'),
        ],
        for (final (title, key) in const [('Location', 'location_data'), ('Device', 'device_data')])
          if (mapOf(a[key]).isNotEmpty) ...[
            const SizedBox(height: 16),
            SubHeading(title),
            KeyValueGrid(values: mapOf(a[key])),
          ],
        const SizedBox(height: 20),
        SubHeading(reviewed ? 'Change the review' : 'Review'),
        FormGrid(children: [
          LabeledField(
            label: 'Outcome',
            required: true,
            child: AdminDropdown<String>(
              value: _status,
              hint: 'Choose an outcome',
              items: [for (final s in ReviewSecurityAlertAction.statuses) (s, _reviewLabels[s]!)],
              onChanged: (v) => setState(() => _status = v),
            ),
          ),
          LabeledField(
            label: 'Action taken',
            child: AdminTextInput(controller: _action, hint: 'e.g. Sessions revoked'),
          ),
        ]),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Notes',
          child: AdminTextInput(controller: _notes, maxLines: 3, hint: 'e.g. Confirmed with the user by phone'),
        ),
        if (_status == 'verified_threat') ...[
          const SizedBox(height: 12),
          const ErrorPanel(
            message: 'Marking this a threat signs the account out of every device and emails its owner.',
            compact: true,
          ),
        ],
      ]),
    );
  }
}

class _BulkBar extends StatelessWidget {
  final Set<int> selected;
  final List<int> pageIds;
  final ValueChanged<List<int>> onSelectPage;
  final VoidCallback onClear;
  final VoidCallback onDone;

  const _BulkBar({
    required this.selected,
    required this.pageIds,
    required this.onSelectPage,
    required this.onClear,
    required this.onDone,
  });

  Future<void> _review(BuildContext context, String status) async {
    final ids = selected.take(BulkReviewSecurityAlertsAction.maxIds).toList();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _BulkReasonDialog(count: ids.length, status: status),
    );
    if (reason == null || !context.mounted) return;
    if (status == 'verified_threat' && !await _confirmThreat(context, bulk: true)) return;
    if (!context.mounted) return;
    final result = await runAdminMutation(
      context,
      (c) => BulkReviewSecurityAlertsAction(ids, status: status, actionReason: reason, completer: c),
      successFrom: (data) {
        final d = mapOf(data);
        final notFound = (d['not_found'] is List) ? (d['not_found'] as List).length : 0;
        final revoked = numOf(d['sessions_revoked']) ?? 0;
        return [
          'Updated ${formatNumber(numOf(d['updated_count']) ?? 0)} alerts.',
          if (notFound > 0) '$notFound no longer exist.',
          if (revoked > 0) '${formatNumber(revoked)} sessions signed out.',
        ].join(' ');
      },
    );
    // The middleware refetches the list, stats and report after the write.
    if (result.ok) onDone();
  }

  @override
  Widget build(BuildContext context) {
    final allOnPage = pageIds.isNotEmpty && pageIds.every(selected.contains);
    return Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text(selected.isEmpty ? 'Select alerts to review several at once.' : '${selected.length} selected',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      if (!allOnPage && pageIds.isNotEmpty)
        TextButton(onPressed: () => onSelectPage(pageIds), child: const Text('Select this page')),
      if (selected.isNotEmpty) ...[
        TextButton(onPressed: onClear, child: const Text('Clear')),
        SecondaryButton(label: 'Dismiss', icon: Icons.do_not_disturb_on_outlined,
            onPressed: () => _review(context, 'dismissed')),
        SecondaryButton(label: 'Legitimate', icon: Icons.verified_user_outlined,
            onPressed: () => _review(context, 'verified_legit')),
        PrimaryButton(label: 'Threat', icon: Icons.gpp_bad_outlined, color: AppColors.danger,
            onPressed: () => _review(context, 'verified_threat')),
      ],
    ]);
  }
}

class _BulkReasonDialog extends StatefulWidget {
  final int count;
  final String status;
  const _BulkReasonDialog({required this.count, required this.status});

  @override
  State<_BulkReasonDialog> createState() => _BulkReasonDialogState();
}

class _BulkReasonDialogState extends State<_BulkReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminDialog(
      title: 'Review ${widget.count} alerts as “${_reviewLabels[widget.status]}”',
      width: 520,
      actions: [
        SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        PrimaryButton(
          label: 'Continue',
          color: widget.status == 'verified_threat' ? AppColors.danger : AppColors.primary,
          onPressed: () => Navigator.pop(context, _reason.text.trim()),
        ),
      ],
      child: LabeledField(
        label: 'Reason (optional)',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AppColors.contentBackground, borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: _reason,
            autofocus: true,
            inputFormatters: [LengthLimitingTextInputFormatter(500)],
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'e.g. Known VPN',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Suspicious accounts ──────────────────────────────────────────────────────

class _SuspiciousTab extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onOpen;
  final bool pinned;
  const _SuspiciousTab({required this.onOpen, this.pinned = false});

  @override
  State<_SuspiciousTab> createState() => _SuspiciousTabState();
}

class _SuspiciousTabState extends State<_SuspiciousTab> {
  int _hours = 24;
  int _threshold = 3;

  Map<String, dynamic> get _params => {'hours': _hours, 'threshold': _threshold};

  void _set({int? hours, int? threshold}) {
    setState(() {
      _hours = hours ?? _hours;
      _threshold = threshold ?? _threshold;
    });
    loadAdmin(context, AdminResource.suspiciousUsers, params: _params);
  }

  @override
  Widget build(BuildContext context) {
    final pinned = widget.pinned;
    final table = AdminResourceBuilder(
        resource: AdminResource.suspiciousUsers,
        load: _params,
        builder: (context, data) {
          final card = TableCard(
            pinned: pinned,
            data: data,
            title: 'Suspicious accounts',
            subtitle: 'Accounts with at least $_threshold unreviewed critical alerts in this window. '
                'Click one to see its alerts.',
            onRetry: () => reloadAdmin(context, AdminResource.suspiciousUsers),
            builder: (raw) => RecordTable(
              rows: recordsOf(raw, ['users']),
              stickyHeader: pinned,
              emptyMessage: 'No account has that many unreviewed critical alerts in this window.',
              onRowTap: widget.onOpen,
              columns: [
                RecordColumn('Account', width: 240,
                    cell: (r) => CellText(formatValue(r['email']),
                        strong: true, subtitle: '${humanize('${r['user_type'] ?? ''}')} #${r['user_id']}')),
                const RecordColumn('Alerts', field: 'alert_count', width: 80),
                const RecordColumn('Critical', field: 'critical_count', width: 80),
                RecordColumn('Avg risk', width: 90,
                    cell: (r) => CellText(formatNumber(numOf(r['avg_risk_score']) ?? 0, decimals: 0))),
                RecordColumn('Types', width: 300,
                    cell: (r) => CellText((r['alert_types'] is List)
                        ? (r['alert_types'] as List).map((t) => humanize('$t'.toLowerCase())).join(', ')
                        : '—')),
                RecordColumn('Latest', width: 160, cell: (r) => dateCell(r['latest_alert'])),
              ],
            ),
          );
          // TableCard expands itself when pinned; it needs a Column parent.
          return pinned ? Column(children: [card]) : card;
        },
      );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionCard(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 20, runSpacing: 12, children: [
          LabeledField(
            label: 'Window',
            child: FilterPills<int>(
              options: const [(24, '24 hours'), (72, '3 days'), (168, '7 days'), (720, '30 days')],
              selected: _hours,
              onSelected: (v) => _set(hours: v),
            ),
          ),
          LabeledField(
            label: 'At least',
            child: FilterPills<int>(
              options: const [(1, '1 alert'), (3, '3 alerts'), (5, '5 alerts'), (10, '10 alerts')],
              selected: _threshold,
              onSelected: (v) => _set(threshold: v),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 18),
      if (pinned) Expanded(child: table) else table,
    ]);
  }
}

// ─── Daily report ─────────────────────────────────────────────────────────────

class _ReportTab extends StatefulWidget {
  const _ReportTab();

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  /// Empty means the server's default: the last 30 days.
  Map<String, dynamic> _range = const {};

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Alerts by day',
      subtitle: 'Without dates, the last 30 days',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RecordFilterBar(
          filters: const [DateRangeFilter('Period')],
          values: _range,
          onChanged: (v) {
            setState(() => _range = v);
            loadAdmin(context, AdminResource.securityReport, params: v);
          },
        ),
        const SizedBox(height: 16),
        AdminResourceBuilder(
          resource: AdminResource.securityReport,
          load: _range,
          builder: (context, data) => AsyncContent(
            data: data,
            onRetry: () => reloadAdmin(context, AdminResource.securityReport),
            builder: (raw) => _Report(data: mapOf(raw)),
          ),
        ),
      ]),
    );
  }
}

class _Report extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Report({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = recordsOf(data['report']);
    final period = mapOf(data['period']);
    final days = dailyAlertTotals(rows, from: '${period['from'] ?? ''}', to: '${period['to'] ?? ''}');

    // By type and severity across the period.
    final byKind = <(String, String), (num, num)>{};
    for (final r in rows) {
      final k = ('${r['alert_type']}', '${r['severity']}');
      final prev = byKind[k] ?? (0, 0);
      byKind[k] = (prev.$1 + (numOf(r['count']) ?? 0), prev.$2 + (numOf(r['confirmed_threats']) ?? 0));
    }
    final kinds = byKind.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1));
    final total = days.fold<num>(0, (s, d) => s + d.$2);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${formatDate(period['from'])} – ${formatDate(period['to'])} · ${formatNumber(total)} alerts',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      const SizedBox(height: 14),
      if (days.isNotEmpty) SizedBox(height: 220, child: _DailyChart(days: days)),
      const SizedBox(height: 18),
      RecordTable(
        rows: [
          for (final e in kinds)
            {'alert_type': e.key.$1, 'severity': e.key.$2, 'count': e.value.$1, 'confirmed_threats': e.value.$2},
        ],
        emptyMessage: 'No alerts in this period.',
        columns: [
          RecordColumn('Type', width: 240, cell: (r) => CellText(humanize('${r['alert_type']}'.toLowerCase()), strong: true)),
          RecordColumn('Severity', width: 120, cell: (r) => severityBadge(r['severity'])),
          const RecordColumn('Alerts', field: 'count', width: 100),
          const RecordColumn('Confirmed threats', field: 'confirmed_threats', width: 150),
        ],
      ),
    ]);
  }
}

/// One `(yyyy-MM-dd, count)` per day from [from] to [to], both included.
/// The report has no row for a day without alerts; those days count 0.
List<(String, num)> dailyAlertTotals(List<Map<String, dynamic>> rows, {required String from, required String to}) {
  final totals = <String, num>{};
  for (final r in rows) {
    final day = '${r['date'] ?? ''}';
    if (day.length < 10) continue;
    totals[day.substring(0, 10)] = (totals[day.substring(0, 10)] ?? 0) + (numOf(r['count']) ?? 0);
  }
  final start = DateTime.tryParse(from.length >= 10 ? '${from.substring(0, 10)}T00:00:00Z' : '');
  final end = DateTime.tryParse(to.length >= 10 ? '${to.substring(0, 10)}T00:00:00Z' : '');
  if (start == null || end == null || end.isBefore(start)) {
    final keys = totals.keys.toList()..sort();
    return [for (final k in keys) (k, totals[k]!)];
  }
  return [
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1)))
      (apiDate(d), totals[apiDate(d)] ?? 0),
  ];
}

class _DailyChart extends StatelessWidget {
  final List<(String, num)> days;
  const _DailyChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final maxY = days.fold<num>(0, (m, d) => d.$2 > m ? d.$2 : m).toDouble();
    final every = (days.length / 8).ceil().clamp(1, 1000);
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        alignment: BarChartAlignment.spaceBetween,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${formatDate(days[group.x].$1)}\n${formatNumber(rod.toY)} alerts',
              const TextStyle(color: Colors.white, fontSize: 11.5),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => value != value.roundToDouble()
                  ? const SizedBox.shrink()
                  : Text(formatNumber(value), style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length || i % every != 0) return const SizedBox.shrink();
                final d = DateTime.parse(days[i].$1);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: days[i].$2.toDouble(),
                width: days.length > 40 ? 4 : 10,
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ]),
        ],
      ),
    );
  }
}
