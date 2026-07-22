import 'package:flutter/material.dart';
import '../models/prescription_return.dart';
import '../theme/app_colors.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/table_cell.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  String _query = '';

  final List<PrescriptionReturn> _returns = [
    PrescriptionReturn(returnId: 'RT500001', orderId: 'RX500001', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', reason: 'Damaged item', status: 'Approved', total: 460.00),
    PrescriptionReturn(returnId: 'RT500002', orderId: 'RX500002', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', reason: 'Wrong medication', status: 'Approved', total: 320.00),
    PrescriptionReturn(returnId: 'RT500003', orderId: 'RX500003', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', reason: 'Wrong dosage', status: 'Pending Review', total: 230.00),
    PrescriptionReturn(returnId: 'RT500004', orderId: 'RX500004', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', reason: 'Expired', status: 'Approved', total: 160.00),
    PrescriptionReturn(returnId: 'RT500005', orderId: 'RX500005', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', reason: 'Damaged item', status: 'Approved', total: 410.00),
    PrescriptionReturn(returnId: 'RT500006', orderId: 'RX500006', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', reason: 'Wrong package', status: 'Rejected', total: 250.00),
    PrescriptionReturn(returnId: 'RT500007', orderId: 'RX500007', patient: 'Maria Wilson', pharmacy: 'HealthPlus Pharmacy', date: '12 March 2026', reason: 'Expired', status: 'Approved', total: 410.00),
  ];

  List<PrescriptionReturn> get _filtered {
    if (_query.trim().isEmpty) return _returns;
    final q = _query.toLowerCase();
    return _returns.where((r) =>
        r.returnId.toLowerCase().contains(q) ||
        r.orderId.toLowerCase().contains(q) ||
        r.patient.toLowerCase().contains(q) ||
        r.pharmacy.toLowerCase().contains(q)).toList();
  }

  int _countWhere(String status) => _returns.where((r) => r.status == status).length;

  void _setStatus(PrescriptionReturn r, String status) {
    setState(() => r.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Return ${r.returnId} marked as $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Prescriptions',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Returns',
              subtitle: 'Manage returned prescription orders',
              searchHint: 'Search prescription',
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),
            _StatsRow(
              total: _returns.length,
              pendingReview: _countWhere('Pending Review'),
              approved: _countWhere('Approved'),
              rejected: _countWhere('Rejected'),
              returned: 19,
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
                minWidth: 1120,
                header: Row(
                  children: const [
                    AppTableHeaderCell(label: 'Return ID', width: 110),
                    AppTableHeaderCell(label: 'Order ID', width: 110),
                    AppTableHeaderCell(label: 'Patient', width: 130),
                    AppTableHeaderCell(label: 'Pharmacy', width: 170),
                    AppTableHeaderCell(label: 'Date', width: 130),
                    AppTableHeaderCell(label: 'Reason', width: 150),
                    AppTableHeaderCell(label: 'Status', width: 130),
                    AppTableHeaderCell(label: 'Total', width: 90),
                    AppTableHeaderCell(label: '', width: 48),
                  ],
                ),
                rows: [
                  for (final r in _filtered) _ReturnRow(item: r, onStatusChange: _setStatus),
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No returns match your search.', style: TextStyle(color: AppColors.textSecondary)),
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
  final int pendingReview;
  final int approved;
  final int rejected;
  final int returned;

  const _StatsRow({
    required this.total,
    required this.pendingReview,
    required this.approved,
    required this.rejected,
    required this.returned,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(label: 'Total Returns', value: '$total', icon: Icons.assignment_return_outlined),
      StatCardData(label: 'Pending Review', value: '$pendingReview', icon: Icons.hourglass_empty),
      StatCardData(label: 'Approved', value: '$approved', icon: Icons.check_circle_outline),
      StatCardData(label: 'Rejected', value: '$rejected', icon: Icons.cancel_outlined),
      StatCardData(label: 'Returned', value: '$returned', icon: Icons.receipt_long_outlined),
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

class _ReturnRow extends StatelessWidget {
  final PrescriptionReturn item;
  final void Function(PrescriptionReturn, String) onStatusChange;

  const _ReturnRow({required this.item, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTableCell(width: 110, child: Text(item.returnId, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
        AppTableCell(width: 110, child: Text(item.orderId, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(width: 130, child: Text(item.patient, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 170, child: Text(item.pharmacy, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 130, child: Text(item.date, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(width: 150, child: Text(item.reason, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 130, child: StatusBadge(status: item.status)),
        AppTableCell(width: 90, child: Text('R${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
        AppTableCell(
          width: 48,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View details')),
              if (item.status != 'Approved') const PopupMenuItem(value: 'Approved', child: Text('Approve')),
              if (item.status != 'Rejected') const PopupMenuItem(value: 'Rejected', child: Text('Reject')),
            ],
            onSelected: (value) {
              if (value == 'view') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing return ${item.returnId}')),
                );
              } else {
                onStatusChange(item, value);
              }
            },
          ),
        ),
      ],
    );
  }
}
