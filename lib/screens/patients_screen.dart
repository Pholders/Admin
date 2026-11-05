import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/account_ui.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/dashboard/stat_card.dart';
import 'account_directory.dart';

/// Every patient account, from `GET /admin/patients`.
class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountDirectory(
      role: 'patient',
      resource: AdminResource.patients,
      listKey: 'patients',
      pageTitle: 'Patients',
      subtitle: 'Manage patient accounts and permissions',
      searchHint: 'Search patients',
      searchFields: const ['first_name', 'last_name', 'email', 'phone', 'city', 'suburb'],
      stats: (rows, total, filter) {
        final now = DateTime.now();
        final newThisMonth = rows.where((r) {
          final d = DateTime.tryParse('${r['created_at']}')?.toLocal();
          return d != null && d.year == now.year && d.month == now.month;
        }).length;
        int count(bool Function(Map<String, dynamic>) test) => rows.where(test).length;
        return [
          StatCardData(
              label: 'Total Patients',
              value: '$total',
              icon: Icons.person_outline,
              actionLabel: 'Show all patients',
              onAction: filter.by(null),
              selected: filter.isOn(null)),
          StatCardData(
              label: 'Active Patients',
              value: '${count((r) => r['status'] == 'active')}',
              icon: Icons.check_circle_outline,
              actionLabel: 'Show active patients',
              onAction: filter.by('active'),
              selected: filter.isOn('active')),
          StatCardData(label: 'New this month', value: '$newThisMonth', icon: Icons.trending_up),
          StatCardData(
              label: 'Suspended/Blocked',
              value: '${count((r) => r['status'] == 'suspended' || r['status'] == 'blocked')}',
              icon: Icons.block_outlined,
              actionLabel: 'Show suspended and blocked patients',
              onAction: filter.by('suspended'),
              selected: filter.isOn('suspended')),
          StatCardData(
              label: 'Email not verified',
              value: '${count((r) => r['email_verified'] == false)}',
              icon: Icons.mark_email_unread_outlined),
        ];
      },
      columns: (open) => [
        RecordColumn('Patient', width: 220, cell: (r) => AccountNameCell(row: r, onTap: () => open(r))),
        RecordColumn('Email',
            width: 230,
            cell: (r) => Row(children: [
                  Flexible(child: CellText(formatValue(r['email']))),
                  if (r['email_verified'] == true) ...[
                    const SizedBox(width: 4),
                    const Tooltip(
                      message: 'Email verified',
                      child: Icon(Icons.verified, size: 13, color: AppColors.primary),
                    ),
                  ],
                ])),
        const RecordColumn('Phone', field: 'phone', width: 140),
        RecordColumn('Location',
            width: 170,
            cell: (r) => CellText([r['suburb'], r['city']]
                    .where((v) => v != null && '$v'.trim().isNotEmpty)
                    .join(', ')
                    .ifEmpty('—'))),
        RecordColumn('Date Joined', width: 120, cell: (r) => CellText(formatDate(r['created_at']))),
        const RecordColumn('Status', field: 'status', width: 110),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
