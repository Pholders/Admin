import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';

/// Every prescription, from `GET /admin/prescriptions`. The backend sends no
/// medicine names or clinical text; opening one is audit-logged.
class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RecordListScreen(
      currentPage: 'Prescriptions',
      title: 'Prescriptions',
      subtitle: 'Every prescription and where it is in its life, newest first',
      note: 'View-only. Opening a prescription is recorded in the audit log under your name.',
      resource: AdminResource.prescriptions,
      listKey: 'prescriptions',
      noun: 'prescriptions',
      filters: const [
        ChoiceFilter('state', 'State', [
          ('pending', 'Pending (not signed)'),
          ('active', 'Active'),
          ('dispensed', 'Dispensed'),
          ('revoked', 'Revoked'),
        ], width: 200),
        IdFilter('doctor_id', 'Doctor ID'),
        IdFilter('patient_id', 'Patient ID'),
        DateRangeFilter('Created'),
      ],
      // Only a click opens one: that open is what the audit log records.
      onRowTap: (context, r) => showPrescriptionDetail(context, r['id'], row: r),
      columns: (_) => [
        RecordColumn('Prescription', width: 170,
            cell: (r) => CellText('${r['prescription_number'] ?? '#${r['id']}'}', strong: true)),
        RecordColumn('State', width: 120, cell: (r) => prescriptionStateBadge(r['state'])),
        RecordColumn('Patient', width: 180, cell: (r) => personCell(r, 'patient')),
        RecordColumn('Doctor', width: 180, cell: (r) => personCell(r, 'doctor')),
        RecordColumn('Medicines', width: 100, cell: (r) => CellText(formatValue(r['item_count']))),
        RecordColumn('Claimed by', width: 200,
            cell: (r) => r['claimed'] == true
                ? CellText(formatValue(r['claimed_by_pharmacy_name'] ?? r['claimed_by_pharmacy_id']),
                    subtitle: r['claim_expires_at'] == null
                        ? null
                        : 'Until ${formatDate(r['claim_expires_at'], withTime: true)}')
                : const CellText('—')),
        RecordColumn('Created', width: 160, cell: (r) => dateCell(r['created_at'])),
      ],
    );
  }
}
