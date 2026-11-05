import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../../theme/app_colors.dart';
import '../admin/admin_format.dart';
import '../admin/admin_ui.dart';

/// Registered accounts by type, from the dashboard summary's `counts`.
class SystemDistributionCard extends StatelessWidget {
  const SystemDistributionCard({super.key});

  static const _segments = [
    ('doctors', 'Doctors', AppColors.chartTealDark),
    ('pharmacies', 'Pharmacies', AppColors.chartTealLight),
    ('patients', 'Patients', AppColors.chartTealPale),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: AdminResourceBuilder(
        resource: AdminResource.dashboardSummary,
        load: const {},
        builder: (context, data) {
          final counts = mapOf(mapOf(data.data)['counts']);
          double value(String key) => (numOf(counts[key]) ?? 0).toDouble();
          final total = numOf(counts['total_users']) ??
              _segments.fold<double>(0, (t, s) => t + value(s.$1));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Distribution',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: total > 0 ? 3 : 0,
                        centerSpaceRadius: 60,
                        sections: total > 0
                            ? [
                                for (final (key, _, color) in _segments)
                                  if (value(key) > 0)
                                    PieChartSectionData(
                                        value: value(key), color: color, radius: 26, showTitle: false),
                              ]
                            : [
                                // An empty ring until there is data.
                                PieChartSectionData(
                                    value: 1, color: AppColors.divider, radius: 26, showTitle: false),
                              ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.hasData ? formatCompact(total) : (data.hasError ? '—' : '…'),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const Text('Total Users',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (key, label, color) in _segments)
                    _LegendDot(
                      color: color,
                      label: data.hasData ? '$label ${formatCompact(value(key))}' : label,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }
}
