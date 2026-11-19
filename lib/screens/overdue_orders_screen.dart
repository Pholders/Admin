import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';
import 'tracking_screen.dart';

/// Orders stuck in the pickup flow: `GET /admin/orders?overdue=true&sort=longest_waiting`.
/// An order is overdue once it has sat in its status longer than the backend
/// allows for that status. Shares its store slot (and first page) with the
/// overdue list on the Tracking page.
class OverdueOrdersScreen extends StatelessWidget {
  const OverdueOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RecordListScreen(
      currentPage: 'Overdue Orders',
      title: 'Overdue Orders',
      subtitle: 'Orders that have waited too long in their status, longest waiting first',
      note: 'Each status has its own time limit, set on the backend; "Overdue after" shows it for each order. '
          'Orders are view-only here.',
      resource: AdminResource.overdueOrders,
      listKey: 'orders',
      noun: 'overdue orders',
      fixedFilters: TrackingScreen.overdueParams,
      filters: [
        ChoiceFilter('waiting_on', 'Waiting on',
            [for (final w in TrackingScreen.waitingOn) (w, waitingOnLabel(w))],
            width: 150),
        ChoiceFilter.values('status', 'Status', TrackingScreen.activeStatuses),
        ChoiceFilter.values('payment_type', 'Payment type', const ['cash', 'medical_aid']),
        const IdFilter('pharmacy_id', 'Pharmacy ID'),
        const IdFilter('patient_id', 'Patient ID'),
        const DateRangeFilter('Created'),
      ],
      onRowTap: (context, r) => showOrderDetail(context, r['id'], row: r),
      columns: (_) => [
        RecordColumn('Order', width: 90, cell: (r) => CellText('#${r['id']}', strong: true)),
        const RecordColumn('Status', field: 'status', width: 140),
        RecordColumn('Waiting', width: 170, cell: (r) => OrderWaitCell(r)),
        RecordColumn('Overdue after', width: 110, cell: (r) => CellText(formatHours(r['overdue_after_hours']))),
        RecordColumn('In status since', width: 160, cell: (r) => dateCell(r['status_since'])),
        RecordColumn('Pharmacy', width: 200, cell: (r) => personCell(r, 'pharmacy')),
        RecordColumn('Patient', width: 190, cell: (r) => personCell(r, 'patient')),
        RecordColumn('Payment', width: 120, cell: (r) => CellText(humanize('${r['payment_type'] ?? ''}'))),
        RecordColumn('Total', width: 110, cell: (r) => CellText(formatRand(r['total_amount']))),
      ],
    );
  }
}
