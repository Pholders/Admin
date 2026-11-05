import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

const _statuses = [
  ('pending', 'Pending'),
  ('active', 'Active'),
  ('suspended', 'Suspended'),
  ('expired', 'Expired'),
  ('terminated', 'Terminated'),
];
const _entityTypes = [('pharmacy', 'Pharmacy'), ('group', 'Group')];

/// Partnership agreements: list, expiring soon, create, edit, activate and
/// suspend.
class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({super.key});

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  bool _expiringOnly = false;
  int _expiringDays = 30;
  String? _status;
  String? _entityType;
  String _query = '';

  AdminResource get _resource =>
      _expiringOnly ? AdminResource.expiringAgreements : AdminResource.agreements;

  /// The expiring endpoint takes only `days`; status and party filters are
  /// applied client-side in that view.
  Map<String, dynamic> get _params => _expiringOnly
      ? {'days': _expiringDays}
      : {
          if (_status != null) 'status': _status,
          if (_entityType != null) 'entity_type': _entityType,
        };

  void _reload() => loadAdmin(context, _resource, params: _params);

  List<Map<String, dynamic>> _visible(List<Map<String, dynamic>> rows, _PartyNames names) {
    Iterable<Map<String, dynamic>> list = rows;
    if (_expiringOnly) {
      if (_status != null) list = list.where((r) => r['status'] == _status);
      if (_entityType != null) list = list.where((r) => r['entity_type'] == _entityType);
    }
    final q = _query.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) => [
            '#${r['id']}',
            r['agreement_type'],
            r['payment_terms'],
            names.of(r),
          ].any((v) => v != null && v.toString().toLowerCase().contains(q)));
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Agreements',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Agreements',
              subtitle: 'Partnership agreements with pharmacies and groups',
              searchHint: 'Search agreements',
              onSearchChanged: (v) => setState(() => _query = v.trim()),
              actionLabel: 'New Agreement',
              onActionTap: () =>
                  showDialog(context: context, builder: (_) => const AgreementFormDialog()),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                FilterPills<bool>(
                  options: const [(false, 'All agreements'), (true, 'Expiring soon')],
                  selected: _expiringOnly,
                  onSelected: (v) {
                    setState(() => _expiringOnly = v);
                    _reload();
                  },
                ),
                if (_expiringOnly)
                  FilterPills<int>(
                    options: const [(30, '30 days'), (60, '60 days'), (90, '90 days')],
                    selected: _expiringDays,
                    onSelected: (v) {
                      setState(() => _expiringDays = v);
                      _reload();
                    },
                  ),
                FilterPills<String?>(
                  options: const [(null, 'Any status'), ..._statuses],
                  selected: _status,
                  onSelected: (v) {
                    setState(() => _status = v);
                    _reload();
                  },
                ),
                FilterPills<String?>(
                  options: const [(null, 'Pharmacies & groups'), ..._entityTypes],
                  selected: _entityType,
                  onSelected: (v) {
                    setState(() => _entityType = v);
                    _reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            _PartyNamesBuilder(
              builder: (names) => AdminResourceBuilder(
                // Keyed so switching views re-runs the initial load.
                key: ValueKey(_resource),
                resource: _resource,
                load: _params,
                builder: (context, data) {
                  final all = recordsOf(data.data);
                  final rows = _visible(all, names);
                  return Column(
                    children: [
                      if (data.hasData) ...[
                        _AgreementStats(rows: all),
                        const SizedBox(height: 18),
                      ],
                      SectionCard(
                        child: AsyncContent(
                          data: data,
                          onRetry: () => reloadAdmin(context, _resource),
                          builder: (_) => _AgreementsTable(rows: rows, names: names),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementStats extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _AgreementStats({required this.rows});

  @override
  Widget build(BuildContext context) {
    int count(String status) => rows.where((r) => r['status'] == status).length;
    return StatGrid(stats: [
      StatCardData(label: 'Agreements', value: '${rows.length}', icon: Icons.handshake_outlined),
      StatCardData(label: 'Active', value: '${count('active')}', icon: Icons.check_circle_outline),
      StatCardData(label: 'Pending', value: '${count('pending')}', icon: Icons.hourglass_empty),
      StatCardData(label: 'Suspended', value: '${count('suspended')}', icon: Icons.pause_circle_outline),
    ]);
  }
}

/// Names for agreement parties. The list endpoints return only
/// `pharmacy_or_group_id`, so names come from the pharmacy and group lists.
class _PartyNames {
  final Map<String, String> pharmacies;
  final Map<String, String> groups;
  const _PartyNames(this.pharmacies, this.groups);

  String of(Map<String, dynamic> agreement) {
    final id = '${agreement['pharmacy_or_group_id']}';
    final isGroup = agreement['entity_type'] == 'group';
    return (isGroup ? groups[id] : pharmacies[id]) ??
        (agreement['entity_name']?.toString() ?? '${isGroup ? 'Group' : 'Pharmacy'} #$id');
  }
}

class _PartyNamesBuilder extends StatelessWidget {
  final Widget Function(_PartyNames names) builder;
  const _PartyNamesBuilder({required this.builder});

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.pharmacies,
      load: pharmacyListParams,
      builder: (context, pharmacies) => AdminResourceBuilder(
        resource: AdminResource.groups,
        load: const {'is_active': true},
        builder: (context, groups) => builder(_PartyNames(
          {
            for (final p in recordsOf(pharmacies.data, ['pharmacies']))
              '${p['id']}': '${p['pharmacy_name'] ?? 'Pharmacy #${p['id']}'}',
          },
          {
            for (final g in recordsOf(groups.data))
              '${g['id']}': '${g['group_name'] ?? 'Group #${g['id']}'}',
          },
        )),
      ),
    );
  }
}

class _AgreementsTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final _PartyNames names;
  const _AgreementsTable({required this.rows, required this.names});

  @override
  Widget build(BuildContext context) {
    return RecordTable(
      rows: rows,
      emptyMessage: 'No agreements match these filters.',
      onRowTap: (r) => showAgreementDetail(context, r['id']),
      columns: [
        RecordColumn('Agreement',
            width: 120,
            cell: (r) => CellText('#${r['id']}',
                strong: true, subtitle: r['agreement_type']?.toString())),
        RecordColumn('Party',
            width: 220,
            cell: (r) => CellText(names.of(r), subtitle: humanize('${r['entity_type'] ?? ''}'))),
        RecordColumn('Commission', width: 110, cell: (r) => CellText(percent(r['commission_rate']))),
        const RecordColumn('Service Fee', field: 'service_fee', width: 100),
        const RecordColumn('Starts', field: 'start_date', width: 120),
        const RecordColumn('Ends', field: 'end_date', width: 120),
        const RecordColumn('Auto-renew', field: 'auto_renew', width: 100),
        const RecordColumn('Status', field: 'status', width: 110),
      ],
      actionsWidth: 110,
      actions: (row) => _AgreementActions(agreement: row),
    );
  }
}

class _AgreementActions extends StatelessWidget {
  final Map<String, dynamic> agreement;
  const _AgreementActions({required this.agreement});

  @override
  Widget build(BuildContext context) {
    final id = agreement['id'];
    final status = agreement['status']?.toString();
    return PendingBuilder(
      mutationKey: 'agreement.$id.status',
      builder: (context, busy) => Row(children: [
        RowIconButton(
            icon: Icons.visibility_outlined,
            tooltip: 'View agreement',
            onPressed: () => showAgreementDetail(context, id)),
        RowIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit terms',
            onPressed: () => showDialog(
                context: context, builder: (_) => AgreementEditDialog(agreement: agreement))),
        if (status == 'active')
          RowIconButton(
              icon: Icons.pause_circle_outline,
              tooltip: 'Suspend',
              color: AppColors.danger,
              onPressed: busy ? null : () => setAgreementActive(context, agreement, false))
        else if (status == 'pending' || status == 'suspended')
          RowIconButton(
              icon: Icons.play_circle_outline,
              tooltip: 'Activate',
              color: AppColors.primaryDark,
              onPressed: busy ? null : () => setAgreementActive(context, agreement, true)),
      ]),
    );
  }
}

Future<void> setAgreementActive(
    BuildContext context, Map<String, dynamic> agreement, bool activate) async {
  final id = agreement['id'];
  final ok = await confirmAdmin(
    context,
    title: activate ? 'Activate agreement #$id?' : 'Suspend agreement #$id?',
    message: activate
        ? 'The agreement\'s terms start applying to claim routing and compliance.'
        : 'The agreement stops applying until it is activated again.',
    confirmLabel: activate ? 'Activate' : 'Suspend',
    destructive: !activate,
  );
  if (!ok || !context.mounted) return;
  await runAdminMutation(
    context,
    (c) => activate
        ? ActivateAgreementAction(id, completer: c)
        : SuspendAgreementAction(id, completer: c),
    success: activate ? 'Agreement #$id activated' : 'Agreement #$id suspended',
  );
}

// ─── Create ───────────────────────────────────────────────────────────────────

class AgreementFormDialog extends StatefulWidget {
  const AgreementFormDialog({super.key});

  @override
  State<AgreementFormDialog> createState() => _AgreementFormDialogState();
}

class _AgreementFormDialogState extends State<AgreementFormDialog> {
  String _entityType = 'pharmacy';
  String? _partyId;
  DateTime? _start = DateTime.now();
  DateTime? _end;
  bool _autoRenew = false;
  final _type = TextEditingController();
  final _commission = TextEditingController();
  final _fee = TextEditingController();
  final _minTx = TextEditingController();
  final _claimHours = TextEditingController(text: '24');
  final _dispenseHours = TextEditingController(text: '48');
  final _paymentTerms = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_type, _commission, _fee, _minTx, _claimHours, _dispenseHours, _paymentTerms]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final commission = num.tryParse(_commission.text.trim());
    String? problem;
    if (_partyId == null) problem = 'Choose the ${_entityType == 'group' ? 'group' : 'pharmacy'}.';
    if (problem == null && _start == null) problem = 'Start date is required.';
    if (problem == null && (commission == null || commission <= 0 || commission > 100)) {
      problem = 'Commission rate is required: a number above 0 and at most 100.';
    }
    if (problem == null && _end != null && !_end!.isAfter(_start!)) {
      problem = 'End date must be after the start date.';
    }
    final numbers = <String, num?>{};
    for (final (key, controller) in [
      ('service_fee', _fee),
      ('minimum_monthly_transactions', _minTx),
      ('claim_response_time_hours', _claimHours),
      ('dispensing_time_hours', _dispenseHours),
    ]) {
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      final n = num.tryParse(text);
      if (n == null || n < 0) problem ??= '${humanize(key)} must be a positive number.';
      numbers[key] = n;
    }
    if (problem != null) return setState(() => _error = problem);
    setState(() => _error = null);

    final body = <String, dynamic>{
      'entity_type': _entityType,
      'pharmacy_or_group_id': int.tryParse(_partyId!) ?? _partyId,
      'start_date': apiDate(_start!),
      if (_end != null) 'end_date': apiDate(_end!),
      'auto_renew': _autoRenew,
      'commission_rate': commission,
      if (_type.text.trim().isNotEmpty) 'agreement_type': _type.text.trim(),
      if (_paymentTerms.text.trim().isNotEmpty) 'payment_terms': _paymentTerms.text.trim(),
      for (final e in numbers.entries) e.key: e.value,
    };
    final result = await runAdminMutation(
      context,
      (c) => CreateAgreementAction(body, completer: c),
      success: 'Agreement created — it starts as pending until activated',
    );
    if (result.ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = _entityType == 'group';
    return AdminDialog(
      title: 'New Agreement',
      subtitle: 'New agreements start as pending. Activate one to put it into effect.',
      width: 680,
      actions: [
        SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        PendingBuilder(
          mutationKey: 'agreement.create',
          builder: (_, busy) =>
              PrimaryButton(label: 'Create Agreement', busy: busy, onPressed: _submit),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormGrid(children: [
            LabeledField(
              label: 'Agreement With',
              required: true,
              child: AdminDropdown<String>(
                value: _entityType,
                items: _entityTypes,
                onChanged: (v) => setState(() {
                  _entityType = v ?? 'pharmacy';
                  _partyId = null;
                }),
              ),
            ),
            LabeledField(
              label: isGroup ? 'Group' : 'Pharmacy',
              required: true,
              child: AdminResourceBuilder(
                key: ValueKey(_entityType),
                resource: isGroup ? AdminResource.groups : AdminResource.pharmacies,
                load: isGroup ? const {'is_active': true} : pharmacyListParams,
                builder: (context, data) {
                  final items = isGroup
                      ? [
                          for (final g in recordsOf(data.data))
                            ('${g['id']}', '${g['group_name'] ?? 'Group #${g['id']}'}'),
                        ]
                      : [
                          for (final p in recordsOf(data.data, ['pharmacies']))
                            ('${p['id']}', '${p['pharmacy_name'] ?? 'Pharmacy #${p['id']}'}'),
                        ];
                  return AdminDropdown<String>(
                    value: _partyId,
                    hint: !data.hasData ? 'Loading…' : (items.isEmpty ? 'None available' : 'Select'),
                    items: items,
                    onChanged: (v) => setState(() => _partyId = v),
                  );
                },
              ),
            ),
            LabeledField(
                label: 'Start Date',
                required: true,
                child: AdminDateInput(value: _start, onChanged: (d) => setState(() => _start = d))),
            LabeledField(
                label: 'End Date',
                child: AdminDateInput(
                    value: _end,
                    hint: 'Open-ended',
                    clearable: true,
                    onChanged: (d) => setState(() => _end = d))),
            LabeledField(
                label: 'Commission Rate (%)',
                required: true,
                child: AdminTextInput(
                    controller: _commission,
                    hint: 'e.g. 10',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            LabeledField(
                label: 'Service Fee',
                child: AdminTextInput(
                    controller: _fee,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            LabeledField(
                label: 'Agreement Type',
                child: AdminTextInput(controller: _type, hint: 'e.g. dispensing')),
            LabeledField(
                label: 'Payment Terms',
                child: AdminTextInput(controller: _paymentTerms, hint: 'e.g. net_30')),
            LabeledField(
                label: 'Claim Response SLA (hours)',
                child: AdminTextInput(controller: _claimHours, keyboardType: TextInputType.number)),
            LabeledField(
                label: 'Dispensing SLA (hours)',
                child:
                    AdminTextInput(controller: _dispenseHours, keyboardType: TextInputType.number)),
            LabeledField(
                label: 'Min. Monthly Transactions',
                child: AdminTextInput(controller: _minTx, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: const Text('Renew automatically', style: TextStyle(fontSize: 13.5)),
            value: _autoRenew,
            onChanged: (v) => setState(() => _autoRenew = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorPanel(message: _error!, compact: true),
          ],
        ],
      ),
    );
  }
}

// ─── Edit ─────────────────────────────────────────────────────────────────────

/// Edits the terms the update endpoint accepts. The server keeps any field
/// that is left blank, so a field cannot be cleared from here.
class AgreementEditDialog extends StatefulWidget {
  final Map<String, dynamic> agreement;
  const AgreementEditDialog({super.key, required this.agreement});

  @override
  State<AgreementEditDialog> createState() => _AgreementEditDialogState();
}

class _AgreementEditDialogState extends State<AgreementEditDialog> {
  late final Map<String, dynamic> a = widget.agreement;
  late final _commission = TextEditingController(text: a['commission_rate']?.toString());
  late final _fee = TextEditingController(text: a['service_fee']?.toString());
  late final _claimHours = TextEditingController(text: a['claim_response_time_hours']?.toString());
  late final _dispenseHours = TextEditingController(text: a['dispensing_time_hours']?.toString());
  late final _paymentTerms = TextEditingController(text: a['payment_terms']?.toString());
  late String? _status = a['status']?.toString();
  late DateTime? _end = DateTime.tryParse('${a['end_date']}');
  String? _error;

  @override
  void dispose() {
    for (final c in [_commission, _fee, _claimHours, _dispenseHours, _paymentTerms]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final body = <String, dynamic>{};
    String? problem;
    for (final (key, controller) in [
      ('commission_rate', _commission),
      ('service_fee', _fee),
      ('claim_response_time_hours', _claimHours),
      ('dispensing_time_hours', _dispenseHours),
    ]) {
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      final n = num.tryParse(text);
      if (n == null || n < 0) problem ??= '${humanize(key)} must be a positive number.';
      body[key] = n;
    }
    final commission = numOf(body['commission_rate']);
    if (commission != null && commission > 100) problem ??= 'Commission cannot exceed 100%.';
    if (problem != null) return setState(() => _error = problem);
    setState(() => _error = null);

    if (_paymentTerms.text.trim().isNotEmpty) body['payment_terms'] = _paymentTerms.text.trim();
    if (_status != null && _status != a['status']) body['status'] = _status;
    if (_end != null) body['end_date'] = apiDate(_end!);

    final result = await runAdminMutation(
      context,
      (c) => UpdateAgreementAction(a['id'], body, completer: c),
      success: 'Agreement #${a['id']} updated',
    );
    if (result.ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdminDialog(
      title: 'Edit Agreement #${a['id']}',
      subtitle: 'Blank fields keep their current value.',
      actions: [
        SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        PendingBuilder(
          mutationKey: 'agreement.${a['id']}.update',
          builder: (_, busy) => PrimaryButton(label: 'Save Changes', busy: busy, onPressed: _submit),
        ),
      ],
      child: Column(children: [
        FormGrid(children: [
          LabeledField(
              label: 'Commission Rate (%)',
              child: AdminTextInput(
                  controller: _commission,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          LabeledField(
              label: 'Service Fee',
              child: AdminTextInput(
                  controller: _fee,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          LabeledField(
              label: 'Claim Response SLA (hours)',
              child: AdminTextInput(controller: _claimHours, keyboardType: TextInputType.number)),
          LabeledField(
              label: 'Dispensing SLA (hours)',
              child: AdminTextInput(controller: _dispenseHours, keyboardType: TextInputType.number)),
          LabeledField(label: 'Payment Terms', child: AdminTextInput(controller: _paymentTerms)),
          LabeledField(
              label: 'End Date',
              child: AdminDateInput(value: _end, onChanged: (d) => setState(() => _end = d))),
          LabeledField(
              label: 'Status',
              child: AdminDropdown<String>(
                  value: _status, items: _statuses, onChanged: (v) => setState(() => _status = v))),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 14),
          ErrorPanel(message: _error!, compact: true),
        ],
      ]),
    );
  }
}

// ─── Detail ───────────────────────────────────────────────────────────────────

Future<void> showAgreementDetail(BuildContext context, Object? id) async {
  if (id == null) return;
  final store = StoreProvider.of<AppState>(context, listen: false);
  await showDialog(context: context, builder: (_) => _AgreementDetailDialog(id: id));
  store.dispatch(const ClearAdminResourceAction(AdminResource.agreementDetail));
}

class _AgreementDetailDialog extends StatelessWidget {
  final Object id;
  const _AgreementDetailDialog({required this.id});

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.agreementDetail,
      load: {'id': id},
      builder: (context, data) {
        final a = mapOf(data.data);
        final status = a['status']?.toString();
        return AdminDialog(
          title: 'Agreement #$id',
          subtitle: a['entity_name'] == null
              ? null
              : '${a['entity_name']} · ${humanize('${a['entity_type'] ?? ''}')}',
          width: 820,
          actions: [
            if (data.hasData && status == 'active')
              SecondaryButton(
                  label: 'Suspend',
                  icon: Icons.pause_circle_outline,
                  onPressed: () => setAgreementActive(context, a, false)),
            if (data.hasData && (status == 'pending' || status == 'suspended'))
              SecondaryButton(
                  label: 'Activate',
                  icon: Icons.play_circle_outline,
                  onPressed: () => setAgreementActive(context, a, true)),
            if (data.hasData)
              SecondaryButton(
                  label: 'Edit Terms',
                  icon: Icons.edit_outlined,
                  onPressed: () => showDialog(
                      context: context, builder: (_) => AgreementEditDialog(agreement: a))),
            PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
          ],
          child: AsyncContent(
            data: data,
            onRetry: () => reloadAdmin(context, AdminResource.agreementDetail),
            builder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status != null) StatusBadge(status: humanize(status)),
                const SizedBox(height: 16),
                const SubHeading('Terms'),
                KeyValueGrid(
                  values: a,
                  exclude: const {'id', 'entity_name', 'entity_type', 'status', 'created_by'},
                  formatters: const {'commission_rate': percent},
                ),
                const SizedBox(height: 22),
                const SubHeading('Compliance'),
                mapOf(a['compliance']).isEmpty
                    ? const EmptyState(message: 'No compliance records for this agreement yet.')
                    : KeyValueGrid(values: mapOf(a['compliance'])),
                const SizedBox(height: 22),
                const SubHeading('Monthly Trend'),
                RecordTable(
                  rows: recordsOf(a['trends']),
                  emptyMessage: 'No monthly compliance data yet.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
