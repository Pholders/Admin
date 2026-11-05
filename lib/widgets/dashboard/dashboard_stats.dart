import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../admin/admin_format.dart';
import '../admin/admin_ui.dart';
import 'stat_card.dart';

/// The dashboard's five headline figures, from `GET /admin/dashboard/summary`.
class StatCardsRow extends StatelessWidget {
  const StatCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.dashboardSummary,
      load: const {},
      builder: (context, data) {
        final summary = mapOf(data.data);
        final counts = mapOf(summary['counts']);
        final revenue = mapOf(summary['revenue']);
        final placeholder = data.hasError ? '—' : '…';
        String count(String key) =>
            data.hasData ? formatNumber(numOf(counts[key]) ?? 0) : placeholder;
        void go(String route) =>
            StoreProvider.of<AppState>(context, listen: false).dispatch(NavigateToAction(route));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.hasError) ...[
              ErrorPanel(
                message: 'Dashboard figures could not be loaded: ${data.error}',
                compact: true,
                onRetry: () => reloadAdmin(context, AdminResource.dashboardSummary),
              ),
              const SizedBox(height: 14),
            ],
            StatGrid(perRow: 5, stats: [
              StatCardData(
                  label: 'Doctors',
                  value: count('doctors'),
                  icon: Icons.person_outline,
                  actionLabel: 'Open the Doctors directory',
                  onAction: () => go('doctors')),
              StatCardData(
                  label: 'Pharmacies',
                  value: count('pharmacies'),
                  icon: Icons.local_pharmacy_outlined,
                  actionLabel: 'Open the Pharmacies directory',
                  onAction: () => go('pharmacies')),
              StatCardData(
                  label: 'Active prescriptions',
                  value: count('active_prescriptions'),
                  icon: Icons.medication_outlined),
              StatCardData(
                  label: 'Orders today', value: count('orders_today'), icon: Icons.receipt_long_outlined),
              StatCardData(
                  label: 'Revenue this month',
                  value: data.hasData ? formatRand(revenue['amount'] ?? 0) : placeholder,
                  icon: Icons.bar_chart_outlined),
            ]),
          ],
        );
      },
    );
  }
}
