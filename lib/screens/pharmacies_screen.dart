import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../widgets/admin/account_ui.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/dashboard/stat_card.dart';
import 'account_directory.dart';

/// Every pharmacy account, from `GET /admin/pharmacies`.
class PharmaciesScreen extends StatelessWidget {
  const PharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountDirectory(
      role: 'pharmacy',
      resource: AdminResource.pharmacies,
      listKey: 'pharmacies',
      pageTitle: 'Pharmacies',
      subtitle: 'Manage pharmacy accounts and permissions',
      searchHint: 'Search pharmacies',
      searchFields: const [
        'pharmacy_name', 'first_name', 'last_name', 'email', 'phone', 'license_number', 'city', 'province',
      ],
      stats: (rows, total, filter) {
        int count(bool Function(Map<String, dynamic>) test) => rows.where(test).length;
        return [
          StatCardData(
              label: 'Total Pharmacies',
              value: '$total',
              icon: Icons.local_pharmacy_outlined,
              actionLabel: 'Show all pharmacies',
              onAction: filter.by(null),
              selected: filter.isOn(null)),
          StatCardData(
              label: 'Active Pharmacies',
              value: '${count((r) => r['status'] == 'active')}',
              icon: Icons.check_circle_outline,
              actionLabel: 'Show active pharmacies',
              onAction: filter.by('active'),
              selected: filter.isOn('active')),
          StatCardData(
              label: 'Pending Approval',
              value: '${count((r) => r['status'] == 'pending')}',
              icon: Icons.hourglass_empty,
              actionLabel: 'Show pharmacies awaiting approval',
              onAction: filter.by('pending'),
              selected: filter.isOn('pending')),
          StatCardData(
              label: 'Suspended/Blocked',
              value: '${count((r) => r['status'] == 'suspended' || r['status'] == 'blocked')}',
              icon: Icons.block_outlined,
              actionLabel: 'Show suspended and blocked pharmacies',
              onAction: filter.by('suspended'),
              selected: filter.isOn('suspended')),
          StatCardData(
              label: 'Email not verified',
              value: '${count((r) => r['email_verified'] == false)}',
              icon: Icons.mark_email_unread_outlined),
        ];
      },
      columns: (open) => [
        RecordColumn('Pharmacy',
            width: 240,
            cell: (r) => AccountNameCell(
                row: r, subtitle: r['license_number']?.toString(), onTap: () => open(r))),
        RecordColumn('Owner / Contact',
            width: 170,
            cell: (r) => CellText(personName(r), subtitle: r['phone']?.toString())),
        const RecordColumn('Email', field: 'email', width: 210),
        RecordColumn('Location',
            width: 170,
            cell: (r) => CellText(formatValue(r['city']), subtitle: r['province']?.toString())),
        RecordColumn('Service',
            width: 150,
            cell: (r) {
              final radius = numOf(r['delivery_radius']);
              return CellText(
                r['is_24_hours'] == true ? 'Open 24 hours' : 'Regular hours',
                subtitle: r['delivery_available'] == true
                    ? (radius == null ? 'Delivers' : 'Delivers within ${formatNumber(radius)} km')
                    : 'No delivery',
              );
            }),
        RecordColumn('Joined On', width: 120, cell: (r) => CellText(formatDate(r['created_at']))),
        const RecordColumn('Status', field: 'status', width: 110),
      ],
    );
  }
}
