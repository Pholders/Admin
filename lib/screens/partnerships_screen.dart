import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../features/partnerships/domain/entities/partnership_overview.dart';
import '../features/partnerships/domain/entities/pharmacy_agreement.dart';
import '../features/partnerships/domain/entities/pharmacy_group.dart';
import '../features/partnerships/domain/usecases/partnership_usecases.dart';
import '../theme/app_colors.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/table_cell.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/partnerships/agreement_form_dialog.dart';
import '../widgets/partnerships/async_section.dart';
import '../widgets/partnerships/compliance_report_panel.dart';
import '../widgets/partnerships/group_form_dialog.dart';
import '../widgets/partnerships/partnership_formatting.dart';
import '../widgets/shell/app_shell.dart';

/// Pharmacy groups, partnership agreements, compliance and claim routing —
/// the whole admin partnership surface the API exposes.
class PartnershipsScreen extends StatefulWidget {
  const PartnershipsScreen({super.key});

  @override
  State<PartnershipsScreen> createState() => _PartnershipsScreenState();
}

class _PartnershipsScreenState extends State<PartnershipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  String _query = '';

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PartnershipsState>(
      converter: (store) => store.state.partnershipsState,
      distinct: true,
      onInit: (store) {
        final state = store.state.partnershipsState;
        if (!state.hasLoadedOverview) {
          store.dispatch(const LoadPartnershipOverviewAction());
        }
        // The agreement form needs the pharmacy list to name a counterparty,
        // and the directory is what carries it.
        if (!state.hasLoadedDirectory) {
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
        final overview = state.overview;

        return AppShell(
          currentPage: 'Partnerships',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Partnerships',
                subtitle:
                    'Pharmacy groups, agreements, compliance and claim routing',
                searchHint: 'Search groups and agreements',
                onSearchChanged: (v) => setState(() => _query = v),
                actionLabel:
                    state.isLoadingOverview ? 'Refreshing…' : 'Refresh',
                onActionTap: state.isLoadingOverview
                    ? null
                    : () => store
                        .dispatch(const LoadPartnershipOverviewAction()),
              ),
              const SizedBox(height: 20),
              if (overview != null) _OverviewStats(overview: overview),
              if (overview != null) const SizedBox(height: 16),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Groups'),
                  Tab(text: 'Agreements'),
                  Tab(text: 'Compliance & routing'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AsyncSection(
                  isLoading: state.isLoadingOverview,
                  hasLoaded: state.hasLoadedOverview,
                  error: state.overviewError,
                  isEmpty: overview == null,
                  emptyMessage:
                      'Nothing to show yet. Create a pharmacy group to get '
                      'started.',
                  onRetry: () => store
                      .dispatch(const LoadPartnershipOverviewAction()),
                  child: overview == null
                      ? const SizedBox.shrink()
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _GroupsTab(
                              overview: overview,
                              query: _query,
                              isBusy: state.isMutating,
                            ),
                            _AgreementsTab(
                              overview: overview,
                              directory: state.directory,
                              query: _query,
                              isBusy: state.isMutating,
                            ),
                            _ComplianceTab(overview: overview),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewStats extends StatelessWidget {
  const _OverviewStats({required this.overview});

  final PartnershipOverview overview;

  @override
  Widget build(BuildContext context) {
    final compliance = overview.compliance.summary;

    final stats = [
      StatCardData(
        label: 'Pharmacy groups',
        value: '${overview.groups.length}',
        icon: Icons.workspaces_outline,
      ),
      StatCardData(
        label: 'Pharmacies in groups',
        value: '${overview.pharmacyCount}',
        icon: Icons.local_pharmacy_outlined,
      ),
      StatCardData(
        label: 'Active agreements',
        value: '${overview.activeAgreementCount}',
        icon: Icons.handshake_outlined,
      ),
      StatCardData(
        label: 'Avg compliance',
        value: formatPercent(compliance.averageComplianceScore),
        icon: Icons.verified_outlined,
      ),
      StatCardData(
        label: 'Claims routed',
        value: '${overview.routing.totalRoutes}',
        icon: Icons.alt_route_outlined,
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

// ─── Groups ──────────────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({
    required this.overview,
    required this.query,
    required this.isBusy,
  });

  final PartnershipOverview overview;
  final String query;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final needle = query.trim().toLowerCase();
    final groups = overview.groups.where((g) {
      if (needle.isEmpty) return true;
      return g.groupName.toLowerCase().contains(needle) ||
          (g.parentCompany?.toLowerCase().contains(needle) ?? false);
    }).toList();

    return _TabPanel(
      title: 'Pharmacy groups',
      actionLabel: 'New group',
      onAction: isBusy
          ? null
          : () async {
              final params = await showDialog<CreateGroupParams>(
                context: context,
                builder: (_) => const GroupFormDialog(),
              );
              if (params == null || !context.mounted) return;
              StoreProvider.of<AppState>(context)
                  .dispatch(CreatePharmacyGroupAction(params));
            },
      child: groups.isEmpty
          ? const _EmptyNote('No groups match.')
          : ScrollableTable(
              minWidth: 1000,
              header: const Row(
                children: [
                  AppTableHeaderCell(label: 'Group', width: 230),
                  AppTableHeaderCell(label: 'Parent company', width: 170),
                  AppTableHeaderCell(label: 'Tier', width: 100),
                  AppTableHeaderCell(label: 'Pharmacies', width: 100),
                  AppTableHeaderCell(label: 'Commission', width: 110),
                  AppTableHeaderCell(label: 'Status', width: 110),
                  AppTableHeaderCell(label: 'Actions', width: 90),
                ],
              ),
              rows: [
                for (final group in groups)
                  _GroupRow(group: group, isBusy: isBusy),
              ],
            ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.isBusy});

  final PharmacyGroup group;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTableCell(
          width: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.groupName,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              if (group.description != null)
                Text(
                  group.description!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        AppTableCell(
          width: 170,
          child: Text(
            group.parentCompany ?? '—',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableCell(width: 100, child: TierChip(tier: group.tier)),
        AppTableCell(
          width: 100,
          child: Text(
            '${group.pharmacyCount}',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        AppTableCell(
          width: 110,
          child: Text(
            formatPercent(group.commissionRate, decimals: 2),
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        AppTableCell(
          width: 110,
          child: StatusBadge(status: group.isActive ? 'Active' : 'Suspended'),
        ),
        AppTableCell(
          width: 90,
          child: PopupMenuButton<String>(
            enabled: !isBusy,
            icon: const Icon(Icons.more_vert,
                size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit group')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(group.isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
            onSelected: (value) => _onAction(context, value),
          ),
        ),
      ],
    );
  }

  Future<void> _onAction(BuildContext context, String value) async {
    final store = StoreProvider.of<AppState>(context);

    if (value == 'toggle') {
      store.dispatch(UpdatePharmacyGroupAction(
        UpdateGroupParams(groupId: group.id, isActive: !group.isActive),
      ));
      return;
    }

    final params = await showDialog<CreateGroupParams>(
      context: context,
      builder: (_) => GroupFormDialog(existing: group),
    );
    if (params == null) return;

    store.dispatch(UpdatePharmacyGroupAction(UpdateGroupParams(
      groupId: group.id,
      groupName: params.groupName,
      tier: params.tier,
      parentCompany: params.parentCompany,
      description: params.description,
      commissionRate: params.commissionRate,
    )));
  }
}

// ─── Agreements ──────────────────────────────────────────────────────────────

class _AgreementsTab extends StatefulWidget {
  const _AgreementsTab({
    required this.overview,
    required this.directory,
    required this.query,
    required this.isBusy,
  });

  final PartnershipOverview overview;
  final PharmacyDirectory directory;
  final String query;
  final bool isBusy;

  @override
  State<_AgreementsTab> createState() => _AgreementsTabState();
}

class _AgreementsTabState extends State<_AgreementsTab> {
  String? _statusFilter;

  /// Resolves an agreement's counterparty name.
  ///
  /// The list endpoint returns the bare row without `entity_name` — only the
  /// detail endpoint joins it — so the name is looked up in the group and
  /// pharmacy lists already loaded.
  String _entityName(PharmacyAgreement agreement) {
    if (agreement.entityName != null) return agreement.entityName!;

    if (agreement.isGroupAgreement) {
      for (final group in widget.overview.groups) {
        if (group.id == agreement.pharmacyOrGroupId) return group.groupName;
      }
      return 'Group #${agreement.pharmacyOrGroupId}';
    }

    for (final entry in widget.directory.entries) {
      if (entry.id == agreement.pharmacyOrGroupId) {
        return entry.pharmacy.pharmacyName;
      }
    }
    return 'Pharmacy #${agreement.pharmacyOrGroupId}';
  }

  @override
  Widget build(BuildContext context) {
    final needle = widget.query.trim().toLowerCase();

    final agreements = widget.overview.agreements.where((a) {
      if (_statusFilter != null && a.status != _statusFilter) return false;
      if (needle.isEmpty) return true;
      return _entityName(a).toLowerCase().contains(needle) ||
          (a.agreementType?.toLowerCase().contains(needle) ?? false);
    }).toList();

    return _TabPanel(
      title: 'Partnership agreements',
      actionLabel: 'New agreement',
      onAction: widget.isBusy ? null : () => _createAgreement(context),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.overview.expiringAgreements.isNotEmpty)
            _ExpiringBanner(agreements: widget.overview.expiringAgreements),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final status in const [
                'pending',
                'active',
                'suspended',
                'expired',
                'terminated',
              ])
                FilterChip(
                  label: Text(titleCase(status)),
                  selected: _statusFilter == status,
                  onSelected: (selected) => setState(
                    () => _statusFilter = selected ? status : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      child: agreements.isEmpty
          ? const _EmptyNote('No agreements match.')
          : ScrollableTable(
              minWidth: 1120,
              header: const Row(
                children: [
                  AppTableHeaderCell(label: 'Counterparty', width: 220),
                  AppTableHeaderCell(label: 'Type', width: 130),
                  AppTableHeaderCell(label: 'Commission', width: 100),
                  AppTableHeaderCell(label: 'SLA (respond / dispense)', width: 180),
                  AppTableHeaderCell(label: 'Period', width: 190),
                  AppTableHeaderCell(label: 'Status', width: 110),
                  AppTableHeaderCell(label: 'Actions', width: 90),
                ],
              ),
              rows: [
                for (final agreement in agreements)
                  _AgreementRow(
                    agreement: agreement,
                    entityName: _entityName(agreement),
                    isBusy: widget.isBusy,
                  ),
              ],
            ),
    );
  }

  Future<void> _createAgreement(BuildContext context) async {
    final params = await showDialog<CreateAgreementParams>(
      context: context,
      builder: (_) => AgreementFormDialog(
        groups: widget.overview.groups,
        pharmacies: widget.directory.entries,
      ),
    );
    if (params == null || !context.mounted) return;

    StoreProvider.of<AppState>(context)
        .dispatch(CreateAgreementAction(params));
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.agreement,
    required this.entityName,
    required this.isBusy,
  });

  final PharmacyAgreement agreement;
  final String entityName;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final remaining = agreement.daysUntilExpiry;

    return Row(
      children: [
        AppTableCell(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entityName,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                agreement.isGroupAgreement ? 'Group' : 'Pharmacy',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        AppTableCell(
          width: 130,
          child: Text(
            agreement.agreementType ?? '—',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableCell(
          width: 100,
          child: Text(
            formatPercent(agreement.commissionRate, decimals: 2),
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        AppTableCell(
          width: 180,
          child: Text(
            '${agreement.claimResponseTimeHours ?? '—'}h / '
            '${agreement.dispensingTimeHours ?? '—'}h',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        AppTableCell(
          width: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${formatDay(agreement.startDate)} → '
                '${agreement.endDate == null ? 'open' : formatDay(agreement.endDate)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (remaining != null && remaining >= 0 && remaining <= 30)
                Text(
                  'Expires in $remaining ${remaining == 1 ? 'day' : 'days'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        AppTableCell(
          width: 110,
          child:
              StatusBadge(status: humanizeAgreementStatus(agreement.status)),
        ),
        AppTableCell(
          width: 90,
          child: PopupMenuButton<bool>(
            enabled: !isBusy,
            icon: const Icon(Icons.more_vert,
                size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (context) => [
              if (agreement.status != 'active')
                const PopupMenuItem(value: true, child: Text('Activate')),
              if (agreement.status == 'active')
                const PopupMenuItem(value: false, child: Text('Suspend')),
            ],
            onSelected: (activate) => StoreProvider.of<AppState>(context)
                .dispatch(SetAgreementStatusAction(SetAgreementStatusParams(
              agreementId: agreement.id,
              activate: activate,
            ))),
          ),
        ),
      ],
    );
  }
}

class _ExpiringBanner extends StatelessWidget {
  const _ExpiringBanner({required this.agreements});

  final List<PharmacyAgreement> agreements;

  @override
  Widget build(BuildContext context) {
    final soonest = agreements.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.alertBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: AppColors.alertIcon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${agreements.length} '
              '${agreements.length == 1 ? 'agreement expires' : 'agreements expire'} '
              'within 30 days — the soonest on ${formatDay(soonest.endDate)}.',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Compliance & routing ────────────────────────────────────────────────────

class _ComplianceTab extends StatelessWidget {
  const _ComplianceTab({required this.overview});

  final PartnershipOverview overview;

  @override
  Widget build(BuildContext context) {
    final summary = overview.compliance.summary;
    final routing = overview.routing;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Panel(
            title: 'Compliance this month',
            child: Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                _Metric(
                  label: 'Average score',
                  value: formatPercent(summary.averageComplianceScore),
                ),
                _Metric(
                    label: 'Excellent (90+)',
                    value: '${summary.excellentCount}'),
                _Metric(label: 'Good (80–89)', value: '${summary.goodCount}'),
                _Metric(label: 'Poor (<80)', value: '${summary.poorCount}'),
                _Metric(
                    label: 'Suspended agreements',
                    value: '${summary.suspendedAgreements}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Claim routing',
            child: Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                _Metric(label: 'Routed', value: '${routing.totalRoutes}'),
                _Metric(label: 'Accepted', value: '${routing.acceptedCount}'),
                _Metric(label: 'Rejected', value: '${routing.rejectedCount}'),
                _Metric(
                    label: 'Awaiting response',
                    value: '${routing.pendingCount}'),
                _Metric(
                  label: 'Acceptance rate',
                  value: formatPercent(routing.acceptanceRate),
                ),
                _Metric(
                  label: 'Avg response',
                  value: formatDuration(routing.averageResponseSeconds),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (overview.routingByTier.isNotEmpty)
            _Panel(
              title: 'Routing by tier',
              child: ScrollableTable(
                minWidth: 560,
                header: const Row(
                  children: [
                    AppTableHeaderCell(label: 'Tier', width: 140),
                    AppTableHeaderCell(label: 'Routed', width: 110),
                    AppTableHeaderCell(label: 'Accepted', width: 110),
                    AppTableHeaderCell(label: 'Rejected', width: 110),
                    AppTableHeaderCell(label: 'Acceptance', width: 110),
                  ],
                ),
                rows: [
                  for (final tier in overview.routingByTier)
                    Row(
                      children: [
                        AppTableCell(
                            width: 140, child: TierChip(tier: tier.tier)),
                        AppTableCell(
                          width: 110,
                          child: Text('${tier.totalRoutes}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary)),
                        ),
                        AppTableCell(
                          width: 110,
                          child: Text('${tier.accepted}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary)),
                        ),
                        AppTableCell(
                          width: 110,
                          child: Text('${tier.rejected}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary)),
                        ),
                        AppTableCell(
                          width: 110,
                          child: Text(
                            tier.acceptanceRate == null
                                ? '—'
                                : '${tier.acceptanceRate}%',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (overview.routingByTier.isNotEmpty) const SizedBox(height: 16),
          if (overview.compliance.lowPerformers.isNotEmpty)
            _Panel(
              title: 'Needs attention',
              subtitle: 'Pharmacies scoring below 70',
              child: Column(
                children: [
                  for (final performer in overview.compliance.lowPerformers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              performer.pharmacyName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            'Accepted ${performer.totalClaimsAccepted ?? 0}'
                            '/${performer.totalClaimsRouted ?? 0}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            formatPercent(performer.overallScore),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (overview.compliance.lowPerformers.isNotEmpty)
            const SizedBox(height: 16),
          const ComplianceReportPanel(),
        ],
      ),
    );
  }
}

// ─── Shared layout pieces ────────────────────────────────────────────────────

class _TabPanel extends StatelessWidget {
  const _TabPanel({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.header,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: kTableActionMenuClearance),
      child: _Panel(
        title: title,
        action: actionLabel == null
            ? null
            : FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.chipBlack,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(actionLabel!,
                    style: const TextStyle(fontSize: 12.5)),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[header!, const SizedBox(height: 16)],
            child,
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}
