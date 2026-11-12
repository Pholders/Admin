import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../core/error/failures.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';
import '../widgets/common/status_badge.dart';

/// The support inbox, from `GET /admin/support/tickets`. The server sorts it
/// as an inbox (open first, then in progress; urgent first; newest first)
/// and it is shown in that order.
class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RecordListScreen(
      currentPage: 'Support Tickets',
      title: 'Support Tickets',
      subtitle: 'Open tickets first, then in progress; most urgent and newest at the top',
      note: 'Replies are emailed. If the person answers the email, it goes to the support inbox, not back into the ticket.',
      resource: AdminResource.supportTickets,
      listKey: 'tickets',
      noun: 'tickets',
      filters: [
        ChoiceFilter.values('status', 'Status', UpdateTicketAction.statuses),
        ChoiceFilter.values('priority', 'Priority', UpdateTicketAction.priorities),
        ChoiceFilter.values('category', 'Category',
            const ['general', 'billing', 'medical', 'technical', 'account', 'contact']),
        const TextFilter('search', 'Search', hint: 'Subject or email, then Enter'),
      ],
      onRowTap: (context, r) => showTicketDetail(context, r['id'], row: r),
      columns: (_) => [
        RecordColumn('Ticket', width: 80, cell: (r) => CellText('#${r['id']}', strong: true)),
        RecordColumn('Subject', width: 280,
            cell: (r) => CellText(formatValue(r['subject']), strong: true, subtitle: ticketFrom(r))),
        RecordColumn('Category', width: 110, cell: (r) => CellText(humanize('${r['category'] ?? ''}'))),
        const RecordColumn('Priority', width: 100, field: 'priority', cell: _priorityCell),
        const RecordColumn('Status', field: 'status', width: 120),
        RecordColumn('Replies', width: 80, cell: (r) => CellText(formatValue(r['reply_count']))),
        RecordColumn('Received', width: 160, cell: (r) => dateCell(r['created_at'])),
        RecordColumn('Updated', width: 160, cell: (r) => dateCell(r['updated_at'])),
      ],
    );
  }
}

Widget _priorityCell(Map<String, dynamic> r) => statusBadge(r['priority']);

/// `"Thandi Nkosi · thandi@example.com"`, or `"Guest · …"` when the ticket
/// came from someone who wasn't signed in (`patient_id` null).
String ticketFrom(Map<String, dynamic> r) {
  final name = personName(r, fallbacks: const []);
  final who = name == '—' ? (r['patient_id'] == null ? 'Guest' : 'Patient #${r['patient_id']}') : name;
  return [who, if (r['email'] != null) '${r['email']}'].join(' · ');
}

Future<void> showTicketDetail(BuildContext context, Object id,
        {Map<String, dynamic> row = const {}}) =>
    showAdminDetail(context, (_) => _TicketDialog(id: id, row: row));

class _TicketDialog extends StatelessWidget {
  final Object id;
  final Map<String, dynamic> row;
  const _TicketDialog({required this.id, required this.row});

  @override
  Widget build(BuildContext context) {
    return RecordDetailLoader(
      kind: AdminRecordKind.supportTicket,
      id: id,
      row: row,
      builder: (context, s) => _TicketBody(id: id, state: s),
    );
  }
}

class _TicketBody extends StatefulWidget {
  final Object id;
  final RecordDetailState state;
  const _TicketBody({required this.id, required this.state});

  @override
  State<_TicketBody> createState() => _TicketBodyState();
}

class _TicketBodyState extends State<_TicketBody> {
  final _reply = TextEditingController();
  bool _sending = false;
  bool _updating = false;

