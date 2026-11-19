import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

/// Where every order is in the pickup flow, from the order tracking
/// endpoints. Orders are collected at the pharmacy: there are no deliveries
/// and no returns.
///
/// An order in progress is always waiting on someone (the pharmacy, the
/// medical aid or the patient), and is overdue once it has sat in its status
/// longer than the backend allows (`config/orderTracking.js`).
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  /// The statuses an order can wait in, in pickup-flow order.
  static const activeStatuses = [
    'pending', 'accepted', 'awaiting_claim', 'claim_approved', 'claim_rejected', 'preparing', 'ready',
  ];
  static const waitingOn = ['pharmacy', 'medical_aid', 'patient'];

  /// Startup prefetch uses these, so they must match the first load here.
  static const overdueParams = {'overdue': true, 'sort': 'longest_waiting'};

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  /// Days covered by the period figures; `null` is the backend's default
  /// (the last 30 days), sent as no dates at all.
  int? _days;

  /// Narrows the overdue list to who it is waiting on; `null` is everyone.
  String? _waitingOn;

  Map<String, dynamic> get _period {
    if (_days == null) return const {};
    final today = toSast(DateTime.now());
    return {'from': apiDate(today.subtract(Duration(days: _days! - 1))), 'to': apiDate(today)};
  }

  /// The stats load only as the page opens, so a new period loads them
  /// here; the pharmacy table reloads itself when its filters change.
  void _setDays(int? days) {
    if (days == _days) return;
    setState(() => _days = days);
    loadAdmin(context, AdminResource.orderTrackingStats, params: _period);
  }

  void _refresh() {
    loadAdmin(context, AdminResource.orderTrackingStats, params: _period, force: true);
    reloadAdmin(context, AdminResource.overdueOrders);
    reloadAdmin(context, AdminResource.orderTrackingPharmacies);
  }

  @override
  Widget build(BuildContext context) {
    final period = _period;
    return AppShell(
      currentPage: 'Tracking',
      body: PinnedPage(
        sections: true,
        header: [
          ScreenTitle(
            title: 'Order Tracking',
            subtitle: 'Where every order is in the pickup flow, who it is waiting on, and what is overdue',
            actions: [
              SizedBox(
                width: 170,
                child: AdminDropdown<int?>(
                  value: _days,
                  items: const [(7, 'Last 7 days'), (null, 'Last 30 days'), (90, 'Last 90 days')],
                  onChanged: _setDays,
                ),
              ),
              SecondaryButton(label: 'Refresh', icon: Icons.refresh, onPressed: _refresh),
            ],
          ),
          const SizedBox(height: 20),
        ],
        // A context inside the app shell, so an order opens in place of
        // the page rather than in a pop-up.
        body: (_) => Builder(builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminResourceBuilder(
            resource: AdminResource.orderTrackingStats,
            load: period,
            builder: (context, data) => AsyncContent(
              data: data,
              onRetry: () => reloadAdmin(context, AdminResource.orderTrackingStats),
              builder: (_) => _Stats(
                stats: mapOf(data.data),
                waitingOn: _waitingOn,
                onWaitingOn: (w) => setState(() => _waitingOn = _waitingOn == w ? null : w),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: _waitingOn == null
                ? 'Overdue orders'
                : 'Overdue orders waiting on ${waitingOnLabel(_waitingOn).toLowerCase()}',
            subtitle: 'Longest waiting first. Click an order for its full history.',
            trailing: _waitingOn == null
                ? null
                : SecondaryButton(label: 'Show all', onPressed: () => setState(() => _waitingOn = null)),
            child: PagedRecordList(
              resource: AdminResource.overdueOrders,
              listKey: 'orders',
              noun: 'overdue orders',
              filters: {...TrackingScreen.overdueParams, if (_waitingOn != null) 'waiting_on': _waitingOn},
              onRowTap: (r) => showOrderDetail(context, r['id'], row: r),
              columns: [
                RecordColumn('Order', width: 90, cell: (r) => CellText('#${r['id']}', strong: true)),
                const RecordColumn('Status', field: 'status', width: 140),
                RecordColumn('Waiting', width: 170, cell: (r) => OrderWaitCell(r)),
                RecordColumn('Overdue after', width: 110, cell: (r) => CellText(formatHours(r['overdue_after_hours']))),
                RecordColumn('Pharmacy', width: 200, cell: (r) => personCell(r, 'pharmacy')),
                RecordColumn('Patient', width: 190, cell: (r) => personCell(r, 'patient')),
                RecordColumn('Payment', width: 120, cell: (r) => CellText(humanize('${r['payment_type'] ?? ''}'))),
                RecordColumn('Created', width: 160, cell: (r) => dateCell(r['created_at'])),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Pharmacies',
            subtitle: 'Most overdue first. In progress, overdue, awaiting response and awaiting collection are '
                'counts right now; the rest cover the period.',
            child: PagedRecordList(
              resource: AdminResource.orderTrackingPharmacies,
              listKey: 'pharmacies',
              noun: 'pharmacies',
              filters: period,
              columns: [
                RecordColumn('Pharmacy', width: 220,
                    cell: (r) => CellText(formatValue(r['pharmacy_name']),
                        strong: true, subtitle: r['pharmacy_email']?.toString())),
                RecordColumn('In progress', width: 95, cell: (r) => _count(r['active'])),
                RecordColumn('Overdue', width: 85, cell: (r) => _count(r['overdue'], danger: true)),
                RecordColumn('Not yet accepted', width: 125, cell: (r) => _count(r['awaiting_response'])),
                RecordColumn('Ready, not collected', width: 145, cell: (r) => _count(r['awaiting_collection'])),
                RecordColumn('Created', width: 85, cell: (r) => _count(r['created'])),
                RecordColumn('Collected', width: 85, cell: (r) => _count(r['picked_up'])),
                RecordColumn('Cancelled', width: 85, cell: (r) => _count(r['cancelled'])),
                RecordColumn('Rejected', width: 85, cell: (r) => _count(r['rejected'])),
                RecordColumn('Avg time to accept', width: 135, cell: (r) => CellText(formatHours(r['avg_hours_to_accept']))),
                RecordColumn('Avg accept → ready', width: 140,
                    cell: (r) => CellText(formatHours(r['avg_hours_accept_to_ready']))),
              ],
            ),
          ),
        ])),
      ),
    );
  }
}

Widget _count(dynamic value, {bool danger = false}) {
  final n = numOf(value) ?? 0;
  return Text(formatNumber(n),
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: danger && n > 0 ? AppColors.danger : AppColors.textPrimary));
}

