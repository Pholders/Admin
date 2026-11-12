import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../../theme/app_colors.dart';
import 'admin_format.dart';
import 'admin_ui.dart';
import 'records_ui.dart';

/// Detail dialogs for the view-only records. Each fetches its record as it
/// opens and links to the records it references, which open on top.
///
/// The backend never sends clinical text, ID or medical-aid numbers,
/// signatures or QR tokens, so none of these dialogs has a place for them.

/// Badge colours the backend team suggests for a prescription's `state`.
const prescriptionStateColors = <String, Color>{
  'pending': Color(0xFF8A97A0),
  'active': Color(0xFF1FA97C),
  'dispensed': Color(0xFF2F80ED),
  'revoked': AppColors.danger,
};

Widget prescriptionStateBadge(dynamic state) =>
    statusBadge(state, color: prescriptionStateColors['$state']);

Future<void> showOrderDetail(BuildContext context, Object id,
        {Map<String, dynamic> row = const {}}) =>
    showAdminDetail(context, (_) => _OrderDetail(id: id, row: row));

Future<void> showPaymentDetail(BuildContext context, Object id,
        {Map<String, dynamic> row = const {}}) =>
    showAdminDetail(context, (_) => _PaymentDetail(id: id, row: row));

Future<void> showAppointmentDetail(BuildContext context, Object id,
        {Map<String, dynamic> row = const {}}) =>
    showAdminDetail(context, (_) => _AppointmentDetail(id: id, row: row));

/// Every open is written to the audit log with the admin's name, so this is
/// only ever called from an explicit click.
Future<void> showPrescriptionDetail(BuildContext context, Object id,
        {Map<String, dynamic> row = const {}}) =>
    showAdminDetail(context, (_) => _PrescriptionDetail(id: id, row: row));

String _person(Map<String, dynamic> r, String prefix) {
  final name = r['${prefix}_name'];
  final id = r['${prefix}_id'];
  if (name == null && id == null) return '—';
  return [if (name != null) '$name', if (id != null) '#$id'].join(' ');
}

Widget _section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SubHeading(title),
        child,
      ]),
    );

// ─── Order ────────────────────────────────────────────────────────────────────

class _OrderDetail extends StatelessWidget {
  final Object id;
  final Map<String, dynamic> row;
  const _OrderDetail({required this.id, required this.row});

  @override
  Widget build(BuildContext context) {
    return RecordDetailLoader(
      kind: AdminRecordKind.order,
      id: id,
      row: row,
      builder: (context, s) {
        final r = s.record;
        final rxId = r['prescription_id'];
        return AdminDialog(
          title: 'Order #$id',
          subtitle: [r['pharmacy_name'], r['patient_name']].whereType<Object>().join(' · '),
          width: 820,
          actions: [PrimaryButton(label: 'Done', onPressed: () => closeAdminDetail(context))],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            s.statusBar,
            FactGrid([
              ('Status', statusBadge(r['status'])),
              FactGrid.text('Payment type', humanize('${r['payment_type'] ?? ''}')),
              FactGrid.text('Fulfilment', humanize('${r['fulfillment_type'] ?? ''}')),
              FactGrid.text('Total', formatRand(r['total_amount'])),
              FactGrid.text('Patient pays', formatRand(r['patient_responsibility'])),
              if (r['restocking_fee_amount'] != null)
                FactGrid.text('Restocking fee', formatRand(r['restocking_fee_amount'])),
              FactGrid.text('Patient', _person(r, 'patient')),
              FactGrid.text('Patient email', r['patient_email']),
              FactGrid.text('Pharmacy', _person(r, 'pharmacy')),
              (
                'Prescription',
                RecordLink(
                  '${r['prescription_number'] ?? (rxId == null ? '—' : '#$rxId')}',
                  onTap: rxId == null ? null : () => showPrescriptionDetail(context, rxId),
                ),
              ),
              if (r['payment_id'] != null)
                ('Payment', RecordLink('#${r['payment_id']}',
                    onTap: () => showPaymentDetail(context, r['payment_id']))),
              if (r['stripe_payment_intent_id'] != null)
                FactGrid.text('Stripe payment intent', r['stripe_payment_intent_id']),
              FactGrid.text('Created', formatDate(r['created_at'], withTime: true)),
              FactGrid.text('Accepted', formatDate(r['accepted_at'], withTime: true)),
              FactGrid.text('Prepared', formatDate(r['prepared_at'], withTime: true)),
              FactGrid.text('Ready', formatDate(r['ready_at'], withTime: true)),
              FactGrid.text('Completed', formatDate(r['completed_at'], withTime: true)),
              if (r['cancelled_at'] != null)
                FactGrid.text('Cancelled', formatDate(r['cancelled_at'], withTime: true)),
            ]),
            for (final (label, key) in const [
              ('Pharmacy notes', 'pharmacy_notes'),
              ('Cancellation reason', 'cancellation_reason'),
              ('Rejection reason', 'rejection_reason'),
            ])
              if ('${r[key] ?? ''}'.trim().isNotEmpty) _section(label, PlainTextBlock('${r[key]}')),
            if (r['status_history'] is List)
              _section('Status history', _StatusTimeline(recordsOf(r['status_history']))),
          ]),
        );
      },
    );
  }
}

