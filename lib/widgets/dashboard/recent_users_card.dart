import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../../theme/app_colors.dart';
import '../admin/account_ui.dart';
import '../admin/admin_format.dart';
import '../admin/admin_ui.dart';
import '../common/status_badge.dart';

/// Newest sign-ups across patients, doctors and pharmacies, from
/// `GET /admin/users/recent`. The row menu verifies or rejects pending
/// accounts and suspends or reactivates the rest.
class RecentUsersCard extends StatefulWidget {
  const RecentUsersCard({super.key});

  @override
  State<RecentUsersCard> createState() => _RecentUsersCardState();
}

class _RecentUsersCardState extends State<RecentUsersCard> {
  static const _limit = 6;
  static const _tabs = [('all', 'All'), ('patient', 'Patients'), ('doctor', 'Doctors'), ('pharmacy', 'Pharmacy')];

  String _role = 'all';

  Map<String, dynamic> get _params => {'role': _role, 'limit': _limit};

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
              const Icon(Icons.person_outline, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Text(
                'Recent Users',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              for (final (role, label) in _tabs)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _TabChip(
                    label: label,
                    selected: role == _role,
                    onTap: () {
                      setState(() => _role = role);
                      loadAdmin(context, AdminResource.recentUsers, params: _params);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _HeaderRow(),
          const Divider(height: 24),
          AdminResourceBuilder(
            resource: AdminResource.recentUsers,
            load: _params,
            builder: (context, data) => AsyncContent(
              data: data,
              onRetry: () => reloadAdmin(context, AdminResource.recentUsers),
              builder: (raw) {
                final users = recordsOf(raw, ['users']);
                if (users.isEmpty) return const EmptyState(message: 'No sign-ups yet.');
                return Column(children: [
                  for (final user in users) ...[
                    _UserRow(user: user),
                    const SizedBox(height: 14),
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

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600);
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('Name', style: style)),
        Expanded(flex: 2, child: Text('Role', style: style)),
        Expanded(flex: 2, child: Text('Joined', style: style)),
        Expanded(flex: 2, child: Text('Status', style: style)),
        SizedBox(width: 80, child: Text('Action', style: style)),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final role = user['role']?.toString() ?? 'patient';
    void open() => showAccountDetail(context, role: role, account: user);
    return Row(
      children: [
        Expanded(flex: 3, child: AccountNameCell(row: user, onTap: open)),
        Expanded(flex: 2, child: CellText(accountRoleLabels[role] ?? humanize(role))),
        Expanded(flex: 2, child: CellText(formatDate(user['created_at']))),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(status: humanize('${user['status'] ?? 'active'}')),
          ),
        ),
        SizedBox(
          width: 80,
          child: Row(children: [
            RowIconButton(icon: Icons.visibility_outlined, tooltip: 'View', onPressed: open),
            AccountActionsMenu(role: role, account: user),
          ]),
        ),
      ],
    );
  }
}
