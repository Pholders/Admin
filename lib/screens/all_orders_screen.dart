import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';

/// Every pharmacy order, from `GET /admin/orders`. View-only: there is no
/// endpoint to cancel or change an order.
class AllOrdersScreen extends StatelessWidget {
  const AllOrdersScreen({super.key});

  static const statuses = [
    'pending', 'accepted', 'awaiting_claim', 'claim_approved', 'claim_rejected',
    'preparing', 'ready', 'picked_up', 'cancelled', 'rejected',
  ];

  @override
  Widget build(BuildContext context) {
    return RecordListScreen(
      currentPage: 'All Orders',
      title: 'All Orders',
      subtitle: 'Pharmacy orders across the platform, newest first',
      note: 'Orders are view-only here.',
      resource: AdminResource.orders,
      listKey: 'orders',
      noun: 'orders',
      filters: [
        ChoiceFilter.values('status', 'Status', statuses),
        ChoiceFilter.values('payment_type', 'Payment type', const ['cash', 'medical_aid']),
        const IdFilter('pharmacy_id', 'Pharmacy ID'),
        const IdFilter('patient_id', 'Patient ID'),
        const DateRangeFilter('Created'),
      ],
      onRowTap: (context, r) => showOrderDetail(context, r['id'], row: r),
      columns: (_) => [
        RecordColumn('Order', width: 90, cell: (r) => CellText('#${r['id']}', strong: true)),
        const RecordColumn('Status', field: 'status', width: 140),
        RecordColumn('Patient', width: 190, cell: (r) => personCell(r, 'patient')),
        RecordColumn('Pharmacy', width: 200, cell: (r) => personCell(r, 'pharmacy')),
        RecordColumn('Prescription', width: 160,
            cell: (r) => CellText(formatValue(r['prescription_number']))),
        RecordColumn('Payment', width: 120,
            cell: (r) => CellText(formatValue(humanize('${r['payment_type'] ?? ''}')),
                subtitle: r['fulfillment_type'] == null ? null : humanize('${r['fulfillment_type']}'))),
        RecordColumn('Total', width: 120,
            cell: (r) => CellText(formatRand(r['total_amount']),
                strong: true,
                subtitle: r['patient_responsibility'] == null
                    ? null
                    : 'Patient ${formatRand(r['patient_responsibility'])}')),
        RecordColumn('Created', width: 160, cell: (r) => dateCell(r['created_at'])),
      ],
    );
  }
}