/// `status_history` arrives oldest first, which is the order it reads in.
class _StatusTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  const _StatusTimeline(this.events);

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const EmptyState(message: 'No status changes recorded.');
    return Column(children: [
      for (var i = 0; i < events.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 22,
              child: Column(children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
                if (i < events.length - 1)
                  Expanded(child: Container(width: 2, color: AppColors.divider)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (events[i]['from_status'] != null) ...[
                      statusBadge(events[i]['from_status']),
                      const Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary),
                    ],
                    statusBadge(events[i]['to_status']),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    [
                      formatDate(events[i]['created_at'], withTime: true),
                      if (events[i]['actor_type'] != null)
                        'by ${events[i]['actor_type']}${events[i]['actor_id'] == null ? '' : ' #${events[i]['actor_id']}'}',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  if ('${events[i]['notes'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('${events[i]['notes']}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                  ],
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

// ─── Payment ──────────────────────────────────────────────────────────────────

class _PaymentDetail extends StatelessWidget {
  final Object id;
  final Map<String, dynamic> row;
  const _PaymentDetail({required this.id, required this.row});

  @override
  Widget build(BuildContext context) {
    return RecordDetailLoader(
      kind: AdminRecordKind.payment,
      id: id,
      row: row,
      builder: (context, s) {
        final r = s.record;
        final apptId = r['appointment_id'];
        return AdminDialog(
          title: 'Payment #$id',
          subtitle: formatRand(r['amount']),
          width: 760,
          actions: [PrimaryButton(label: 'Done', onPressed: () => closeAdminDetail(context))],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            s.statusBar,
            FactGrid([
              ('Status', statusBadge(r['payment_status'])),
              FactGrid.text('Amount', formatRand(r['amount'])),
              FactGrid.text('Method', humanize('${r['payment_method'] ?? ''}')),
              if (r['medical_aid_provider'] != null)
                FactGrid.text('Medical aid', r['medical_aid_provider']),
              FactGrid.text('Patient', _person(r, 'patient')),
              FactGrid.text('Patient email', r['patient_email']),
              FactGrid.text('Doctor', _person(r, 'doctor')),
              ('Appointment', RecordLink(apptId == null ? '—' : '#$apptId',
                  onTap: apptId == null ? null : () => showAppointmentDetail(context, apptId))),
              FactGrid.text('Stripe payment intent', r['stripe_payment_intent_id']),
              FactGrid.text('Stripe transaction', r['stripe_transaction_id']),
              FactGrid.text('Created', formatDate(r['created_at'], withTime: true)),
              FactGrid.text('Updated', formatDate(r['updated_at'], withTime: true)),
            ]),
            if ('${r['receipt_url'] ?? ''}'.isNotEmpty)
              _section('Receipt', SelectableText('${r['receipt_url']}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.primaryDark))),
            if ('${r['notes'] ?? ''}'.trim().isNotEmpty) _section('Notes', PlainTextBlock('${r['notes']}')),
          ]),
        );
      },
    );
  }
}

// ─── Appointment ──────────────────────────────────────────────────────────────

class _AppointmentDetail extends StatelessWidget {
  final Object id;
  final Map<String, dynamic> row;
  const _AppointmentDetail({required this.id, required this.row});

  @override
  Widget build(BuildContext context) {
    return RecordDetailLoader(
      kind: AdminRecordKind.appointment,
      id: id,
      row: row,
      builder: (context, s) {
        final r = s.record;
        final payments = recordsOf(r['payments']);
        final prescriptions = recordsOf(r['prescriptions']);
        return AdminDialog(
          title: 'Appointment #$id',
          subtitle: appointmentWhen(r),
          width: 820,
          actions: [PrimaryButton(label: 'Done', onPressed: () => closeAdminDetail(context))],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            s.statusBar,
            FactGrid([
              ('Status', statusBadge(r['status'])),
              FactGrid.text('When', appointmentWhen(r)),
              FactGrid.text('Patient', _person(r, 'patient')),
              FactGrid.text('Patient email', r['patient_email']),
              FactGrid.text('Doctor', _person(r, 'doctor')),
              FactGrid.text('Doctor accepted', r['doctor_accepted'] == null
                  ? null
                  : r['doctor_accepted'] == true
                      ? 'Yes, ${formatDate(r['doctor_accepted_at'], withTime: true)}'
                      : 'No'),
              FactGrid.text('Consultation fee', formatRand(r['consultation_fee'])),
              ('Payment status', statusBadge(r['payment_status'])),
              FactGrid.text('Payment method', humanize('${r['payment_method'] ?? ''}')),
              FactGrid.text('Booked', formatDate(r['created_at'], withTime: true)),
              FactGrid.text('Updated', formatDate(r['updated_at'], withTime: true)),
            ]),
            if (r.containsKey('payments'))
              _section(
                'Payments',
                RecordTable(
                  rows: payments,
                  emptyMessage: 'No payments for this appointment.',
                  onRowTap: (p) => showPaymentDetail(context, p['id'], row: p),
                  columns: [
                    RecordColumn('Payment', width: 100, cell: (p) => CellText('#${p['id']}', strong: true)),
                    RecordColumn('Amount', width: 110, cell: (p) => CellText(formatRand(p['amount']))),
                    RecordColumn('Method', width: 140, cell: (p) => CellText(humanize('${p['payment_method'] ?? ''}'))),
                    const RecordColumn('Status', field: 'payment_status', width: 130),
                    RecordColumn('Created', width: 160, cell: (p) => dateCell(p['created_at'])),
                  ],
                ),
              ),
            if (r.containsKey('prescriptions'))
              _section(
                'Prescriptions',
                RecordTable(
                  rows: prescriptions,
                  emptyMessage: 'No prescriptions from this appointment.',
                  // Opening one is audit-logged; it happens on the click only.
                  onRowTap: (p) => showPrescriptionDetail(context, p['id'], row: p),
                  columns: [
                    RecordColumn('Prescription', width: 180,
                        cell: (p) => CellText('${p['prescription_number'] ?? '#${p['id']}'}', strong: true)),
                    const RecordColumn('Signature', field: 'signature_status', width: 130),
                    RecordColumn('Created', width: 160, cell: (p) => dateCell(p['created_at'])),
                  ],
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// `"12 Nov 2026 · Morning, 09:30"`. `appointment_date` is a plain date and is
/// shown as-is, with no time-zone shift.
String appointmentWhen(Map<String, dynamic> r) => [
      formatDate(r['appointment_date']),
      [
        if (r['time_period'] != null) humanize('${r['time_period']}'),
        if (r['time_slot'] != null) '${r['time_slot']}',
      ].join(', '),
    ].where((s) => s.isNotEmpty && s != '—').join(' · ');

// ─── Prescription ─────────────────────────────────────────────────────────────

class _PrescriptionDetail extends StatelessWidget {
  final Object id;
  final Map<String, dynamic> row;
  const _PrescriptionDetail({required this.id, required this.row});

  @override
  Widget build(BuildContext context) {
    return RecordDetailLoader(
      kind: AdminRecordKind.prescription,
      id: id,
      row: row,
      builder: (context, s) {
        final r = s.record;
        final apptId = r['appointment_id'];
        final claimedBy = r['claimed_by_pharmacy_name'] ?? r['claimed_by_pharmacy_id'];
        final dispensedBy = r['dispensed_by_pharmacy_name'] ?? r['dispensed_by_pharmacy_id'];
        return AdminDialog(
          title: '${r['prescription_number'] ?? 'Prescription #$id'}',
          subtitle: 'Opening a prescription is recorded in the audit log under your name',
          width: 820,
          actions: [PrimaryButton(label: 'Done', onPressed: () => closeAdminDetail(context))],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            s.statusBar,
            FactGrid([
              ('State', prescriptionStateBadge(r['state'])),
              ('Signature', statusBadge(r['signature_status'])),
              FactGrid.text('Medicines', r['item_count']),
              FactGrid.text('Patient', _person(r, 'patient')),
              FactGrid.text('Doctor', _person(r, 'doctor')),
              ('Appointment', RecordLink(apptId == null ? '—' : '#$apptId',
                  onTap: apptId == null ? null : () => showAppointmentDetail(context, apptId))),
              FactGrid.text('Signed', formatDate(r['signed_at'], withTime: true)),
              FactGrid.text('Created', formatDate(r['created_at'], withTime: true)),
              FactGrid.text('Claimed', r['claimed'] == true
                  ? '${claimedBy ?? 'Yes'}, ${formatDate(r['claimed_at'], withTime: true)}'
                  : 'No'),
              if (r['claimed'] == true)
                FactGrid.text('Claim expires', formatDate(r['claim_expires_at'], withTime: true)),
              FactGrid.text('Dispensed', r['is_dispensed'] == true
                  ? [if (dispensedBy != null) '$dispensedBy', formatDate(r['dispensed_at'], withTime: true)].join(', ')
                  : 'No'),
              if (r['is_revoked'] == true)
                FactGrid.text('Revoked', formatDate(r['revoked_at'], withTime: true)),
            ]),
            if (r['is_revoked'] == true && '${r['revoke_reason'] ?? ''}'.trim().isNotEmpty)
              _section('Revoke reason', PlainTextBlock('${r['revoke_reason']}')),
            if (r.containsKey('orders'))
              _section(
                'Orders',
                RecordTable(
                  rows: recordsOf(r['orders']),
                  emptyMessage: 'No orders for this prescription.',
                  onRowTap: (o) => showOrderDetail(context, o['id'], row: o),
                  columns: [
                    RecordColumn('Order', width: 90, cell: (o) => CellText('#${o['id']}', strong: true)),
                    const RecordColumn('Status', field: 'status', width: 140),
                    RecordColumn('Pharmacy', width: 220, cell: (o) => personCell(o, 'pharmacy')),
                    RecordColumn('Created', width: 160, cell: (o) => dateCell(o['created_at'])),
                  ],
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// Plain text from users or staff, shown as written: line breaks kept, never
/// interpreted as markup.
class PlainTextBlock extends StatelessWidget {
  final String text;
  const PlainTextBlock(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.contentBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(text,
          style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
    );
  }
}
