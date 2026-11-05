import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../../theme/app_colors.dart';
import '../admin/admin_format.dart';
import '../admin/admin_ui.dart';

/// Prescriptions and orders created per day, month or year, from
/// `GET /admin/dashboard/activity`. The server returns every bucket, empty
/// ones as 0.
class ActivityTrendCard extends StatefulWidget {
  const ActivityTrendCard({super.key});

  @override
  State<ActivityTrendCard> createState() => _ActivityTrendCardState();
}

class _ActivityTrendCardState extends State<ActivityTrendCard> {
  static const _ranges = ['daily', 'monthly', 'yearly'];
  String _range = 'monthly';

  void _select(int i) {
    setState(() => _range = _ranges[i]);
    loadAdmin(context, AdminResource.dashboardActivity, params: {'range': _range});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Activity Trend',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              _RangeToggle(selectedIndex: _ranges.indexOf(_range), onChanged: _select),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: AdminResourceBuilder(
              resource: AdminResource.dashboardActivity,
              load: {'range': _range},
              builder: (context, data) {
                if (!data.hasData) {
                  return Center(
                    child: data.hasError
                        ? ErrorPanel(
                            message: data.error!,
                            onRetry: () => reloadAdmin(context, AdminResource.dashboardActivity))
                        : const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
                  );
                }
                return _Chart(
                  buckets: recordsOf(mapOf(data.data)['buckets']),
                  range: _range,
                  reloading: data.isLoading,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.chartTealDark, label: 'Prescriptions'),
              SizedBox(width: 20),
              _LegendDot(color: AppColors.chartTealLight, label: 'Orders'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<Map<String, dynamic>> buckets;
  final String range;
  final bool reloading;

  const _Chart({required this.buckets, required this.range, required this.reloading});

  /// A round axis step giving about four gridlines: 1, 2, 5, 10, 20, 50…
  static double _step(double max) {
    if (max <= 4) return 1;
    final raw = max / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 5, 10]) {
      if (m * magnitude >= raw) return m * magnitude;
    }
    return 10 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = [for (final b in buckets) (numOf(b['prescriptions']) ?? 0).toDouble()];
    final orders = [for (final b in buckets) (numOf(b['orders']) ?? 0).toDouble()];
    final peak = [for (var i = 0; i < buckets.length; i++) prescriptions[i] + orders[i]]
        .fold<double>(0, math.max);
    final step = _step(peak);
    final maxY = math.max(step * 4, (peak / step).ceil() * step);

    // Thirty daily labels don't fit; show every fifth day plus today.
    bool showLabel(int i) =>
        range != 'daily' || i % 5 == 0 || i == buckets.length - 1;
    final barWidth = switch (range) { 'daily' => 6.0, 'yearly' => 26.0, _ => 14.0 };

    return Stack(
      children: [
        BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: step,
              getDrawingHorizontalLine: (v) => const FlLine(color: AppColors.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.chipBlack,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final i = group.x;
                  return BarTooltipItem(
                    '${buckets[i]['label']}\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    children: [
                      TextSpan(
                        text: 'Prescriptions: ${formatNumber(prescriptions[i])}\n'
                            'Orders: ${formatNumber(orders[i])}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 11.5),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: step,
                  getTitlesWidget: (value, meta) => Text(
                    formatCompact(value),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= buckets.length || !showLabel(i)) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${buckets[i]['label']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < buckets.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: prescriptions[i] + orders[i],
                      width: barWidth,
                      color: AppColors.chartTealPale,
                      borderRadius: BorderRadius.circular(4),
                      rodStackItems: [
                        BarChartRodStackItem(0, orders[i], AppColors.chartTealLight),
                        BarChartRodStackItem(orders[i], orders[i] + prescriptions[i], AppColors.chartTealDark),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (peak == 0)
          const Center(
            child: Text('No prescriptions or orders in this period',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
        if (reloading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
                minHeight: 2, color: AppColors.primary, backgroundColor: AppColors.activeNavBackground),
          ),
      ],
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _RangeToggle({required this.selectedIndex, required this.onChanged});

  static const _labels = ['Daily', 'Monthly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: i == selectedIndex ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: i == selectedIndex ? Colors.white : AppColors.textSecondary,
                    fontWeight: i == selectedIndex ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
      ],
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
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
