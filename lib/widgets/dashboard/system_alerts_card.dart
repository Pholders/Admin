import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';

import 'package:pholders_admin/store.dart';
import '../../theme/app_colors.dart';
import '../admin/admin_format.dart';
import '../admin/admin_ui.dart';

class SystemAlert {
  final String title;
  final String subtitle;
  final String? time;
  final bool active;
  final VoidCallback? onTap;

  const SystemAlert({
    required this.title,
    required this.subtitle,
    this.time,
    this.active = true,
    this.onTap,
  });
}

/// Alert tiles from the dashboard summary's `alerts`. A tile the backend
/// doesn't track yet (it sends `null`, as for flagged prescriptions) is left
/// out rather than shown as zero.
class SystemAlertsCard extends StatelessWidget {
  const SystemAlertsCard({super.key});

  /// `09:05 AM` for today, otherwise `3 Nov`.
  static String? _when(dynamic value) {
    final t = DateTime.tryParse('${value ?? ''}')?.toLocal();
    if (t == null) return null;
    final now = DateTime.now();
    final today = t.year == now.year && t.month == now.month && t.day == now.day;
    return today ? DateFormat('hh:mm a').format(t) : DateFormat('d MMM').format(t);
  }

  List<SystemAlert> _alerts(BuildContext context, Map<String, dynamic> alerts) {
    void go(String route) =>
        StoreProvider.of<AppState>(context, listen: false).dispatch(NavigateToAction(route));
    final list = <SystemAlert>[];

    final pending = alerts['pending_verifications'];
    if (pending is Map) {
      final count = (numOf(pending['count']) ?? 0).toInt();
      final doctors = (numOf(pending['doctors']) ?? 0).toInt();
      final pharmacies = (numOf(pending['pharmacies']) ?? 0).toInt();
      final parts = [
        if (doctors > 0) '$doctors doctor${doctors == 1 ? '' : 's'}',
        if (pharmacies > 0) '$pharmacies pharmac${pharmacies == 1 ? 'y' : 'ies'}',
      ];
      list.add(SystemAlert(
        title: 'Pending verifications',
        subtitle: count == 0 ? 'None waiting' : '$count waiting · ${parts.join(', ')}',
        time: count == 0 ? null : _when(pending['latest_at']),
        active: count > 0,
        // Open whichever directory has requests waiting (Doctors if both).
        onTap: count == 0 ? null : () => go(doctors > 0 ? 'doctors' : 'pharmacies'),
      ));
    }

    final failed = alerts['failed_payments'];
    if (failed is Map) {
      final count = (numOf(failed['count']) ?? 0).toInt();
      final days = (numOf(failed['window_days']) ?? 7).toInt();
      list.add(SystemAlert(
        title: 'Failed payments',
        subtitle: count == 0 ? 'None in the last $days days' : '$count in the last $days days',
        time: count == 0 ? null : _when(failed['latest_at']),
        active: count > 0,
      ));
    }

    final flagged = alerts['flagged_prescriptions'];
    if (flagged is Map) {
      final count = (numOf(flagged['count']) ?? 0).toInt();
      list.add(SystemAlert(
        title: 'Flagged prescriptions',
        subtitle: count == 0 ? 'None flagged' : '$count new',
        time: count == 0 ? null : _when(flagged['latest_at']),
        active: count > 0,
      ));
    }
    return list;
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
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'System alerts',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminResourceBuilder(
            resource: AdminResource.dashboardSummary,
            load: const {},
            builder: (context, data) => AsyncContent(
              data: data,
              onRetry: () => reloadAdmin(context, AdminResource.dashboardSummary),
              builder: (raw) {
                final alerts = _alerts(context, mapOf(mapOf(raw)['alerts']));
                if (alerts.isEmpty) return const EmptyState(message: 'No alerts.');
                return Column(children: [
                  for (final alert in alerts) ...[
                    _AlertTile(alert: alert),
                    const SizedBox(height: 10),
                  ],
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final SystemAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: alert.active ? AppColors.alertBackground : AppColors.contentBackground.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: alert.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(alert.subtitle,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(alert.onTap == null ? Icons.more_horiz : Icons.chevron_right,
                      size: 16, color: AppColors.textSecondary),
                  if (alert.time != null) ...[
                    const SizedBox(height: 8),
                    Text(alert.time!, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
