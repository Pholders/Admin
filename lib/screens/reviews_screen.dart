import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/admin/record_details.dart';
import '../widgets/admin/records_ui.dart';

/// Doctor reviews, from `GET /admin/reviews`. Hiding is the main moderation
/// action; deleting is permanent and sits behind a confirmation.
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RecordListScreen(
      currentPage: 'Doctor Reviews',
      title: 'Doctor Reviews',
      subtitle: 'What patients have written about their doctors',
      note: 'A hidden review leaves the doctor\'s public page, review count and average rating. '
          'The patient who wrote it still sees it.',
      resource: AdminResource.reviews,
      listKey: 'reviews',
      noun: 'reviews',
      filters: [
        ChoiceFilter('rating', 'Rating', [for (var i = 5; i >= 1; i--) ('$i', '$i ★')], width: 120),
        const ChoiceFilter('hidden', 'Visibility', [('false', 'Visible'), ('true', 'Hidden')], width: 140),
        const IdFilter('doctor_id', 'Doctor ID'),
        const IdFilter('patient_id', 'Patient ID'),
      ],
      onRowTap: (context, r) => showReviewDetail(context, r),
      actionsWidth: 80,
      actions: (context, r) => Row(children: [
        r['is_hidden'] == true
            ? RowIconButton(
                icon: Icons.visibility_outlined, tooltip: 'Show again', onPressed: () => showReview(context, r))
            : RowIconButton(
                icon: Icons.visibility_off_outlined, tooltip: 'Hide', onPressed: () => hideReview(context, r)),
        RowIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete permanently',
            color: AppColors.danger,
            onPressed: () => deleteReview(context, r)),
      ]),
      columns: (_) => [
        RecordColumn('Rating', width: 100, cell: (r) => _Stars(numOf(r['rating'])?.toInt() ?? 0)),
        RecordColumn('Review', width: 320,
            cell: (r) => Text(formatValue(r['review_text']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
        RecordColumn('Doctor', width: 180, cell: (r) => personCell(r, 'doctor')),
        RecordColumn('Patient', width: 180,
            cell: (r) => CellText(formatValue(r['patient_name']),
                subtitle: [
                  if (r['patient_id'] != null) '#${r['patient_id']}',
                  if (r['is_verified'] == true) 'Verified visit',
                ].join(' · '))),
        RecordColumn('Visibility', width: 160,
            cell: (r) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusBadge(r['is_hidden'] == true ? 'hidden' : 'visible'),
                    if (r['is_hidden'] == true && r['hidden_reason'] != null)
                      Text('${r['hidden_reason']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                )),
        RecordColumn('Written', width: 150, cell: (r) => dateCell(r['created_at'])),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars(this.rating);

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 15, color: i <= rating ? const Color(0xFFE0A83C) : AppColors.textMuted),
      ]);
}

/// Asks for the reason (required, at most 500 characters), then hides.
Future<bool> hideReview(BuildContext context, Map<String, dynamic> review) async {
  final reason = await showDialog<String>(context: context, builder: (_) => const _HideReasonDialog());
  if (reason == null || !context.mounted) return false;
  final result = await runAdminMutation(
    context,
    (c) => SetReviewVisibilityAction(review['id'], hidden: true, reason: reason, completer: c),
    success: 'Review hidden.',
  );
  return result.ok;
}

Future<bool> showReview(BuildContext context, Map<String, dynamic> review) async {
  final result = await runAdminMutation(
    context,
    (c) => SetReviewVisibilityAction(review['id'], hidden: false, completer: c),
    success: 'Review is visible again.',
  );
  return result.ok;
}

Future<bool> deleteReview(BuildContext context, Map<String, dynamic> review) async {
  final ok = await confirmAdmin(
    context,
    title: 'Delete this review permanently?',
    message: 'This cannot be undone. To take it off the doctor\'s page but keep a record, hide it instead.',
    confirmLabel: 'Delete permanently',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  final result = await runAdminMutation(
    context,
    (c) => DeleteReviewAction(review['id'], completer: c),
    success: 'Review deleted.',
  );
  return result.ok;
}

class _HideReasonDialog extends StatefulWidget {
  const _HideReasonDialog();

  @override
  State<_HideReasonDialog> createState() => _HideReasonDialogState();
}

class _HideReasonDialogState extends State<_HideReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _reason,
      builder: (context, value, _) => AdminDialog(
        title: 'Hide this review?',
        subtitle: 'It leaves the doctor\'s public page, review count and rating.',
        width: 520,
        actions: [
          SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          PrimaryButton(
            label: 'Hide review',
            icon: Icons.visibility_off_outlined,
            onPressed: value.text.trim().isEmpty ? null : () => Navigator.pop(context, value.text.trim()),
          ),
        ],
        child: LabeledField(
          label: 'Reason (${value.text.length} / ${SetReviewVisibilityAction.maxReasonLength})',
          required: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.contentBackground, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _reason,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              inputFormatters: [LengthLimitingTextInputFormatter(SetReviewVisibilityAction.maxReasonLength)],
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. Abusive language',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showReviewDetail(BuildContext context, Map<String, dynamic> r) => showAdminDetail(
      context,
      (dialogContext) {
        final hidden = r['is_hidden'] == true;
        Future<void> act(Future<bool> Function(BuildContext, Map<String, dynamic>) action) async {
          if (await action(dialogContext, r) && dialogContext.mounted) closeAdminDetail(dialogContext);
        }

        return AdminDialog(
          title: 'Review of ${r['doctor_name'] ?? 'doctor #${r['doctor_id']}'}',
          subtitle: 'By ${r['patient_name'] ?? 'patient #${r['patient_id']}'} · ${formatDate(r['created_at'], withTime: true)}',
          width: 640,
          actions: [
            SecondaryButton(label: 'Delete permanently', icon: Icons.delete_outline, onPressed: () => act(deleteReview)),
            if (hidden)
              PrimaryButton(label: 'Show again', icon: Icons.visibility_outlined, onPressed: () => act(showReview))
            else
              PrimaryButton(label: 'Hide', icon: Icons.visibility_off_outlined, onPressed: () => act(hideReview)),
          ],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Stars(numOf(r['rating'])?.toInt() ?? 0),
              const SizedBox(width: 10),
              statusBadge(hidden ? 'hidden' : 'visible'),
              if (r['is_verified'] == true) ...[const SizedBox(width: 8), statusBadge('verified')],
            ]),
            const SizedBox(height: 14),
            PlainTextBlock('${r['review_text'] ?? '(No text)'}'),
            if (hidden) ...[
              const SizedBox(height: 16),
              FactGrid([
                FactGrid.text('Hidden', formatDate(r['hidden_at'], withTime: true)),
                FactGrid.text('Hidden by', r['hidden_by'] == null ? null : 'Admin #${r['hidden_by']}'),
                FactGrid.text('Reason', r['hidden_reason']),
              ]),
            ],
          ]),
        );
      },
    );
