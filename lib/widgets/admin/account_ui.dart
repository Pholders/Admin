import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../common/status_badge.dart';
import 'admin_format.dart';
import 'admin_ui.dart';

/// Shared pieces for patient, doctor and pharmacy accounts: avatar, status
/// actions and the View dialog. Used by the dashboard's Recent Users and the
/// Patients / Doctors directories.

const accountRoleLabels = {'patient': 'Patient', 'doctor': 'Doctor', 'pharmacy': 'Pharmacy'};

/// Display name for a directory row from any of the three account types.
String accountName(Map<String, dynamic> row) {
  final name = row['name']?.toString().trim();
  if (name != null && name.isNotEmpty) return name;
  final pharmacy = row['pharmacy_name']?.toString().trim();
  if (pharmacy != null && pharmacy.isNotEmpty) return pharmacy;
  return personName(row, fallbacks: ['email']);
}

/// Image URL for an account. Uploads may be stored as server-relative paths.
String? accountImageUrl(Map<String, dynamic> row) {
  final raw = (row['profile_image'] ?? row['avatar_url'])?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  final host = AppConstants.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return raw.startsWith('/') ? '$host$raw' : '$host/$raw';
}

/// Initials on a tinted circle, replaced by the account's photo when it loads.
class AccountAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;

  const AccountAvatar({super.key, required this.name, this.imageUrl, this.radius = 14});

  static const _tints = [
    Color(0xFF14B8A9),
    Color(0xFF2F80ED),
    Color(0xFF7C6FEA),
    Color(0xFFE0577B),
    Color(0xFFE0A83C),
    Color(0xFF1FA97C),
  ];

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
    final tint = _tints[name.codeUnits.fold<int>(0, (a, b) => a + b) % _tints.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: tint.withValues(alpha: 0.15),
      foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      onForegroundImageError: imageUrl == null ? null : (_, __) {},
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.w700, color: tint),
      ),
    );
  }
}

/// Avatar, name and optional second line, for the first column of a table.
class AccountNameCell extends StatelessWidget {
  final Map<String, dynamic> row;
  final String? subtitle;
  final VoidCallback? onTap;

  const AccountNameCell({super.key, required this.row, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = accountName(row);
    final content = Row(children: [
      AccountAvatar(name: name, imageUrl: accountImageUrl(row)),
      const SizedBox(width: 10),
      Expanded(child: CellText(name, strong: true, subtitle: subtitle)),
    ]);
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: content),
    );
  }
}

// ─── Status changes ───────────────────────────────────────────────────────────

/// Asks for confirmation where the change locks someone out, then applies it.
Future<void> changeAccountStatus(
  BuildContext context, {
  required String role,
  required Map<String, dynamic> account,
  required String status,
}) async {
  final name = accountName(account);
  final current = account['status']?.toString();
  final roleLabel = (accountRoleLabels[role] ?? 'account').toLowerCase();

  if (status != 'active') {
    // Pharmacies' status endpoint doesn't revoke sessions; the patient and
    // doctor endpoints do.
    final signsOut = role != 'pharmacy';
    final (title, verb, effect) = switch (status) {
      'blocked' when current == 'pending' => (
          'Reject $name?',
          'Reject',
          'The $roleLabel registration is declined and the account is blocked.'
        ),
      'blocked' => ('Block $name?', 'Block', 'The $roleLabel can no longer sign in.'),
      'suspended' => (
          'Suspend $name?',
          'Suspend',
          'The $roleLabel can no longer sign in until the account is reactivated.'
        ),
      _ => ('Mark $name as pending?', 'Mark Pending', 'The account goes back to awaiting verification.'),
    };
    final ok = await confirmAdmin(
      context,
      title: title,
      message: signsOut ? '$effect They are also signed out on every device.' : effect,
      confirmLabel: verb,
      destructive: status != 'pending',
    );
    if (!ok || !context.mounted) return;
  }

  final id = account['id'];
  if (id == null) return;
  final done = switch (status) {
    'active' when current == 'pending' => '$name approved',
    'active' => '$name reactivated',
    'blocked' when current == 'pending' => '$name rejected',
    _ => '$name is now $status',
  };
  await runAdminMutation(
    context,
    (c) => SetAccountStatusAction(role, id, status, completer: c),
    success: done,
  );
}

/// The ⋯ menu for an account row: View plus the status changes that make
/// sense from its current status. A pending account gets the design's
/// "Verify (Approve)" and "Reject".
class AccountActionsMenu extends StatelessWidget {
  final String role;
  final Map<String, dynamic> account;

  const AccountActionsMenu({super.key, required this.role, required this.account});

