import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/shell/app_shell.dart';

/// The signed-in admin's profile, active sessions and audit history.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'My Account',
      body: PinnedPage(
        sections: true,
        header: const [
          ScreenTitle(title: 'My Account', subtitle: 'Your admin profile, sessions and activity'),
          SizedBox(height: 20),
        ],
        body: (_) => const Column(children: [
          _Profile(),
          SizedBox(height: 18),
          _Sessions(),
          SizedBox(height: 18),
          _Activity(),
        ]),
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile();

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.profile,
      load: const {},
      builder: (context, data) => SectionCard(
        title: 'Profile',
        child: AsyncContent(
          data: data,
          onRetry: () => reloadAdmin(context, AdminResource.profile),
          // Keyed by update time so the form picks up saved values.
          builder: (raw) => _ProfileForm(key: ValueKey(data.updatedAt), profile: mapOf(raw)),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  final Map<String, dynamic> profile;
  const _ProfileForm({super.key, required this.profile});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _first = TextEditingController(text: widget.profile['first_name']?.toString());
  late final _last = TextEditingController(text: widget.profile['last_name']?.toString());
  late final _phone = TextEditingController(text: widget.profile['phone']?.toString());
  late final _email = TextEditingController(text: widget.profile['email']?.toString());
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final first = _first.text.trim();
    final last = _last.text.trim();
    final phone = _phone.text.trim();
    if (first.isEmpty || last.isEmpty) {
      setState(() => _error = 'First and last name are required.');
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a valid phone number.');
      return;
    }
    setState(() => _error = null);
    await runAdminMutation(
      context,
      (c) => UpdateAdminProfileAction(
          {'first_name': first, 'last_name': last, 'phone': phone.isEmpty ? null : phone},
          completer: c),
      success: 'Profile updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final initials = [p['first_name'], p['last_name']]
        .map((v) => v?.toString().trim() ?? '')
        .where((v) => v.isNotEmpty)
        .map((v) => v[0].toUpperCase())
        .join();

    final summary = Row(children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.activeNavBackground,
        child: Text(initials.isEmpty ? 'A' : initials,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(personName(p, fallbacks: ['email']),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            StatusBadge(status: humanize('${p['status'] ?? 'active'}')),
            Text('Admin since ${formatDate(p['created_at'])}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary,
        const SizedBox(height: 22),
        FormGrid(children: [
          LabeledField(label: 'First Name', required: true, child: AdminTextInput(controller: _first)),
          LabeledField(label: 'Last Name', required: true, child: AdminTextInput(controller: _last)),
          LabeledField(label: 'Phone', child: AdminTextInput(controller: _phone, keyboardType: TextInputType.phone)),
          LabeledField(label: 'Email (cannot be changed)', child: AdminTextInput(controller: _email, enabled: false)),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 14),
          ErrorPanel(message: _error!, compact: true),
        ],
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: PendingBuilder(
            mutationKey: 'profile.update',
            builder: (_, busy) => PrimaryButton(label: 'Save Changes', busy: busy, onPressed: _save),
          ),
        ),
      ],
    );
  }
}

class _Sessions extends StatelessWidget {
  const _Sessions();

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.sessions,
      load: const {},
      builder: (context, data) {
        final rows = recordsOf(data.data, ['sessions']);
        return SectionCard(
          title: 'Active Sessions',
          subtitle: data.hasData ? '${rows.length} signed-in session${rows.length == 1 ? '' : 's'}' : null,
          trailing: RowIconButton(
              icon: Icons.refresh,
              tooltip: 'Refresh',
              onPressed: () => reloadAdmin(context, AdminResource.sessions)),
          child: AsyncContent(
            data: data,
            onRetry: () => reloadAdmin(context, AdminResource.sessions),
            builder: (_) => RecordTable(
              rows: rows,
              emptyMessage: 'No active sessions.',
              columns: [
                RecordColumn('Device',
                    width: 280,
                    cell: (r) => CellText(formatValue(r['device_info']), strong: true)),
                const RecordColumn('IP Address', field: 'ip_address', width: 150),
                const RecordColumn('Signed In', field: 'created_at', width: 160),
                const RecordColumn('Last Active', field: 'last_activity_at', width: 160),
                const RecordColumn('Expires', field: 'expires_at', width: 160),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity();

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.activityLog,
      load: const {'limit': 50},
      builder: (context, data) => SectionCard(
        title: 'Activity Log',
        // The backend currently always returns 50: adminController defines
        // getActivityLog twice and the later copy ignores `limit`.
        subtitle: 'Your 50 most recent actions, newest first',
        trailing: RowIconButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onPressed: () => reloadAdmin(context, AdminResource.activityLog)),
        child: AsyncContent(
          data: data,
          onRetry: () => reloadAdmin(context, AdminResource.activityLog),
          // The endpoint returns a bare list today; older builds wrapped it
          // as {activities: [...]}.
          builder: (raw) => RecordTable(
            rows: recordsOf(raw, ['activities']),
            emptyMessage: 'No activity recorded yet.',
            columns: [
              RecordColumn('Event', width: 220, cell: (r) => CellText(humanize('${r['event_type'] ?? '—'}'), strong: true)),
              const RecordColumn('Status', field: 'status', width: 110),
              const RecordColumn('IP Address', field: 'ip_address', width: 150),
              const RecordColumn('When', field: 'created_at', width: 170),
              const RecordColumn('Details', field: 'error_message', width: 260),
            ],
          ),
        ),
      ),
    );
  }
}
