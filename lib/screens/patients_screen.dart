import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../theme/app_colors.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/table_cell.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _query = '';

  final List<Patient> _patients = [
    Patient(name: 'Maria Garcia', email: 'mariag@email.com', phone: '+27 71 123 4567', dateJoined: '12 March 2026', lastActivity: '3 hours ago', status: 'Active', avatarColor: Colors.pinkAccent),
    Patient(name: 'Maria Wilson', email: 'mwilson@email.com', phone: '+27 72 123 4567', dateJoined: '12 March 2026', lastActivity: '5 hours ago', status: 'Active', avatarColor: Colors.indigoAccent),
    Patient(name: 'Maria Wilson', email: 'mwilson2@email.com', phone: '+27 73 123 4567', dateJoined: '12 March 2026', lastActivity: '1 day ago', status: 'Active', avatarColor: Colors.deepPurpleAccent),
    Patient(name: 'Maria Wilson', email: 'mwilson3@email.com', phone: '+27 74 123 4567', dateJoined: '12 March 2026', lastActivity: '2 hours ago', status: 'Active', avatarColor: Colors.teal),
    Patient(name: 'Maria Wilson', email: 'mwilson4@email.com', phone: '+27 75 123 4567', dateJoined: '12 March 2026', lastActivity: '2 days ago', status: 'Active', avatarColor: Colors.orangeAccent),
    Patient(name: 'Maria Wilson', email: 'mwilson5@email.com', phone: '+27 76 123 4567', dateJoined: '12 March 2026', lastActivity: '2 days ago', status: 'Active', avatarColor: Colors.blueAccent),
    Patient(name: 'Maria Wilson', email: 'mwilson6@email.com', phone: '+27 77 123 4567', dateJoined: '12 March 2026', lastActivity: '2 days ago', status: 'Pending', avatarColor: Colors.brown),
    Patient(name: 'Maria Wilson', email: 'mwilson7@email.com', phone: '+27 78 123 4567', dateJoined: '12 March 2026', lastActivity: '2 days ago', status: 'Active', avatarColor: Colors.pink),
    Patient(name: 'Maria Wilson', email: 'mwilson8@email.com', phone: '+27 79 123 4567', dateJoined: '12 March 2026', lastActivity: '4 hours ago', status: 'Active', avatarColor: Colors.cyan),
  ];

  List<Patient> get _filtered {
    if (_query.trim().isEmpty) return _patients;
    final q = _query.toLowerCase();
    return _patients.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.email.toLowerCase().contains(q) ||
        p.phone.toLowerCase().contains(q)).toList();
  }

  int get _activeCount => _patients.where((p) => p.status == 'Active').length;
  int get _suspendedCount => _patients.where((p) => p.status == 'Suspended' || p.status == 'Blocked').length;
  int get _pendingCount => _patients.where((p) => p.status == 'Pending').length;

  void _setStatus(Patient p, String status) {
    setState(() => p.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.name} marked as $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Patients',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: kTableActionMenuClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Patients',
              subtitle: 'Manage patient accounts and permissions',
              searchHint: 'Search patients',
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),
            _StatsRow(
              total: _patients.length,
              active: _activeCount,
              newThisMonth: 219,
              suspended: _suspendedCount,
              pending: _pendingCount,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ScrollableTable(
                minWidth: 1060,
                header: Row(
                  children: const [
                    AppTableHeaderCell(label: 'Patient', width: 220),
                    AppTableHeaderCell(label: 'Email', width: 210),
                    AppTableHeaderCell(label: 'Phone', width: 150),
                    AppTableHeaderCell(label: 'Date Joined', width: 130),
                    AppTableHeaderCell(label: 'Last Activity', width: 130),
                    AppTableHeaderCell(label: 'Status', width: 110),
                    AppTableHeaderCell(label: 'Action', width: 110),
                  ],
                ),
                rows: [
                  for (final patient in _filtered) _PatientRow(patient: patient, onStatusChange: _setStatus),
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No patients match your search.', style: TextStyle(color: AppColors.textSecondary)),
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

class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int newThisMonth;
  final int suspended;
  final int pending;

  const _StatsRow({
    required this.total,
    required this.active,
    required this.newThisMonth,
    required this.suspended,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(label: 'Total Patients', value: '$total', icon: Icons.person_outline),
      StatCardData(label: 'Active Patients', value: '$active', icon: Icons.check_circle_outline),
      StatCardData(label: 'New this month', value: '$newThisMonth', icon: Icons.trending_up),
      StatCardData(label: 'Suspended/Blocked', value: '$suspended', icon: Icons.block_outlined),
      StatCardData(label: 'Pending verification', value: '$pending', icon: Icons.hourglass_empty),
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

class _PatientRow extends StatelessWidget {
  final Patient patient;
  final void Function(Patient, String) onStatusChange;

  const _PatientRow({required this.patient, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTableCell(
          width: 220,
          child: Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: patient.avatarColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(patient.name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        AppTableCell(width: 210, child: Text(patient.email, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        AppTableCell(width: 150, child: Text(patient.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(width: 130, child: Text(patient.dateJoined, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(width: 130, child: Text(patient.lastActivity, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
        AppTableCell(width: 110, child: StatusBadge(status: patient.status)),
        AppTableCell(
          width: 110,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit ${patient.name}')),
                ),
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
                  if (patient.status != 'Active') const PopupMenuItem(value: 'Active', child: Text('Activate')),
                  if (patient.status == 'Active') const PopupMenuItem(value: 'Suspended', child: Text('Suspend')),
                  const PopupMenuItem(value: 'Blocked', child: Text('Block')),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing ${patient.name}\'s profile')),
                    );
                  } else {
                    onStatusChange(patient, value);
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
