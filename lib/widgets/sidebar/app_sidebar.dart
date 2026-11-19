import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../../models/nav_item.dart';
import '../../theme/app_colors.dart';
import '../../core/utils/logout.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  static final List<NavSection> _sections = [
    const NavSection(
      title: 'Main',
      icon: Icons.dashboard_outlined,
      items: [NavItem(label: 'Dashboard', route: 'dashboard')],
    ),
    const NavSection(
      title: 'Users',
      icon: Icons.groups_outlined,
      items: [
        NavItem(label: 'Patients', route: 'patients'),
        NavItem(label: 'Doctors', route: 'doctors'),
        NavItem(label: 'Pharmacies', route: 'pharmacies'),
        NavItem(label: 'Doctor Reviews', route: 'reviews'),
      ],
    ),
    const NavSection(
      title: 'Care',
      icon: Icons.medical_services_outlined,
      items: [
        NavItem(label: 'Appointments', route: 'appointments'),
        NavItem(label: 'Prescriptions', route: 'prescriptions'),
      ],
    ),
    const NavSection(
      title: 'Orders',
      icon: Icons.medication_outlined,
      items: [
        NavItem(label: 'All Orders', route: 'all_orders'),
        NavItem(label: 'Tracking', route: 'tracking'),
        NavItem(label: 'Overdue Orders', route: 'overdue_orders'),
      ],
    ),
    const NavSection(
      title: 'Partnerships',
      icon: Icons.handshake_outlined,
      items: [
        NavItem(label: 'Partner Groups', route: 'partner_groups'),
        NavItem(label: 'Agreements', route: 'agreements'),
        NavItem(label: 'Compliance', route: 'compliance'),
        NavItem(label: 'Claim Routing', route: 'claim_routing'),
      ],
    ),
    const NavSection(
      title: 'Financial',
      icon: Icons.account_balance_outlined,
      items: [NavItem(label: 'Billing & Payments', route: 'billing')],
    ),
    const NavSection(
      title: 'Security',
      icon: Icons.shield_outlined,
      items: [
        NavItem(label: 'Security Alerts', route: 'security_alerts'),
        NavItem(label: 'Security Overview', route: 'security'),
        NavItem(label: 'Login Locations', route: 'login_locations'),
      ],
    ),
    const NavSection(
      title: 'Support',
      icon: Icons.support_agent_outlined,
      items: [
        NavItem(label: 'Support Tickets', route: 'support_tickets'),
        NavItem(label: 'Help Center', route: 'help_center'),
      ],
    ),
    const NavSection(
      title: 'System',
      icon: Icons.settings_outlined,
      items: [
        NavItem(label: 'Settings', route: 'settings'),
        NavItem(label: 'Payment Gateways', route: 'payment_gateways'),
        NavItem(label: 'My Account', route: 'account'),
        NavItem(label: 'Admin Tools', route: 'admin_tools'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String>(
      converter: (store) => store.state.navigationState.currentRoute,
      distinct: true,
      builder: (context, currentRoute) => Container(
        width: 260,
        color: AppColors.sidebarBackground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Logo(),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  for (final section in _sections) ...[
                    _SectionHeader(section: section),
                    const SizedBox(height: 4),
                    for (final item in section.items)
                      _NavRow(
                        item: item,
                        selected: currentRoute == item.route,
                        onTap: () => StoreProvider.of<AppState>(context)
                            .dispatch(NavigateToAction(item.route)),
                      ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: const Icon(Icons.favorite_border, color: AppColors.primary, size: 20),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final NavSection section;
  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(section.icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavRow({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.activeNavBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
                  : null,
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (item.route == 'security_alerts') _CountBadge.alerts,
              if (item.route == 'overdue_orders') _CountBadge.overdueOrders,
            ]),
          ),
        ),
      ),
    );
  }
}

/// A red count beside a sidebar item, read from a stats endpoint that is
/// loaded once per session (with no params, as the startup prefetch does)
/// and refetched whenever that screen reloads it. Hidden at zero.
class _CountBadge extends StatelessWidget {
  final AdminResource resource;
  final dynamic Function(Map data) read;
  final String Function(num count) tooltip;

  const _CountBadge(this.resource, this.read, this.tooltip);

  /// Unreviewed critical and high alerts, all time.
  static const alerts = _CountBadge(
      AdminResource.securityAlertStats, _unreviewedAlerts, _alertsTooltip);

  /// Orders in progress that are past their status's time limit, right now.
  static const overdueOrders = _CountBadge(
      AdminResource.orderTrackingStats, _overdueOrders, _overdueTooltip);

  static dynamic _unreviewedAlerts(Map d) => d['unreviewed_critical_or_high'];
  static String _alertsTooltip(num n) => '$n critical or high alerts waiting for review';
  static dynamic _overdueOrders(Map d) => d['active'] is Map ? d['active']['overdue'] : null;
  static String _overdueTooltip(num n) => '$n orders overdue right now';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, num>(
      onInit: (store) {
        if (store.state.adminState.of(resource).isIdle) {
          store.dispatch(FetchAdminResourceAction(resource));
        }
      },
      converter: (store) {
        final data = store.state.adminState.of(resource).data;
        final n = data is Map ? read(data) : null;
        return n is num ? n : num.tryParse('${n ?? ''}') ?? 0;
      },
      distinct: true,
      builder: (context, count) {
        if (count <= 0) return const SizedBox.shrink();
        return Tooltip(
          message: tooltip(count),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
            child: Text(count > 99 ? '99+' : '$count',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Was inert: a bare Container with no gesture handler, so the button
    // looked live but did nothing.
    return Material(
      color: AppColors.contentBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // Best-effort by design: the store is cleared and the user is routed
        // out even if revoking the session server-side fails.
        onTap: () => performLogout(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.logout, size: 16, color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
