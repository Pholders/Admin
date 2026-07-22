import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final String? actionLabel; // e.g. "View requests" — shown as a small link under the value
  final VoidCallback? onAction;

  const StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });
}

class StatCard extends StatelessWidget {
  final StatCardData data;
  const StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (data.actionLabel != null) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: data.onAction,
                  child: Text(
                    data.actionLabel!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class StatCardsRow extends StatelessWidget {
  const StatCardsRow({super.key});

  static const List<StatCardData> _stats = [
    StatCardData(label: 'Doctors', value: '128', icon: Icons.person_outline),
    StatCardData(label: 'Pharmacies', value: '128', icon: Icons.local_pharmacy_outlined),
    StatCardData(label: 'Active prescriptions', value: '128', icon: Icons.medication_outlined),
    StatCardData(label: 'Orders today', value: '128', icon: Icons.receipt_long_outlined),
    StatCardData(label: 'Revenue', value: 'R20000', icon: Icons.bar_chart_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Wrap on narrow widths, single row of 5 on wide screens.
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final stat in _stats)
              SizedBox(
                width: constraints.maxWidth > 900
                    ? (constraints.maxWidth - 14 * 4) / 5
                    : 220,
                child: StatCard(data: stat),
              ),
          ],
        );
      },
    );
  }
}
