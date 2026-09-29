import 'package:flutter/material.dart';
import '../models/prescription_order.dart';
import '../theme/app_colors.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/table_cell.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  String _query = '';

  final List<PrescriptionOrder> _orders = [
    PrescriptionOrder(orderId: 'RX00001', patient: 'John Doe', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Completed', total: 450.00),
    PrescriptionOrder(orderId: 'RX00002', patient: 'Maria Garcia', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Completed', total: 320.00),
    PrescriptionOrder(orderId: 'RX00003', patient: 'Elaina Johnson', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Processing', total: 230.00),
    PrescriptionOrder(orderId: 'RX00004', patient: 'Maria Wilson', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Completed', total: 150.00),
    PrescriptionOrder(orderId: 'RX00005', patient: 'Maria Wilson', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Completed', total: 410.00),
    PrescriptionOrder(orderId: 'RX00006', patient: 'Maria Wilson', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Cancelled', total: 390.00),
    PrescriptionOrder(orderId: 'RX00007', patient: 'Maria Wilson', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Completed', total: 410.00),
    PrescriptionOrder(orderId: 'RX00008', patient: 'Maria Wilson', doctor: 'Dr. Sarah Johnson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', status: 'Processing', total: 400.00),
  ];

  List<PrescriptionOrder> get _filtered {
    if (_query.trim().isEmpty) return _orders;
    final q = _query.toLowerCase();
    return _orders.where((o) =>
        o.orderId.toLowerCase().contains(q) ||
        o.patient.toLowerCase().contains(q) ||
        o.doctor.toLowerCase().contains(q) ||
        o.pharmacy.toLowerCase().contains(q)).toList();
  }

  int _countWhere(String status) => _orders.where((o) => o.status == status).length;

  void _setStatus(PrescriptionOrder order, String status) {
    setState(() => order.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.orderId} marked as $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Prescriptions',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: kTableActionMenuClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'All Orders',
              subtitle: 'View and manage all prescription orders',
              searchHint: 'Search orders...',
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),
            _StatsRow(
              total: _orders.length,
              completed: _countWhere('Completed'),
              processing: _countWhere('Processing'),
              cancelled: _countWhere('Cancelled'),
              returned: 82,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ScrollableTable(
                minWidth: 1020,
                header: Row(
                  children: const [
                    AppTableHeaderCell(label: 'Order ID', width: 120),
                    AppTableHeaderCell(label: 'Patient', width: 140),
                    AppTableHeaderCell(label: 'Doctor', width: 170),
                    AppTableHeaderCell(label: 'Pharmacy', width: 180),
                    AppTableHeaderCell(label: 'Date', width: 130),
                    AppTableHeaderCell(label: 'Status', width: 120),
                    AppTableHeaderCell(label: 'Total', width: 90),
                    AppTableHeaderCell(label: '', width: 48),
                  ],
                ),
                rows: [
                  for (final order in _filtered) _OrderRow(order: order, onStatusChange: _setStatus),
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No orders match your search.', style: TextStyle(color: AppColors.textSecondary)),
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

class _StatsRow extends StatelessWidget {
  final int total;
  final int completed;
  final int processing;
  final int cancelled;
  final int returned;

  const _StatsRow({
    required this.total,
    required this.completed,
    required this.processing,
    required this.cancelled,
    required this.returned,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(label: 'Total Orders', value: '$total', icon: Icons.receipt_long_outlined),
      StatCardData(label: 'Completed', value: '$completed', icon: Icons.check_circle_outline),
      StatCardData(label: 'Processing', value: '$processing', icon: Icons.autorenew),
      StatCardData(label: 'Cancelled', value: '$cancelled', icon: Icons.cancel_outlined),
      StatCardData(label: 'Returned', value: '$returned', icon: Icons.assignment_return_outlined),
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

class _OrderRow extends StatelessWidget {
  final PrescriptionOrder order;
  final void Function(PrescriptionOrder, String) onStatusChange;

  const _OrderRow({required this.order, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTableCell(width: 120, child: Text(order.orderId, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
        AppTableCell(width: 140, child: Text(order.patient, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 170, child: Text(order.doctor, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 180, child: Text(order.pharmacy, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 130, child: Text(order.date, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(width: 120, child: StatusBadge(status: order.status)),
        AppTableCell(width: 90, child: Text('R${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
        AppTableCell(
          width: 48,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View details')),
              if (order.status != 'Completed') const PopupMenuItem(value: 'Completed', child: Text('Mark Completed')),
              if (order.status != 'Processing') const PopupMenuItem(value: 'Processing', child: Text('Mark Processing')),
              if (order.status != 'Cancelled') const PopupMenuItem(value: 'Cancelled', child: Text('Cancel order')),
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
        ),
      ],
    );
  }
}
