import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../widgets/admin/account_ui.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/dashboard/stat_card.dart';
import 'account_directory.dart';

/// Every doctor account, from `GET /admin/doctors`.
class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountDirectory(
      role: 'doctor',
      resource: AdminResource.doctors,
      listKey: 'doctors',
      pageTitle: 'Doctors',
      subtitle: 'Manage doctor accounts and permissions',
      searchHint: 'Search doctors',
      searchFields: const [
        'first_name', 'last_name', 'email', 'specialization', 'hpcsa_number', 'clinic_name', 'city',
      ],
      stats: (rows, total, filter) {
        int count(bool Function(Map<String, dynamic>) test) => rows.where(test).length;
        return [
          StatCardData(
              label: 'Total Doctors',
              value: '$total',
              icon: Icons.person_outline,
              actionLabel: 'Show all doctors',
              onAction: filter.by(null),
              selected: filter.isOn(null)),
          StatCardData(
              label: 'Active Doctors',
              value: '${count((r) => r['status'] == 'active')}',
              icon: Icons.check_circle_outline,
              actionLabel: 'Show active doctors',
              onAction: filter.by('active'),
              selected: filter.isOn('active')),
          StatCardData(
              label: 'Pending Approval',
              value: '${count((r) => r['status'] == 'pending')}',
              icon: Icons.hourglass_empty,
              actionLabel: 'Show doctors awaiting approval',
              onAction: filter.by('pending'),
              selected: filter.isOn('pending')),
          StatCardData(
              label: 'Suspended/Blocked',
              value: '${count((r) => r['status'] == 'suspended' || r['status'] == 'blocked')}',
              icon: Icons.block_outlined,
              actionLabel: 'Show suspended and blocked doctors',
              onAction: filter.by('suspended'),
              selected: filter.isOn('suspended')),
          StatCardData(
              label: 'Email not verified',
              value: '${count((r) => r['email_verified'] == false)}',
              icon: Icons.mark_email_unread_outlined),
        ];
      },
      columns: (open) => [
        RecordColumn('Doctor',
            width: 230,
            cell: (r) => AccountNameCell(
                row: r, subtitle: r['specialization']?.toString(), onTap: () => open(r))),
        const RecordColumn('Email', field: 'email', width: 210),
        const RecordColumn('HPCSA No.', field: 'hpcsa_number', width: 120),
        RecordColumn('Practice',
            width: 190,
            cell: (r) => CellText(
                  formatValue(r['clinic_name']),
                  subtitle: [r['suburb'], r['city']]
                      .where((v) => v != null && '$v'.trim().isNotEmpty)
                      .join(', '),
                )),
        RecordColumn('Rating',
            width: 100,
            cell: (r) {
              final rating = numOf(r['rating']);
              final reviews = numOf(r['review_count']) ?? 0;
              return CellText(rating == null || reviews == 0
                  ? 'No reviews'
                  : '${formatNumber(rating, decimals: 1)} ★ (${formatNumber(reviews)})');
            }),
        RecordColumn('Joined On', width: 120, cell: (r) => CellText(formatDate(r['created_at']))),
        const RecordColumn('Status', field: 'status', width: 110),
      ],
    );
  }
}
