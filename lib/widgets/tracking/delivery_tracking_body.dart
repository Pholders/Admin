import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../../models/tracking_order.dart';
import '../../theme/app_colors.dart';
import '../common/page_header.dart';
import '../common/status_badge.dart';
import '../common/table_cell.dart';
import '../dashboard/stat_card.dart';

/// The Tracking and Billing & Payments screens show the same delivery
/// tracking table in the Figma design, so this widget holds the real
/// search / stats / action logic once. Each screen mounts its own instance
/// (own in-memory state) — see tracking_screen.dart and
/// billing_payments_screen.dart.
class DeliveryTrackingBody extends StatefulWidget {
  final String title;
  final String subtitle;
  final String searchHint;

  const DeliveryTrackingBody({
    super.key,
    this.title = 'Tracking',
    this.subtitle = 'Track delivery status of prescription orders',
    this.searchHint = 'Search tracking',
  });

  @override
  State<DeliveryTrackingBody> createState() => _DeliveryTrackingBodyState();
}

class _DeliveryTrackingBodyState extends State<DeliveryTrackingBody> {
  String _query = '';

  final List<TrackingOrder> _orders = [
    TrackingOrder(orderId: 'RX1001246', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'FastTrack', trackingNumber: 'FT123456782A', status: 'Delivered', eta: 'Delivered'),
    TrackingOrder(orderId: 'RX1001247', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'PosX', trackingNumber: 'PX1234567892A', status: 'In Transit', eta: '2 hrs'),
    TrackingOrder(orderId: 'RX1001246', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'The Courier Guy', trackingNumber: 'CG1234567892A', status: 'Delayed', eta: '1 day'),
    TrackingOrder(orderId: 'RX1001218', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'PosX', trackingNumber: 'PX1234567892A', status: 'Out for Delivery', eta: '20 mins'),
    TrackingOrder(orderId: 'RX1001244', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'The Courier Guy', trackingNumber: 'CG1234567892A', status: 'Out for Delivery', eta: '1 hr'),
    TrackingOrder(orderId: 'RX1001212', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'The Courier Guy', trackingNumber: 'CG1234567892A', status: 'Failed Delivery', eta: '-'),
    TrackingOrder(orderId: 'RX1001205', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'The Courier Guy', trackingNumber: 'CG1234567892A', status: 'Out for Delivery', eta: '20 mins'),
    TrackingOrder(orderId: 'RX1001241', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', courier: 'FastTrack', trackingNumber: 'FT1231567892A', status: 'In Transit', eta: '1 hr'),
  ];

  List<TrackingOrder> get _filtered {
    if (_query.trim().isEmpty) return _orders;
    final q = _query.toLowerCase();
    return _orders.where((o) =>
        o.orderId.toLowerCase().contains(q) ||
        o.patient.toLowerCase().contains(q) ||
        o.pharmacy.toLowerCase().contains(q) ||
        o.courier.toLowerCase().contains(q) ||
        o.trackingNumber.toLowerCase().contains(q)).toList();
  }

  int _countWhere(String status) => _orders.where((o) => o.status == status).length;

  void _setStatus(TrackingOrder order, String status) {
    setState(() {
      order.status = status;
      if (status == 'Delivered') order.eta = 'Delivered';
      if (status == 'Failed Delivery') order.eta = '-';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.orderId} marked as $status')),
    );
  }

  Widget _table(bool pinned) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ScrollableTable(
                stickyHeader: pinned,
              minWidth: 1100,
              header: Row(
                children: const [
                  AppTableHeaderCell(label: 'Order ID', width: 120),
                  AppTableHeaderCell(label: 'Patient', width: 130),
                  AppTableHeaderCell(label: 'Pharmacy', width: 170),
                  AppTableHeaderCell(label: 'Courier', width: 130),
                  AppTableHeaderCell(label: 'Tracking No.', width: 140),
                  AppTableHeaderCell(label: 'Status', width: 140),
                  AppTableHeaderCell(label: 'ETA', width: 90),
                  AppTableHeaderCell(label: 'Actions', width: 110),
                ],
              ),
              rows: [
                for (final order in _filtered) _TrackingRow(order: order, onStatusChange: _setStatus),
                if (_filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No orders match your search.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
              ],
            ),
          );

  @override
  Widget build(BuildContext context) {
    return PinnedPage(
        header: [
          PageHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            searchHint: widget.searchHint,
            onSearchChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 20),
          _StatsRow(
            inTransit: _countWhere('In Transit'),
            outForDelivery: _countWhere('Out for Delivery'),
            delivered: _countWhere('Delivered'),
            delayed: _countWhere('Delayed'),
            failedDelivery: _countWhere('Failed Delivery'),
          ),
          const SizedBox(height: 20),
          ],
        body: (pinned) => Column(children: [
          if (pinned) Expanded(child: _table(pinned)) else _table(pinned),
        ]),
      );
  }
}

class _StatsRow extends StatelessWidget {
  final int inTransit;
  final int outForDelivery;
  final int delivered;
  final int delayed;
  final int failedDelivery;

  const _StatsRow({
    required this.inTransit,
    required this.outForDelivery,
    required this.delivered,
    required this.delayed,
    required this.failedDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(label: 'In Transit', value: '$inTransit', icon: Icons.person_outline),
      StatCardData(label: 'Out for Delivery', value: '$outForDelivery', icon: Icons.local_shipping_outlined),
      StatCardData(label: 'Delivered', value: '$delivered', icon: Icons.check_circle_outline),
      StatCardData(label: 'Delayed', value: '$delayed', icon: Icons.schedule_outlined),
      StatCardData(label: 'Failed Delivery', value: '$failedDelivery', icon: Icons.report_gmailerrorred_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final stat in stats)
              SizedBox(
                width: constraints.maxWidth > 900 ? (constraints.maxWidth - 14 * 4) / 5 : 220,
                child: StatCard(data: stat),
              ),
          ],
        );
      },
    );
  }
}

class _TrackingRow extends StatelessWidget {
  final TrackingOrder order;
  final void Function(TrackingOrder, String) onStatusChange;

  const _TrackingRow({required this.order, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTableCell(width: 120, child: Text(order.orderId, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
        AppTableCell(width: 130, child: Text(order.patient, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 170, child: Text(order.pharmacy, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 130, child: Text(order.courier, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 140, child: Text(order.trackingNumber, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 140, child: StatusBadge(status: order.status)),
        AppTableCell(width: 90, child: Text(order.eta, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(
          width: 110,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit ${order.orderId}')),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete ${order.orderId}')),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View details')),
                  if (order.status != 'In Transit') const PopupMenuItem(value: 'In Transit', child: Text('Mark In Transit')),
                  if (order.status != 'Out for Delivery') const PopupMenuItem(value: 'Out for Delivery', child: Text('Mark Out for Delivery')),
                  if (order.status != 'Delivered') const PopupMenuItem(value: 'Delivered', child: Text('Mark Delivered')),
                  if (order.status != 'Delayed') const PopupMenuItem(value: 'Delayed', child: Text('Mark Delayed')),
                  if (order.status != 'Failed Delivery') const PopupMenuItem(value: 'Failed Delivery', child: Text('Mark Failed Delivery')),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing order ${order.orderId}')),
                    );
                  } else {
                    onStatusChange(order, value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
