import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class RecentUser {
  final String name;
  final String role;
  final String status;
  final Color avatarColor;

  const RecentUser({
    required this.name,
    required this.role,
    required this.status,
    required this.avatarColor,
  });
}

class RecentUsersCard extends StatefulWidget {
  const RecentUsersCard({super.key});

  @override
  State<RecentUsersCard> createState() => _RecentUsersCardState();
}

class _RecentUsersCardState extends State<RecentUsersCard> {
  int _tabIndex = 0;
  static const _tabs = ['All', 'Patients', 'Doctors', 'Pharmacy'];

  static const _users = [
    RecentUser(name: 'Maria Wilson', role: 'Patient', status: 'Active', avatarColor: Colors.pinkAccent),
    RecentUser(name: 'Maria Wilson', role: 'Doctor', status: 'Active', avatarColor: Colors.indigoAccent),
    RecentUser(name: 'Maria Wilson', role: 'Pharmacy', status: 'Active', avatarColor: Colors.deepPurpleAccent),
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
            children: [
              const Icon(Icons.person_outline, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Text(
                'Recent Users',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              for (var i = 0; i < _tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _TabChip(
                    label: _tabs[i],
                    selected: i == _tabIndex,
                    onTap: () => setState(() => _tabIndex = i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _HeaderRow(),
          const Divider(height: 24),
          for (final user in _users) ...[
            _UserRow(user: user),
            const SizedBox(height: 14),
          ],
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
    return Row(
      children: const [
        Expanded(flex: 3, child: Text('Name', style: style)),
        Expanded(flex: 2, child: Text('Role', style: style)),
        Expanded(flex: 2, child: Text('Status', style: style)),
        Expanded(flex: 2, child: Text('Action', style: style)),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final RecentUser user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: user.avatarColor),
              const SizedBox(width: 10),
              Text(user.name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(user.role, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(user.status, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.textSecondary),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.textSecondary),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              _ActionMenu(user: user),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "..." menu that opens View / Verify (Approve) / Reject — matches the
/// popup shown at the bottom of the Figma frame.
class _ActionMenu extends StatelessWidget {
  final RecentUser user;
  const _ActionMenu({required this.user});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 17, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'view', child: Text('View')),
        const PopupMenuItem(value: 'verify', child: Text('Verify (Approve)')),
        const PopupMenuItem(value: 'reject', child: Text('Reject')),
      ],
      onSelected: (value) {
        // Wire these up to real actions (navigate, call API, show dialog, etc).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$value → ${user.name}')),
        );
      },
    );
  }
}
