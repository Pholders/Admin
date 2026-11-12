import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';

import 'package:pholders_admin/store.dart';
import '../core/utils/greeting.dart';
import '../theme/app_colors.dart';
import '../widgets/shell/app_shell.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/dashboard/dashboard_stats.dart';
import '../widgets/dashboard/activity_trend_card.dart';
import '../widgets/dashboard/system_distribution_card.dart';
import '../widgets/dashboard/recent_users_card.dart';
import '../widgets/dashboard/system_alerts_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _resources = [
    AdminResource.dashboardSummary,
    AdminResource.dashboardActivity,
    AdminResource.recentUsers,
  ];

  @override
  void initState() {
    super.initState();
    // The store keeps the last figures; show them straight away and refresh
    // them in the background each time the dashboard is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = StoreProvider.of<AppState>(context, listen: false).state.adminState;
      for (final r in _resources) {
        final slot = admin.of(r);
        // Skip data the startup prefetch is still loading or just loaded.
        final fresh = slot.isLoading ||
            (slot.updatedAt != null &&
                DateTime.now().difference(slot.updatedAt!) < const Duration(seconds: 30));
        if (!slot.isIdle && !fresh) reloadAdmin(context, r);
      }
    });
  }

  void _refresh() {
    for (final r in _resources) {
      reloadAdmin(context, r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final greeting = timeOfDayGreeting();

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
                    RowIconButton(icon: Icons.refresh, tooltip: 'Refresh', onPressed: _refresh),
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
            // Real name from the store, written when the admin's code was
            // verified and reloaded from secure storage on refresh.
            StoreConnector<AppState, String?>(
              converter: (store) => store.state.authState.userName,
              builder: (context, userName) {
                final name = userName?.trim() ?? '';
                return Text(
                  name.isEmpty ? greeting : '$greeting $name',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                );
              },
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
