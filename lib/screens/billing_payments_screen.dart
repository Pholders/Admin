import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';
import '../widgets/dashboard/stat_card.dart';

/// Consultation payments, from `GET /admin/payments`. View-only: there is no
/// refund endpoint.
class BillingPaymentsScreen extends StatelessWidget {
  const BillingPaymentsScreen({super.key});

  static const statuses = ['completed', 'pending', 'failed', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    return RecordListScreen(
      currentPage: 'Billing & Payments',
      title: 'Billing & Payments',
      subtitle: 'Consultation payments, newest first. Amounts in ZAR.',
      note: 'Payments are view-only here; refunds are not available.',
      resource: AdminResource.payments,
      listKey: 'payments',
      noun: 'payments',
      filters: [
        ChoiceFilter.values('status', 'Status', statuses),
        ChoiceFilter.values('method', 'Method', const ['stripe', 'cash_on_arrival', 'medical_aid']),
        const IdFilter('patient_id', 'Patient ID'),
        const IdFilter('doctor_id', 'Doctor ID'),
        const DateRangeFilter('Created'),
      ],
      header: (body, _) => PaymentTotals(totals: mapOf(body['totals'])),
      onRowTap: (context, r) => showPaymentDetail(context, r['id'], row: r),
      columns: (_) => [
        RecordColumn('Payment', width: 90, cell: (r) => CellText('#${r['id']}', strong: true)),
        RecordColumn('Amount', width: 110, cell: (r) => CellText(formatRand(r['amount']), strong: true)),
        const RecordColumn('Status', field: 'payment_status', width: 120),
        RecordColumn('Method', width: 150,
            cell: (r) => CellText(formatValue(humanize('${r['payment_method'] ?? ''}')),
                subtitle: r['medical_aid_provider']?.toString())),
        RecordColumn('Patient', width: 210,
            cell: (r) => CellText(formatValue(r['patient_name']),
                strong: true, subtitle: r['patient_email']?.toString())),
        RecordColumn('Doctor', width: 180, cell: (r) => personCell(r, 'doctor')),
        RecordColumn('Appointment', width: 110,
            cell: (r) => CellText(r['appointment_id'] == null ? '—' : '#${r['appointment_id']}')),
        RecordColumn('Created', width: 160, cell: (r) => dateCell(r['created_at'])),
      ],
    );
  }
}

/// Count and amount per status over the whole filtered set, not just this
/// page. A status with no payments is missing from `by_status`; it shows 0.
class PaymentTotals extends StatelessWidget {
  final Map<String, dynamic> totals;
  const PaymentTotals({super.key, required this.totals});

  static const _icons = {
    'completed': Icons.check_circle_outline,
    'pending': Icons.hourglass_empty,
    'failed': Icons.error_outline,
    'cancelled': Icons.cancel_outlined,
  };

  StatCardData _card(String status) {
    final s = mapOf(mapOf(totals['by_status'])[status]);
    final count = numOf(s['count']) ?? 0;
    return StatCardData(
      label: '${humanize(status)} · ${formatNumber(count)}',
      value: formatRand(numOf(s['amount']) ?? 0),
      icon: _icons[status]!,
    );
  }

  @override
  Widget build(BuildContext context) => StatGrid(
      perRow: 4, stats: [for (final s in BillingPaymentsScreen.statuses) _card(s)]);
}