  @override
  Widget build(BuildContext context) {
    final status = account['status']?.toString() ?? 'active';
    return PendingBuilder(
      mutationKey: 'account.$role.${account['id']}.status',
      builder: (context, busy) {
        if (busy) {
          return const Padding(
            padding: EdgeInsets.all(6),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }
        return PopupMenuButton<String>(
          tooltip: 'Actions',
          icon: const Icon(Icons.more_vert, size: 17, color: AppColors.textSecondary),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            if (status == 'pending') ...[
              const PopupMenuItem(value: 'active', child: Text('Verify (Approve)')),
              const PopupMenuItem(value: 'blocked', child: Text('Reject')),
            ] else ...[
              if (status != 'active') const PopupMenuItem(value: 'active', child: Text('Reactivate')),
              if (status == 'active') const PopupMenuItem(value: 'suspended', child: Text('Suspend')),
              if (status != 'blocked') const PopupMenuItem(value: 'blocked', child: Text('Block')),
            ],
          ],
          onSelected: (value) {
            if (value == 'view') {
              showAccountDetail(context, role: role, account: account);
            } else {
              changeAccountStatus(context, role: role, account: account, status: value);
            }
          },
        );
      },
    );
  }
}

// ─── View dialog ──────────────────────────────────────────────────────────────

/// Opens an account's details: the list row at once, then the full record
/// from `GET /admin/{patients|doctors|pharmacies}/:id`. A patient view is
/// audit-logged on the server.
Future<void> showAccountDetail(
  BuildContext context, {
  required String role,
  required Map<String, dynamic> account,
}) async {
  final store = StoreProvider.of<AppState>(context, listen: false);
  await showAdminDetail(context, (_) => _AccountDetailDialog(role: role, account: account));
  store.dispatch(const ClearAdminResourceAction(AdminResource.accountDetail));
}

class _AccountDetailDialog extends StatelessWidget {
  final String role;
  final Map<String, dynamic> account;

  const _AccountDetailDialog({required this.role, required this.account});

  static const _hidden = {
    'id', 'role', 'name', 'first_name', 'last_name', 'pharmacy_name', 'status',
    'profile_image', 'avatar_url', 'availability', 'details', 'operating_hours',
  };

  static const Map<String, String Function(dynamic)> _formatters = {
    'rating': _rating,
    'consultation_fee': formatRand,
    'delivery_radius': _km,
    // Postgres sends these as strings with eight decimals.
    'latitude': _coordinate,
    'longitude': _coordinate,
  };

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: AdminResource.accountDetail,
      load: {'role': role, 'id': account['id']},
      builder: _frame,
    );
  }

  Widget _frame(BuildContext context, RemoteData data) {
    // The list row until the full record arrives, then the full record.
    final record = data.hasData ? {...account, ...mapOf(data.data)} : account;
    final name = accountName(record);
    final status = record['status']?.toString() ?? 'active';

    return AdminDialog(
      title: name,
      subtitle: [
        accountRoleLabels[role],
        if (role == 'patient') 'Viewing a patient record is logged in the audit trail',
      ].whereType<String>().join(' · '),
      width: 760,
      actions: [
        if (status == 'pending') ...[
          SecondaryButton(
              label: 'Reject',
              icon: Icons.close,
              onPressed: () => changeAccountStatus(context, role: role, account: record, status: 'blocked')),
          PrimaryButton(
              label: 'Verify (Approve)',
              icon: Icons.verified_outlined,
              onPressed: () => changeAccountStatus(context, role: role, account: record, status: 'active')),
        ] else if (status == 'active')
          SecondaryButton(
              label: 'Suspend',
              icon: Icons.pause_circle_outline,
              onPressed: () => changeAccountStatus(context, role: role, account: record, status: 'suspended'))
        else
          PrimaryButton(
              label: 'Reactivate',
              icon: Icons.play_circle_outline,
              onPressed: () => changeAccountStatus(context, role: role, account: record, status: 'active')),
        if (status != 'pending') PrimaryButton(label: 'Done', onPressed: () => closeAdminDetail(context)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AccountAvatar(name: name, imageUrl: accountImageUrl(record), radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(record['email']?.toString() ?? '—',
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  StatusBadge(status: humanize(status)),
                  if (record['email_verified'] == false) const StatusBadge(status: 'Email unverified'),
                  if (record['account_frozen'] == true) const StatusBadge(status: 'Frozen'),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          // The row's own fields show at once; the full record fills in.
          if (data.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                  minHeight: 2, color: AppColors.primary, backgroundColor: AppColors.activeNavBackground),
            ),
          if (data.hasError) ...[
            ErrorPanel(
              message: 'Showing the list details only — the full record could not be loaded: ${data.error}',
              compact: true,
              onRetry: () => reloadAdmin(context, AdminResource.accountDetail),
            ),
            const SizedBox(height: 12),
          ],
          KeyValueGrid(values: record, exclude: _hidden, formatters: _formatters),
          if (record['services'] is List && (record['services'] as List).isNotEmpty) ...[
            const SizedBox(height: 18),
            const SubHeading('Services'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in record['services'] as List) _Chip(humanize('$s')),
            ]),
          ],
        ],
      ),
    );
  }

  static String _rating(dynamic v) {
    final n = numOf(v);
    return n == null ? '—' : '${formatNumber(n, decimals: 1)} ★';
  }

  static String _km(dynamic v) {
    final n = numOf(v);
    return n == null ? '—' : '${formatNumber(n)} km';
  }

  static String _coordinate(dynamic v) {
    final n = numOf(v);
    return n == null ? '—' : n.toStringAsFixed(5);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.activeNavBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
    );
  }
}
