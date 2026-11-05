import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/shell/app_shell.dart';

/// One-off operational actions and diagnostics.
class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Admin Tools',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle(
              title: 'Admin Tools',
              subtitle: 'Maintenance actions and system diagnostics',
            ),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              const tools = [_AutoCancelTool(), _RevertClaimTool(), _StripeTool()];
              if (c.maxWidth < 1000) {
                return Column(children: [
                  for (final t in tools) ...[t, const SizedBox(height: 18)],
                ]);
              }
              return IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = 0; i < tools.length; i++) ...[
                    if (i > 0) const SizedBox(width: 18),
                    Expanded(child: tools[i]),
                  ],
                ]),
              );
            }),
            const SizedBox(height: 18),
            const _LogsTool(),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(description,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// The outcome of the last run, shown under a tool.
class _Outcome extends StatelessWidget {
  final bool ok;
  final String message;
  const _Outcome({required this.ok, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF1FA97C) : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ok ? Icons.check_circle_outline : Icons.error_outline, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
      ]),
    );
  }
}

class _AutoCancelTool extends StatefulWidget {
  const _AutoCancelTool();

  @override
  State<_AutoCancelTool> createState() => _AutoCancelToolState();
}

class _AutoCancelToolState extends State<_AutoCancelTool> {
  final _minutes = TextEditingController(text: '30');
  _Outcome? _outcome;

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final minutes = int.tryParse(_minutes.text.trim());
    if (minutes == null || minutes < 5 || minutes > 1440) {
      setState(() => _outcome = const _Outcome(ok: false, message: 'Enter a number of minutes from 5 to 1440.'));
      return;
    }
    final ok = await confirmAdmin(context,
        title: 'Cancel unpaid appointments?',
        message: 'Every appointment whose payment has been pending for more than $minutes minutes '
            'will be cancelled. Patients will need to book again.',
        confirmLabel: 'Cancel Appointments',
        destructive: true);
    if (!ok || !mounted) return;

    final result = await runAdminMutation(
      context,
      (c) => AutoCancelExpiredAppointmentsAction(timeoutMinutes: minutes, completer: c),
    );
    if (!mounted) return;
    setState(() => _outcome = result.ok
        ? _Outcome(
            ok: true,
            message: 'Cancelled ${formatValue(numOf(mapOf(result.data)['cancelledCount']) ?? 0)} '
                'appointment(s) with payment pending over $minutes minutes.')
        : null);
  }

  @override
  Widget build(BuildContext context) {
    return _ToolCard(
      icon: Icons.event_busy_outlined,
      title: 'Cancel Expired Appointments',
      description: 'Cancels appointments whose payment was never completed within the time limit.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LabeledField(
          label: 'Payment pending longer than (minutes)',
          child: AdminTextInput(controller: _minutes, keyboardType: TextInputType.number),
        ),
        const SizedBox(height: 14),
        PendingBuilder(
          mutationKey: 'maintenance.autoCancel',
          builder: (_, busy) => PrimaryButton(label: 'Run Now', icon: Icons.play_arrow_rounded, busy: busy, onPressed: _run),
        ),
        if (_outcome != null) _outcome!,
      ]),
    );
  }
}

class _RevertClaimTool extends StatefulWidget {
  const _RevertClaimTool();

  @override
  State<_RevertClaimTool> createState() => _RevertClaimToolState();
}

class _RevertClaimToolState extends State<_RevertClaimTool> {
  final _id = TextEditingController();
  final _reason = TextEditingController();
  _Outcome? _outcome;

  @override
  void dispose() {
    _id.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final id = _id.text.trim();
    final reason = _reason.text.trim();
    if (id.isEmpty || reason.isEmpty) {
      setState(() => _outcome = const _Outcome(ok: false, message: 'Prescription ID and a reason are both required.'));
      return;
    }
    final ok = await confirmAdmin(context,
        title: 'Revert claim on prescription $id?',
        message: 'The pharmacy that claimed it loses the claim and the prescription becomes '
            'available to other pharmacies. The reason is recorded.',
        confirmLabel: 'Revert Claim',
        destructive: true);
    if (!ok || !mounted) return;

    final result = await runAdminMutation(
      context,
      (c) => RevertPrescriptionClaimAction(id, reason: reason, completer: c),
    );
    if (!mounted) return;
    if (result.ok) {
      final number = mapOf(result.data)['prescriptionNumber'];
      _id.clear();
      _reason.clear();
      setState(() =>
          _outcome = _Outcome(ok: true, message: 'Claim reverted on prescription ${number ?? id}.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ToolCard(
      icon: Icons.undo_rounded,
      title: 'Revert Prescription Claim',
      description: 'Takes a prescription back from the pharmacy that claimed it.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LabeledField(label: 'Prescription ID', required: true, child: AdminTextInput(controller: _id)),
        const SizedBox(height: 12),
        LabeledField(
            label: 'Reason',
            required: true,
            child: AdminTextInput(controller: _reason, hint: 'Why the claim is being reverted', maxLines: 2)),
        const SizedBox(height: 14),
        PendingBuilder(
          mutationKey: 'maintenance.revertClaim',
          builder: (_, busy) => PrimaryButton(
              label: 'Revert Claim', icon: Icons.undo_rounded, busy: busy, color: AppColors.danger, onPressed: _run),
        ),
        if (_outcome != null) _outcome!,
      ]),
    );
  }
}