class _Stats extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String? waitingOn;
  final ValueChanged<String> onWaitingOn;

  const _Stats({required this.stats, required this.waitingOn, required this.onWaitingOn});

  static const _icons = {
    'pharmacy': Icons.local_pharmacy_outlined,
    'medical_aid': Icons.health_and_safety_outlined,
    'patient': Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final active = mapOf(stats['active']);
    final byWaiting = mapOf(active['by_waiting_on']);
    final byStatus = mapOf(active['by_status']);
    final p = mapOf(stats['period']);
    final avg = mapOf(p['avg_hours']);
    String n(dynamic v) => formatNumber(numOf(v) ?? 0);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StatGrid(stats: [
        StatCardData(
          label: 'In progress · ${n(active['overdue'])} overdue',
          value: n(active['total']),
          icon: Icons.local_shipping_outlined,
        ),
        for (final w in TrackingScreen.waitingOn)
          StatCardData(
            label: 'Waiting on ${waitingOnLabel(w).toLowerCase()} · ${n(mapOf(byWaiting[w])['overdue'])} overdue',
            value: n(mapOf(byWaiting[w])['count']),
            icon: _icons[w]!,
            actionLabel: 'Show overdue orders waiting on ${waitingOnLabel(w).toLowerCase()}',
            onAction: () => onWaitingOn(w),
            selected: waitingOn == w,
          ),
      ]),
      const SizedBox(height: 18),
      LayoutBuilder(builder: (context, c) {
        final stages = SectionCard(
          title: 'Orders in progress by status',
          subtitle: 'Right now, whatever the period',
          child: RecordTable(
            rows: [
              for (final s in TrackingScreen.activeStatuses) {'status': s, ...mapOf(byStatus[s])},
            ],
            columns: [
              const RecordColumn('Status', field: 'status', width: 140),
              RecordColumn('Waiting on', width: 110, cell: (r) => CellText(waitingOnLabel(r['waiting_on']))),
              RecordColumn('Orders', width: 70, cell: (r) => _count(r['count'])),
              RecordColumn('Overdue', width: 75, cell: (r) => _count(r['overdue'], danger: true)),
              RecordColumn('Longest wait', width: 105, cell: (r) => CellText(formatHours(r['longest_wait_hours']))),
              RecordColumn('Overdue after', width: 105, cell: (r) => CellText(formatHours(r['overdue_after_hours']))),
            ],
          ),
        );
        final outcomes = SectionCard(
          title: 'Orders created in the period',
          subtitle: p['from'] == null ? null : '${formatDate(p['from'])} – ${formatDate(p['to'])}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FactGrid([
              FactGrid.text('Created', n(p['created'])),
              FactGrid.text('Collected', n(p['picked_up'])),
              FactGrid.text('Cancelled', n(p['cancelled'])),
              FactGrid.text('Rejected', n(p['rejected'])),
              FactGrid.text('Still in progress', n(p['still_active'])),
              FactGrid.text('Collection rate', percent(p['collection_rate'])),
            ], tileWidth: 150),
            const SizedBox(height: 16),
            const SubHeading('Average time per step'),
            FactGrid([
              FactGrid.text('Order → accepted', formatHours(avg['to_accept'])),
              FactGrid.text('Accepted → ready', formatHours(avg['accept_to_ready'])),
              FactGrid.text('Ready → collected', formatHours(avg['ready_to_collect'])),
              FactGrid.text('Order → collected', formatHours(avg['order_to_collect'])),
            ], tileWidth: 150),
            const SizedBox(height: 8),
            const Text('Collection rate is the share of finished orders that were collected.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ]),
        );
        if (c.maxWidth < 1100) return Column(children: [stages, const SizedBox(height: 18), outcomes]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 6, child: stages),
          const SizedBox(width: 18),
          Expanded(flex: 5, child: outcomes),
        ]);
      }),
    ]);
  }
}
