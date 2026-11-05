import 'dart:async';

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

const _tiers = [('premium', 'Premium'), ('standard', 'Standard'), ('basic', 'Basic')];

/// Pharmacy partnership groups: list, search, create, edit, and membership.
class PartnerGroupsScreen extends StatefulWidget {
  const PartnerGroupsScreen({super.key});

  @override
  State<PartnerGroupsScreen> createState() => _PartnerGroupsScreenState();
}

class _PartnerGroupsScreenState extends State<PartnerGroupsScreen> {
  bool _active = true;
  String? _tier;
  String _query = '';
  Timer? _debounce;

  /// Search and the filters are separate endpoints: the search endpoint takes
  /// only `q`, so the filters don't apply while a search term is set.
  Map<String, dynamic> get _params => _query.isNotEmpty
      ? {'q': _query}
      : {'is_active': _active, if (_tier != null) 'tier': _tier};

  void _reload() => loadAdmin(context, AdminResource.groups, params: _params);

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Partner Groups',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Partner Groups',
              subtitle: 'Pharmacy groups, their tiers and members',
              searchHint: 'Search groups',
              onSearchChanged: _onSearch,
              actionLabel: 'New Group',
              onActionTap: () => showDialog(
                context: context,
                builder: (_) => const GroupFormDialog(),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterPills<bool>(
                  options: const [(true, 'Active'), (false, 'Inactive')],
                  selected: _active,
                  onSelected: (v) {
                    setState(() => _active = v);
                    _reload();
                  },
                ),
                FilterPills<String?>(
                  options: const [(null, 'All tiers'), ..._tiers],
                  selected: _tier,
                  onSelected: (v) {
                    setState(() => _tier = v);
                    _reload();
                  },
                ),
                if (_query.isNotEmpty)
                  const Text('Showing search results — filters are not applied',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 18),
            AdminResourceBuilder(
              resource: AdminResource.groups,
              load: _params,
              builder: (context, data) {
                final rows = recordsOf(data.data);
                return Column(
                  children: [
                    if (data.hasData) ...[
                      _GroupStats(rows: rows),
                      const SizedBox(height: 18),
                    ],
                    SectionCard(
                      child: AsyncContent(
                        data: data,
                        onRetry: () => reloadAdmin(context, AdminResource.groups),
                        builder: (_) => _GroupsTable(rows: rows),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Member count for a group row. Search responses carry a live
/// `pharmacy_count`; the plain list may only have the stored
/// `total_pharmacies`.
num? _memberCount(Map<String, dynamic> group) =>
    numOf(group['pharmacy_count']) ?? numOf(group['total_pharmacies']);

/// Parent company, and a note on the default group (where every newly
/// registered pharmacy starts).
String? _groupSubtitle(Map<String, dynamic> group) {
  final parts = [
    if (group['is_default'] == true) 'Default for new pharmacies',
    if ((group['parent_company']?.toString() ?? '').trim().isNotEmpty) group['parent_company'].toString(),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class _GroupStats extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _GroupStats({required this.rows});

  @override
  Widget build(BuildContext context) {
    num sum(String key) => rows.fold<num>(0, (t, r) => t + (numOf(r[key]) ?? 0));
    final members = rows.fold<num>(0, (t, r) => t + (_memberCount(r) ?? 0));
    final rates = rows.map((r) => numOf(r['commission_rate'])).whereType<num>().toList();
    final avgRate = rates.isEmpty ? null : rates.reduce((a, b) => a + b) / rates.length;

    return StatGrid(stats: [
      StatCardData(label: 'Groups', value: '${rows.length}', icon: Icons.hub_outlined),
      StatCardData(
          label: 'Member Pharmacies',
          value: formatNumber(members),
          icon: Icons.local_pharmacy_outlined),
      StatCardData(
          label: 'Avg Commission',
          value: avgRate == null ? '—' : percent(avgRate),
          icon: Icons.percent),
      StatCardData(
          label: 'Claims Handled',
          value: formatNumber(sum('total_claims_handled')),
          icon: Icons.receipt_long_outlined),
    ]);
  }
}

class _GroupsTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _GroupsTable({required this.rows});

  void _open(BuildContext context, Map<String, dynamic> row) =>
      showGroupDetail(context, row['id'], row['group_name']?.toString());

  @override
  Widget build(BuildContext context) {
    return RecordTable(
      rows: rows,
      emptyMessage: 'No groups match these filters.',
      onRowTap: (row) => _open(context, row),
      columns: [
        RecordColumn('Group',
            width: 240,
            cell: (r) => CellText(formatValue(r['group_name']),
                strong: true, subtitle: _groupSubtitle(r))),
        RecordColumn('Tier',
            width: 110,
            cell: (r) => Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(status: humanize('${r['tier'] ?? '—'}')))),
        RecordColumn('Pharmacies',
            width: 100, cell: (r) => CellText(formatValue(_memberCount(r)))),
        RecordColumn('Commission',
            width: 110, cell: (r) => CellText(percent(r['commission_rate']))),
        const RecordColumn('Claims', field: 'total_claims_handled', width: 90),
        const RecordColumn('Revenue', field: 'total_revenue', width: 110),
        RecordColumn('Status',
            width: 100,
            cell: (r) => Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(status: r['is_active'] == false ? 'Inactive' : 'Active'))),
        const RecordColumn('Created', field: 'created_at', width: 150),
      ],
      actionsWidth: 90,
      actions: (row) => Row(children: [
        RowIconButton(
            icon: Icons.visibility_outlined,
            tooltip: 'View group',
            onPressed: () => _open(context, row)),
        RowIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit group',
            onPressed: () => showDialog(
                context: context, builder: (_) => GroupFormDialog(group: row))),
      ]),
    );
  }
}

// ─── Create / edit ────────────────────────────────────────────────────────────

class GroupFormDialog extends StatefulWidget {
  /// The group to edit; omitted to create one.
  final Map<String, dynamic>? group;
  const GroupFormDialog({super.key, this.group});

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  late final _name = TextEditingController(text: widget.group?['group_name']?.toString());
  late final _company = TextEditingController(text: widget.group?['parent_company']?.toString());
  late final _commission = TextEditingController(text: widget.group?['commission_rate']?.toString());
  late final _description = TextEditingController(text: widget.group?['description']?.toString());
  late String? _tier = widget.group?['tier']?.toString() ?? 'standard';
  late bool _isActive = widget.group?['is_active'] != false;
  String? _error;

  bool get _editing => widget.group != null;

  @override
  void dispose() {
    for (final c in [_name, _company, _commission, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final commissionText = _commission.text.trim();
    final commission = commissionText.isEmpty ? null : num.tryParse(commissionText);

    if (name.isEmpty) return setState(() => _error = 'Group name is required.');
    if (_tier == null) return setState(() => _error = 'Choose a tier.');
    if (commissionText.isNotEmpty && (commission == null || commission < 0 || commission > 100)) {
      return setState(() => _error = 'Commission must be a number from 0 to 100.');
    }
    setState(() => _error = null);

    final body = <String, dynamic>{
      'group_name': name,
      'tier': _tier,
      if (_company.text.trim().isNotEmpty) 'parent_company': _company.text.trim(),
      if (commission != null) 'commission_rate': commission,
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      if (_editing) 'is_active': _isActive,
    };

    final result = await runAdminMutation(
      context,
      (c) => _editing
          ? UpdateGroupAction(widget.group!['id'], body, completer: c)
          : CreateGroupAction(body, completer: c),
      success: _editing ? 'Group updated' : 'Group "$name" created',
    );
    if (result.ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final key = _editing ? 'group.${widget.group!['id']}.update' : 'group.create';
    return AdminDialog(
      title: _editing ? 'Edit Group' : 'New Group',
      subtitle: _editing ? null : 'Pharmacies can be added once the group exists.',
      actions: [
        SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        PendingBuilder(
          mutationKey: key,
          builder: (_, busy) => PrimaryButton(
              label: _editing ? 'Save Changes' : 'Create Group', busy: busy, onPressed: _submit),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormGrid(children: [
            LabeledField(label: 'Group Name', required: true, child: AdminTextInput(controller: _name)),
            LabeledField(label: 'Parent Company', child: AdminTextInput(controller: _company)),
            LabeledField(
              label: 'Tier',
              required: true,
              child: AdminDropdown<String>(
                  value: _tier, items: _tiers, onChanged: (v) => setState(() => _tier = v)),
            ),
            LabeledField(
              label: 'Commission Rate (%)',
              child: AdminTextInput(
                  controller: _commission,
                  hint: 'e.g. 12.5',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            ),
          ]),
          const SizedBox(height: 16),
          LabeledField(
              label: 'Description', child: AdminTextInput(controller: _description, maxLines: 3)),
          if (_editing) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text('Group is active', style: TextStyle(fontSize: 13.5)),
              subtitle: const Text('Inactive groups are hidden from the default list.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            ErrorPanel(message: _error!, compact: true),
          ],
        ],
      ),
    );
  }
}

// ─── Detail ───────────────────────────────────────────────────────────────────

/// Opens a group's detail, clearing it from the store when closed so later
/// group writes don't keep reloading a view nobody is looking at.
Future<void> showGroupDetail(BuildContext context, Object? groupId, String? name) async {
  if (groupId == null) return;
  final store = StoreProvider.of<AppState>(context, listen: false);
  await showDialog(
    context: context,
    builder: (_) => _GroupDetailDialog(groupId: groupId, name: name),
  );
  store.dispatch(const ClearAdminResourceAction(AdminResource.groupDetail));
}

class _GroupDetailDialog extends StatelessWidget {
  final Object groupId;
  final String? name;
  const _GroupDetailDialog({required this.groupId, this.name});

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.groupDetail,
      load: {'id': groupId},
      builder: (context, data) {
        final group = mapOf(data.data);
        final members = recordsOf(group['pharmacies']);
        return AdminDialog(
          title: group['group_name']?.toString() ?? name ?? 'Group',
          subtitle: group['parent_company']?.toString(),
          width: 860,
          actions: [
            if (data.hasData)
              SecondaryButton(
                label: 'Edit Group',
                icon: Icons.edit_outlined,
                onPressed: () => showDialog(
                    context: context, builder: (_) => GroupFormDialog(group: group)),
              ),
            PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
          ],
          child: AsyncContent(
            data: data,
            onRetry: () => reloadAdmin(context, AdminResource.groupDetail),
            builder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, children: [
                  StatusBadge(status: humanize('${group['tier'] ?? '—'}')),
                  StatusBadge(status: group['is_active'] == false ? 'Inactive' : 'Active'),
                ]),
                if ((group['description']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(group['description'].toString(),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                ],
                const SizedBox(height: 18),
                const SubHeading('Statistics'),
                KeyValueGrid(
                  values: {
                    'commission_rate': group['commission_rate'],
                    ...mapOf(group['statistics']),
                  },
                  formatters: const {'commission_rate': percent},
                ),
                const SizedBox(height: 22),
                SubHeading('Member Pharmacies (${members.length})'),
                _AddMember(groupId: groupId, memberIds: members.map((m) => '${m['id']}').toSet()),
                const SizedBox(height: 14),
                RecordTable(
                  rows: members,
                  emptyMessage: 'No pharmacies in this group yet.',
                  columns: [
                    RecordColumn('Pharmacy',
                        width: 220,
                        cell: (r) => CellText(formatValue(r['pharmacy_name']),
                            strong: true, subtitle: r['email']?.toString())),
                    RecordColumn('Location',
                        width: 160,
                        cell: (r) => CellText(
                            [r['city'], r['province']].where((v) => v != null).join(', '))),
                    const RecordColumn('Primary', field: 'is_primary', width: 80),
                    const RecordColumn('Status', field: 'status', width: 100),
                    const RecordColumn('Joined', field: 'joined_at', width: 140),
                  ],
                  actionsWidth: 60,
                  actions: (row) => PendingBuilder(
                    mutationKey: 'group.$groupId.remove.${row['id']}',
                    builder: (context, busy) => RowIconButton(
                      icon: Icons.person_remove_outlined,
                      tooltip: 'Remove from group',
                      color: AppColors.danger,
                      onPressed: busy ? null : () => _remove(context, row),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _remove(BuildContext context, Map<String, dynamic> pharmacy) async {
    final name = pharmacy['pharmacy_name'] ?? 'this pharmacy';
    final ok = await confirmAdmin(context,
        title: 'Remove pharmacy?',
        message: 'Remove $name from the group? Its membership history is kept.',
        confirmLabel: 'Remove',
        destructive: true);
    if (!ok || !context.mounted) return;
    await runAdminMutation(
      context,
      (c) => RemovePharmacyFromGroupAction(groupId, pharmacy['id'], completer: c),
      success: '$name removed from the group',
    );
  }
}

class _AddMember extends StatefulWidget {
  final Object groupId;
  final Set<String> memberIds;
  const _AddMember({required this.groupId, required this.memberIds});

  @override
  State<_AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<_AddMember> {
  String? _pharmacyId;
  bool _primary = true;

  Future<void> _add() async {
    if (_pharmacyId == null) return;
    final result = await runAdminMutation(
      context,
      (c) => AddPharmacyToGroupAction(widget.groupId, int.tryParse(_pharmacyId!) ?? _pharmacyId!,
          isPrimary: _primary, completer: c),
      success: 'Pharmacy added to the group',
    );
    if (result.ok && mounted) setState(() => _pharmacyId = null);
  }

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.pharmacies,
      load: pharmacyListParams,
      builder: (context, data) {
        final options = [
          for (final p in recordsOf(data.data, ['pharmacies']))
            if (!widget.memberIds.contains('${p['id']}'))
              ('${p['id']}', '${p['pharmacy_name'] ?? 'Pharmacy #${p['id']}'} · ${p['city'] ?? ''}'),
        ];
        return Row(
          children: [
            Expanded(
              child: AdminDropdown<String>(
                value: _pharmacyId,
                hint: data.isLoading && !data.hasData
                    ? 'Loading pharmacies…'
                    : options.isEmpty
                        ? 'Every pharmacy is already a member'
                        : 'Choose a pharmacy to add',
                items: options,
                onChanged: (v) => setState(() => _pharmacyId = v),
              ),
            ),
            const SizedBox(width: 10),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(
                value: _primary,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _primary = v ?? true),
              ),
              const Text('Primary', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ]),
            const SizedBox(width: 10),
            PendingBuilder(
              mutationKey: 'group.${widget.groupId}.add',
              builder: (_, busy) => PrimaryButton(
                label: 'Add',
                icon: Icons.add,
                busy: busy,
                onPressed: _pharmacyId == null ? null : _add,
              ),
            ),
          ],
        );
      },
    );
  }
}