class _StripeTool extends StatefulWidget {
  const _StripeTool();

  @override
  State<_StripeTool> createState() => _StripeToolState();
}

class _StripeToolState extends State<_StripeTool> {
  _Outcome? _outcome;
  DateTime? _checkedAt;

  Future<void> _run() async {
    final result = await runAdminMutation(context, (c) => TestStripeConnectionAction(completer: c));
    if (!mounted || !result.ok) return;
    final body = mapOf(result.data);
    final ok = body['success'] == true;
    final parts = [body['message'], if (!ok) body['error']]
        .where((v) => v != null && '$v'.isNotEmpty)
        .join(' — ');
    setState(() {
      _checkedAt = DateTime.now();
      _outcome = _Outcome(
        ok: ok,
        message: parts.isNotEmpty ? parts : (ok ? 'Stripe is reachable.' : 'Stripe could not be reached.'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolCard(
      icon: Icons.credit_card_outlined,
      title: 'Stripe Connection',
      description: 'Checks that the server can reach Stripe with its configured keys.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PendingBuilder(
          mutationKey: 'maintenance.stripeTest',
          builder: (_, busy) =>
              PrimaryButton(label: 'Test Connection', icon: Icons.wifi_tethering, busy: busy, onPressed: _run),
        ),
        if (_outcome != null) _outcome!,
        if (_checkedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Checked ${formatDate(_checkedAt!.toIso8601String(), withTime: true)}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ),
      ]),
    );
  }
}

class _LogsTool extends StatefulWidget {
  const _LogsTool();

  @override
  State<_LogsTool> createState() => _LogsToolState();
}

class _LogsToolState extends State<_LogsTool> {
  int _lines = 100;

  void _load() => loadAdmin(context, AdminResource.systemLogs, params: {'lines': _lines}, force: true);

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Server Logs',
      subtitle: 'The most recent lines of today\'s application log',
      trailing: Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilterPills<int>(
          options: const [(50, '50'), (100, '100'), (250, '250'), (500, '500')],
          selected: _lines,
          onSelected: (v) {
            setState(() => _lines = v);
            _load();
          },
        ),
        PrimaryButton(label: 'Load Logs', icon: Icons.download_rounded, onPressed: _load),
      ]),
      child: AdminResourceBuilder(
        resource: AdminResource.systemLogs,
        builder: (context, data) => AsyncContent(
          data: data,
          idleMessage: 'Load the logs to view them here.',
          onRetry: () => reloadAdmin(context, AdminResource.systemLogs),
          builder: (raw) => _LogView(entries: raw is List ? raw : const []),
        ),
      ),
    );
  }
}

class _LogView extends StatelessWidget {
  final List<dynamic> entries;
  const _LogView({required this.entries});

  static Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return const Color(0xFFFF8A8A);
      case 'warn':
      case 'warning':
        return const Color(0xFFF2C46D);
      case 'debug':
        return const Color(0xFF8A97A0);
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(message: 'No log lines for today yet.', icon: Icons.notes_outlined);
    }
    // Newest first, so the latest problem is at the top.
    final lines = entries.reversed.toList();
    return Container(
      height: 420,
      decoration: BoxDecoration(color: AppColors.chipBlack, borderRadius: BorderRadius.circular(12)),
      child: Scrollbar(
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: lines.length,
          itemBuilder: (context, i) {
            final e = lines[i];
            final m = mapOf(e);
            final level = '${m['level'] ?? 'info'}';
            final time = m['timestamp'] ?? m['time'];
            final message = m['message'] ?? m['msg'] ?? m['raw'] ?? e;
            final extra = m.entries
                .where((x) => !{'level', 'timestamp', 'time', 'message', 'msg', 'raw'}.contains(x.key))
                .map((x) => '${x.key}=${x.value is Map || x.value is List ? '…' : x.value}')
                .join(' ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SelectableText.rich(
                TextSpan(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.45, color: Color(0xFFE6EDF0)),
                  children: [
                    if (time != null)
                      TextSpan(text: '${formatValue(time)}  ', style: const TextStyle(color: Color(0xFF8A97A0))),
                    TextSpan(
                        text: '${level.toUpperCase().padRight(5)}  ',
                        style: TextStyle(color: _levelColor(level), fontWeight: FontWeight.w700)),
                    TextSpan(text: '$message'),
                    if (extra.isNotEmpty)
                      TextSpan(text: '  $extra', style: const TextStyle(color: Color(0xFF8A97A0))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
