import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';

import 'package:pholders_admin/store.dart';
import '../core/di/service_locator.dart';
import '../features/partnerships/domain/entities/pharmacy_group.dart';
import '../features/partnerships/domain/usecases/partnership_usecases.dart';
import '../theme/app_colors.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/table_cell.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/partnerships/async_section.dart';
import '../widgets/partnerships/partnership_formatting.dart';
import '../widgets/shell/app_shell.dart';

/// Every pharmacy on the platform, assembled from group membership.
///
/// The API has no endpoint that lists pharmacies on their own, so a pharmacy
/// only appears once it belongs to a group — see
/// `PartnershipRepository.getPharmacyDirectory`. The row actions are limited
/// to what the admin API can actually do: read compliance, and move a
/// pharmacy between groups. There is no admin route that suspends or deletes
/// a pharmacy account, so no control offers to.
class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  State<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  String _query = '';
  String? _statusFilter;

  List<PharmacyDirectoryEntry> _filtered(List<PharmacyDirectoryEntry> all) {
    Iterable<PharmacyDirectoryEntry> list = all;

    if (_statusFilter != null) {
      list = list.where((e) => e.pharmacy.status == _statusFilter);
    }

    final needle = _query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      list = list.where((e) =>
          e.pharmacy.pharmacyName.toLowerCase().contains(needle) ||
          e.pharmacy.email.toLowerCase().contains(needle) ||
          e.pharmacy.contactName.toLowerCase().contains(needle) ||
          (e.pharmacy.city?.toLowerCase().contains(needle) ?? false) ||
          e.groupName.toLowerCase().contains(needle));
    }

    return list.toList();
  }

  void _toggleFilter(String status) {
    setState(() => _statusFilter = _statusFilter == status ? null : status);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PartnershipsState>(
      converter: (store) => store.state.partnershipsState,
      distinct: true,
      onInit: (store) {
        if (!store.state.partnershipsState.hasLoadedDirectory) {
          store.dispatch(const LoadPharmacyDirectoryAction());
        }
      },
      onDidChange: (previous, state) => showPartnershipActionBanner(
        context,
        previous: previous,
        current: state,
      ),
      builder: (context, state) {
        final store = StoreProvider.of<AppState>(context);
        final entries = state.directory.entries;
        final visible = _filtered(entries);

        return AppShell(
          currentPage: 'Pharmacies',
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: kTableActionMenuClearance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Pharmacies',
                  subtitle:
                      'Pharmacies on the platform, grouped by partnership tier',
                  searchHint: 'Search pharmacies',
                  onSearchChanged: (v) => setState(() => _query = v),
                  actionLabel: state.isLoadingDirectory
                      ? 'Refreshing…'
                      : 'Refresh',
                  onActionTap: state.isLoadingDirectory
                      ? null
                      : () => store.dispatch(
                            const LoadPharmacyDirectoryAction(),
                          ),
                ),
                const SizedBox(height: 20),
                _StatsRow(
                  entries: entries,
                  groupCount: state.directory.groups.length,
                  onFilter: _toggleFilter,
                ),
                if (_statusFilter != null) ...[
                  const SizedBox(height: 12),
                  _FilterBanner(
                    label: humanizePharmacyStatus(_statusFilter!),
                    onClear: () => setState(() => _statusFilter = null),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: AsyncSection(
                    isLoading: state.isLoadingDirectory,
                    hasLoaded: state.hasLoadedDirectory,
                    error: state.directoryError,
                    isEmpty: entries.isEmpty,
                    emptyMessage:
                        'No pharmacies are assigned to a group yet. Add one '
                        'from a group on the Partnerships screen and it will '
                        'appear here.',
                    onRetry: () =>
                        store.dispatch(const LoadPharmacyDirectoryAction()),
                    child: ScrollableTable(
                      minWidth: 1120,
                      header: const Row(
                        children: [
                          AppTableHeaderCell(label: 'Pharmacy', width: 230),
                          AppTableHeaderCell(
                              label: 'Owner / Contact', width: 150),
                          AppTableHeaderCell(label: 'Email', width: 210),
                          AppTableHeaderCell(label: 'Group / Tier', width: 170),
                          AppTableHeaderCell(label: 'Status', width: 110),
                          AppTableHeaderCell(label: 'Joined', width: 120),
                          AppTableHeaderCell(label: 'Actions', width: 90),
                        ],
                      ),
                      rows: [
                        for (final entry in visible)
                          _PharmacyRow(
                            entry: entry,
                            groups: state.directory.groups,
                            isBusy: state.isMutating,
                          ),
                        if (visible.isEmpty && entries.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No pharmacies match your search.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                      ],
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
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.entries,
    required this.groupCount,
    required this.onFilter,
  });

  final List<PharmacyDirectoryEntry> entries;
  final int groupCount;
  final ValueChanged<String> onFilter;

  int _count(String status) =>
      entries.where((e) => e.pharmacy.status == status).length;

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(
        label: 'Total Pharmacies',
        value: '${entries.length}',
        icon: Icons.local_pharmacy_outlined,
      ),
      StatCardData(
        label: 'Active',
        value: '${_count('active')}',
        icon: Icons.verified_outlined,
        actionLabel: 'Filter',
        onAction: () => onFilter('active'),
      ),
      StatCardData(
        label: 'Pending verification',
        value: '${_count('pending_verification')}',
        icon: Icons.hourglass_empty,
        actionLabel: 'Filter',
        onAction: () => onFilter('pending_verification'),
      ),
      StatCardData(
        label: 'Inactive',
        value: '${_count('inactive')}',
        icon: Icons.block_outlined,
        actionLabel: 'Filter',
        onAction: () => onFilter('inactive'),
      ),
      StatCardData(
        label: 'Groups',
        value: '$groupCount',
        icon: Icons.workspaces_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final stat in stats)
            SizedBox(
              width: constraints.maxWidth > 900
                  ? (constraints.maxWidth - 14 * 4) / 5
                  : 220,
              child: StatCard(data: stat),
            ),
        ],
      ),
    );
  }
}

class _FilterBanner extends StatelessWidget {
  const _FilterBanner({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filtering by status: ',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close,
                size: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PharmacyRow extends StatelessWidget {
  const _PharmacyRow({
    required this.entry,
    required this.groups,
    required this.isBusy,
  });

  final PharmacyDirectoryEntry entry;
  final List<PharmacyGroup> groups;
  final bool isBusy;

  static final _joinedFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final pharmacy = entry.pharmacy;
    final joined = pharmacy.joinedAt ?? pharmacy.createdAt;

    return Row(
      children: [
        AppTableCell(
          width: 230,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: avatarColorFor(pharmacy.id),
                child: Text(
                  initialsFor(pharmacy.pharmacyName),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pharmacy.pharmacyName,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pharmacy.city != null)
                      Text(
                        [pharmacy.city, pharmacy.province]
                            .whereType<String>()
                            .join(', '),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppTableCell(
          width: 150,
          child: Text(
            pharmacy.contactName,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableCell(
          width: 210,
          child: Text(
            pharmacy.email,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableCell(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.groupName,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              TierChip(tier: entry.tier),
            ],
          ),
        ),
        AppTableCell(
          width: 110,
          child: StatusBadge(status: humanizePharmacyStatus(pharmacy.status)),
        ),
        AppTableCell(
          width: 120,
          child: Text(
            joined == null ? '—' : _joinedFormat.format(joined),
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        AppTableCell(
          width: 90,
          child: PopupMenuButton<String>(
            enabled: !isBusy,
            icon: const Icon(Icons.more_vert,
                size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'compliance', child: Text('View compliance')),
              const PopupMenuItem(value: 'move', child: Text('Move to group')),
              const PopupMenuItem(
                  value: 'remove', child: Text('Remove from group')),
            ],
            onSelected: (value) => _onAction(context, value),
          ),
        ),
      ],
    );
  }

  Future<void> _onAction(BuildContext context, String value) async {
    final store = StoreProvider.of<AppState>(context);

    switch (value) {
      case 'compliance':
        await showDialog<void>(
          context: context,
          builder: (_) => _ComplianceDialog(entry: entry),
        );
        return;

      case 'move':
        final target = await showDialog<PharmacyGroup>(
          context: context,
          builder: (_) => _MoveToGroupDialog(entry: entry, groups: groups),
        );
        if (target == null) return;

        // One action, not an add plus a remove: the use case sequences the
        // two calls so a failure between them cannot leave the pharmacy in
        // no group at all.
        store.dispatch(MovePharmacyToGroupAction(MovePharmacyParams(
          pharmacyId: entry.id,
          fromGroupId: entry.groupId,
          toGroupId: target.id,
        )));
        return;

      case 'remove':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => _ConfirmDialog(
            title: 'Remove from group',
            message:
                'Remove ${entry.pharmacy.pharmacyName} from ${entry.groupName}? '
                'It will stop receiving routed claims and will disappear from '
                'this list until it is added to another group.',
            confirmLabel: 'Remove',
          ),
        );
        if (confirmed != true) return;

        store.dispatch(RemovePharmacyFromGroupAction(
          GroupMembershipParams(
            groupId: entry.groupId,
            pharmacyId: entry.id,
          ),
        ));
        return;
    }
  }
}

/// Reads one pharmacy's compliance standing on demand.
///
/// Goes straight to the use case instead of through Redux: it is a one-off
/// read for a single dialog, and nothing else in the app needs the result.
class _ComplianceDialog extends StatelessWidget {
  const _ComplianceDialog({required this.entry});

  final PharmacyDirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        entry.pharmacy.pharmacyName,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 380,
        child: FutureBuilder(
          future: sl<GetPharmacyComplianceUseCase>().call(entry.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text(
                '${snapshot.error}',
                style: const TextStyle(fontSize: 13, color: AppColors.danger),
              );
            }

            final status = snapshot.data!;
            if (!status.hasAgreements) {
              return const Text(
                'This pharmacy has no partnership agreement yet, so there is '
                'nothing to score. Create one from the Partnerships screen.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      status.overallCompliance == null
                          ? '—'
                          : '${status.overallCompliance!.round()}%',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(status: titleCase(status.status)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Across ${status.agreementCount} '
                  '${status.agreementCount == 1 ? 'agreement' : 'agreements'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),
                for (final agreement in status.agreements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            agreement.agreementType ??
                                'Agreement #${agreement.agreementId}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          agreement.averageCompliance == null
                              ? 'Not scored'
                              : '${agreement.averageCompliance!.round()}%',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _MoveToGroupDialog extends StatefulWidget {
  const _MoveToGroupDialog({required this.entry, required this.groups});

  final PharmacyDirectoryEntry entry;
  final List<PharmacyGroup> groups;

  @override
  State<_MoveToGroupDialog> createState() => _MoveToGroupDialogState();
}

class _MoveToGroupDialogState extends State<_MoveToGroupDialog> {
  PharmacyGroup? _selected;

  @override
  Widget build(BuildContext context) {
    final options = widget.groups
        .where((g) => g.id != widget.entry.groupId)
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Move to group',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 360,
        child: options.isEmpty
            ? const Text(
                'There is no other group to move this pharmacy to. Create one '
                'on the Partnerships screen first.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.entry.pharmacy.pharmacyName} is currently in '
                    '${widget.entry.groupName}.',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PharmacyGroup>(
                    initialValue: _selected,
                    decoration: const InputDecoration(
                      labelText: 'New group',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final group in options)
                        DropdownMenuItem(
                          value: group,
                          child: Text('${group.groupName} · ${group.tier}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selected = value),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: const Text('Move'),
        ),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 360,
        child: Text(message,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
