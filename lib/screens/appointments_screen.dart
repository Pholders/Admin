import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';

/// Every consultation booking, from `GET /admin/appointments`. View-only:
/// there is no endpoint to cancel an appointment.
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RecordListScreen(
      currentPage: 'Appointments',
      title: 'Appointments',
      subtitle: 'Consultations by appointment date, latest first',
      note: 'View-only. The date filter is the appointment date, not the booking date.',
      resource: AdminResource.appointments,
      listKey: 'appointments',
      noun: 'appointments',
      filters: [
        ChoiceFilter.values('status', 'Status',
            const ['pending_payment', 'scheduled', 'completed', 'cancelled', 'no-show', 'rescheduled']),
        ChoiceFilter.values('payment_status', 'Payment', const ['pending', 'completed', 'failed', 'cancelled']),
        const IdFilter('doctor_id', 'Doctor ID'),
        const IdFilter('patient_id', 'Patient ID'),
        const DateRangeFilter('Appointment date'),
      ],
      onRowTap: (context, r) => showAppointmentDetail(context, r['id'], row: r),
      columns: (_) => [
        RecordColumn('Appointment', width: 110, cell: (r) => CellText('#${r['id']}', strong: true)),
        // A plain date, formatted without any time-zone shift.
        RecordColumn('Date', width: 150,
            cell: (r) => CellText(formatDate(r['appointment_date']),
                strong: true,
                subtitle: [
                  if (r['time_period'] != null) humanize('${r['time_period']}'),
                  if (r['time_slot'] != null) '${r['time_slot']}',
                ].join(', '))),
        const RecordColumn('Status', field: 'status', width: 140),
        RecordColumn('Patient', width: 190, cell: (r) => personCell(r, 'patient')),
        RecordColumn('Doctor', width: 190,
            cell: (r) => CellText(formatValue(r['doctor_name']),
                strong: true,
                subtitle: switch (r['doctor_accepted']) {
                  true => 'Accepted',
                  false => 'Not accepted yet',
                  _ => null,
                })),
        RecordColumn('Fee', width: 100, cell: (r) => CellText(formatRand(r['consultation_fee']))),
        RecordColumn('Payment', width: 140,
            cell: (r) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    statusBadge(r['payment_status']),
                    if (r['payment_method'] != null)
                      Text(humanize('${r['payment_method']}'),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                )),
        RecordColumn('Booked', width: 160, cell: (r) => dateCell(r['created_at'])),
      ],
    );
  }
}
