import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/shell/app_shell.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/dashboard/activity_trend_card.dart';
import '../widgets/dashboard/system_distribution_card.dart';
import '../widgets/dashboard/recent_users_card.dart';
import '../widgets/dashboard/system_alerts_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return AppShell(
      currentPage: 'Dashboard',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: [
                    Text(today, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.refresh, size: 15, color: AppColors.textSecondary),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Good Morning Sam',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            const StatCardsRow(),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final activity = const SizedBox(height: 340, child: ActivityTrendCard());
                final distribution = const SizedBox(height: 340, child: SystemDistributionCard());
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: activity),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: distribution),
                    ],
                  );
                }
                return Column(children: [activity, const SizedBox(height: 16), distribution]);
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                const usersCard = RecentUsersCard();
                const alertsCard = SystemAlertsCard();
                if (isWide) {
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: usersCard),
                      SizedBox(width: 16),
                      Expanded(flex: 1, child: alertsCard),
                    ],
                  );
                }
                return const Column(children: [usersCard, SizedBox(height: 16), alertsCard]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