  Map<String, dynamic> get _ticket => widget.state.record;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _update({String? status, String? priority}) async {
    setState(() => _updating = true);
    final result = await runAdminMutation(
      context,
      (c) => UpdateTicketAction(widget.id, status: status, priority: priority, completer: c),
      success: status != null ? 'Ticket marked ${humanize(status).toLowerCase()}.' : 'Priority set to $priority.',
    );
    if (!mounted) return;
    setState(() => _updating = false);
    // The response is the whole ticket, replies included.
    if (result.ok && result.data is Map) widget.state.replace(mapOf(result.data));
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final store = StoreProvider.of<AppState>(context, listen: false);
    final completer = Completer<dynamic>();
    setState(() => _sending = true);
    store.dispatch(ReplyToTicketAction(widget.id, text, completer: completer));
    try {
      final data = mapOf(await completer.future);
      if (!mounted) return;
      _reply.clear();
      if (data['ticket'] is Map) widget.state.replace(mapOf(data['ticket']));
      if (data['email_sent'] == false) {
        // Saved but not emailed. Not resent: that would save a duplicate.
        showAdminSnack(messenger, 'Reply saved, but the email could not be sent.', isWarning: true);
      } else {
        showAdminSnack(messenger, 'Reply sent to ${_ticket['email'] ?? 'the sender'}.');
      }
    } catch (e) {
      final message = e is Failure ? e.message : 'The reply could not be sent.';
      showAdminSnack(messenger, message, isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _ticket;
    final status = '${t['status'] ?? ''}';
    final closed = status == 'closed';
    final replies = recordsOf(t['replies']);

    return AdminDialog(
      title: '${t['subject'] ?? 'Ticket #${widget.id}'}',
      subtitle: '#${widget.id} · ${humanize('${t['category'] ?? ''}')} · ${ticketFrom(t)}',
      width: 860,
      actions: [PrimaryButton(label: 'Done', onPressed: () => closeAdminDetail(context))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        widget.state.statusBar,
        Wrap(spacing: 14, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end, children: [
          SizedBox(
            width: 180,
            child: LabeledField(
              label: 'Status',
              child: AdminDropdown<String>(
                value: status,
                items: [for (final s in UpdateTicketAction.statuses) (s, humanize(s))],
                onChanged: (v) => (v == null || v == status || _updating) ? null : _update(status: v),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: LabeledField(
              label: 'Priority',
              child: AdminDropdown<String>(
                value: '${t['priority'] ?? ''}',
                items: [for (final p in UpdateTicketAction.priorities) (p, humanize(p))],
                onChanged: (v) => (v == null || v == t['priority'] || _updating) ? null : _update(priority: v),
              ),
            ),
          ),
          if (_updating)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ]),
        const SizedBox(height: 16),
        FactGrid([
          FactGrid.text('Email', t['email']),
          FactGrid.text('Account', t['patient_id'] == null ? 'Not signed in' : 'Patient #${t['patient_id']}'),
          FactGrid.text('Received', formatDate(t['created_at'], withTime: true)),
          FactGrid.text('Resolved', formatDate(t['resolved_at'], withTime: true)),
          FactGrid.text('IP address', t['ip_address']),
          FactGrid.text('Browser', t['user_agent']),
        ], tileWidth: 252),
        const SizedBox(height: 20),
        const SubHeading('Message'),
        // Plain text: line breaks kept, never rendered as markup.
        PlainTextBlock('${t['message'] ?? (widget.state.loading ? 'Loading…' : '—')}'),
        const SizedBox(height: 20),
        SubHeading('Replies (${replies.length})'),
        if (replies.isEmpty)
          const Text('No replies yet.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
        else
          for (final r in replies) _ReplyBubble(reply: r),
        const SizedBox(height: 16),
        if (closed)
          const ErrorPanel(
            message: 'This ticket is closed. Set its status to Open or In progress to reply.',
            compact: true,
          )
        else
          _Composer(controller: _reply, sending: _sending, onSend: _send,
              note: status == 'open' ? 'Replying moves this ticket to In progress.' : null),
      ]),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final Map<String, dynamic> reply;
  const _ReplyBubble({required this.reply});

  @override
  Widget build(BuildContext context) {
    final notEmailed = reply['email_sent'] == false;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.activeNavBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              '${reply['admin_name'] ?? 'Admin'} · ${formatDate(reply['created_at'], withTime: true)}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          if (notEmailed)
            const Tooltip(
              message: 'Saved, but the email could not be sent',
              child: StatusBadge(status: 'Not emailed', color: Color(0xFFE0A83C)),
            ),
        ]),
        const SizedBox(height: 6),
        SelectableText('${reply['message'] ?? ''}',
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
      ]),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final String? note;

  const _Composer({required this.controller, required this.sending, required this.onSend, this.note});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SubHeading('Reply'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: AppColors.contentBackground, borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 10,
          enabled: !sending,
          inputFormatters: [LengthLimitingTextInputFormatter(ReplyToTicketAction.maxLength)],
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Write a reply. It is emailed as plain text.',
            hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      ),
      const SizedBox(height: 10),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Row(children: [
          Expanded(
            child: Text(
              [
                '${value.text.length} / ${ReplyToTicketAction.maxLength}',
                if (note != null) note!,
              ].join(' · '),
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          PrimaryButton(
            label: 'Send reply',
            icon: Icons.send_outlined,
            busy: sending,
            onPressed: value.text.trim().isEmpty ? null : onSend,
          ),
        ]),
      ),
    ]);
  }
}
