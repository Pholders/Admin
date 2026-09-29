import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../theme/app_colors.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/table_cell.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String _query = '';
  String? _statusFilter; // set by tapping "View requests" / "View suspended"

  final List<Doctor> _doctors = [
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j@example.com', specialization: 'Orthopedic', status: 'Active', joinedOn: '12 March 2026', avatarColor: Colors.pinkAccent),
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j2@example.com', specialization: 'Orthopedic', status: 'Active', joinedOn: '12 March 2026', avatarColor: Colors.indigoAccent),
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j3@example.com', specialization: 'Orthopedic', status: 'Active', joinedOn: '12 March 2026', avatarColor: Colors.teal),
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j4@example.com', specialization: 'Orthopedic', status: 'Active', joinedOn: '12 March 2026', avatarColor: Colors.deepPurpleAccent),
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j5@example.com', specialization: 'Orthopedic', status: 'Active', joinedOn: '12 March 2026', avatarColor: Colors.orangeAccent),
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j6@example.com', specialization: 'Orthopedic', status: 'Active', joinedOn: '12 March 2026', avatarColor: Colors.blueAccent),
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j7@example.com', specialization: 'Orthopedic', status: 'Active', joinedOn: '12 March 2026', avatarColor: Colors.cyan),
    Doctor(name: 'Dr. Sarah Johnson', email: 'sarah.j8@example.com', specialization: 'Orthopedic', status: 'Pending', joinedOn: '12 March 2026', avatarColor: Colors.brown),
  ];

  List<Doctor> get _filtered {
    Iterable<Doctor> list = _doctors;
    if (_statusFilter != null) {
      list = list.where((d) => d.status == _statusFilter);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.email.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q));
    }
    return list.toList();
  }

  int get _activeCount => _doctors.where((d) => d.status == 'Active').length;
  int get _pendingCount => _doctors.where((d) => d.status == 'Pending').length;
  int get _suspendedCount => _doctors.where((d) => d.status == 'Suspended' || d.status == 'Blocked').length;

  void _setStatus(Doctor d, String status) {
    setState(() => d.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${d.name} marked as $status')),
    );
  }

  void _applyFilter(String status) {
    setState(() => _statusFilter = _statusFilter == status ? null : status);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Doctors',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: kTableActionMenuClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Doctors',
              subtitle: 'Manage doctor accounts and permissions',
              searchHint: 'Search doctors',
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),
            _StatsRow(
              total: _doctors.length,
              active: _activeCount,
              pending: _pendingCount,
              suspended: _suspendedCount,
              pendingVerification: 48,
              onViewPending: () => _applyFilter('Pending'),
              onViewSuspended: () => _applyFilter('Suspended'),
            ),
            if (_statusFilter != null) ...[
              const SizedBox(height: 12),
              _FilterBanner(status: _statusFilter!, onClear: () => setState(() => _statusFilter = null)),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ScrollableTable(
                minWidth: 980,
                header: Row(
                  children: const [
                    AppTableHeaderCell(label: 'Doctor', width: 220),
                    AppTableHeaderCell(label: 'Email', width: 210),
                    AppTableHeaderCell(label: 'Specialization', width: 150),
                    AppTableHeaderCell(label: 'Status', width: 110),
                    AppTableHeaderCell(label: 'Joined On', width: 130),
                    AppTableHeaderCell(label: 'Actions', width: 110),
                  ],
                ),
                rows: [
                  for (final d in _filtered) _DoctorRow(doctor: d, onStatusChange: _setStatus),
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No doctors match your search.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBanner extends StatelessWidget {
  final String status;
  final VoidCallback onClear;
  const _FilterBanner({required this.status, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filtering by status: ', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          Text(status, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int pending;
  final int suspended;
  final int pendingVerification;
  final VoidCallback onViewPending;
  final VoidCallback onViewSuspended;

  const _StatsRow({
    required this.total,
    required this.active,
    required this.pending,
    required this.suspended,
    required this.pendingVerification,
    required this.onViewPending,
    required this.onViewSuspended,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(label: 'Total Doctors', value: '$total', icon: Icons.person_outline),
      StatCardData(label: 'Active Doctors', value: '$active', icon: Icons.check_circle_outline),
      StatCardData(label: 'Pending Approval', value: '$pending', icon: Icons.hourglass_empty, actionLabel: 'View requests', onAction: onViewPending),
      StatCardData(label: 'Suspended/Blocked', value: '$suspended', icon: Icons.block_outlined, actionLabel: 'View suspended', onAction: onViewSuspended),
      StatCardData(label: 'Pending verification', value: '$pendingVerification', icon: Icons.receipt_long_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final stat in stats)
              SizedBox(
                width: constraints.maxWidth > 900 ? (constraints.maxWidth - 14 * 4) / 5 : 220,
                child: StatCard(data: stat),
              ),
          ],
        );
      },
    );
  }
}

class _DoctorRow extends StatelessWidget {
  final Doctor doctor;
  final void Function(Doctor, String) onStatusChange;

  const _DoctorRow({required this.doctor, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTableCell(
          width: 220,
          child: Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: doctor.avatarColor),
              const SizedBox(width: 10),
              Expanded(child: Text(doctor.name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        AppTableCell(width: 210, child: Text(doctor.email, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 150, child: Text(doctor.specialization, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(width: 110, child: StatusBadge(status: doctor.status)),
        AppTableCell(width: 130, child: Text(doctor.joinedOn, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(
          width: 110,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit ${doctor.name}'))),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete ${doctor.name}'))),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View profile')),
                  if (doctor.status != 'Active') const PopupMenuItem(value: 'Active', child: Text('Activate')),
                  if (doctor.status == 'Active') const PopupMenuItem(value: 'Suspended', child: Text('Suspend')),
                  const PopupMenuItem(value: 'Blocked', child: Text('Block')),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing ${doctor.name}\'s profile')));
                  } else {
                    onStatusChange(doctor, value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
