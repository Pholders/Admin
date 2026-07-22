import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SystemAlert {
  final String title;
  final String subtitle;
  final String time;

  const SystemAlert({required this.title, required this.subtitle, required this.time});
}

class SystemAlertsCard extends StatelessWidget {
  const SystemAlertsCard({super.key});

  static const _alerts = [
    SystemAlert(title: 'Pending verifications', subtitle: '3 New', time: '09:05 AM'),
    SystemAlert(title: 'Failed payments', subtitle: '2 New', time: '09:24 AM'),
    SystemAlert(title: 'Flagged prescription', subtitle: '1 New', time: '09:25 AM'),
  ];

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
            children: const [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'System alerts',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final alert in _alerts) ...[
            _AlertTile(alert: alert),
            const SizedBox(height: 10),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.alertBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(alert.subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(alert.time, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
