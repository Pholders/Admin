import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../../core/error/failures.dart';
import '../../theme/app_colors.dart';
import '../common/status_badge.dart';
import '../common/table_cell.dart';
import '../dashboard/stat_card.dart';
import 'admin_format.dart';
import 'detail_host.dart';

export 'detail_host.dart' show showAdminDetail, closeAdminDetail, AdminDetailHost;

// ─── Store bindings ───────────────────────────────────────────────────────────

/// Loads [resource] with [params] unless that exact request is already in the
/// store — so switching tabs back and forth doesn't refetch every time.
void loadAdmin(BuildContext context, AdminResource resource,
    {Map<String, dynamic> params = const {}, bool force = false}) {
  final store = StoreProvider.of<AppState>(context, listen: false);
  final slot = store.state.adminState.of(resource);
  if (!force && !slot.isIdle && sameParams(slot.params, params)) return;
  store.dispatch(FetchAdminResourceAction(resource, params: params));
}

/// Params for "every pharmacy" lookups (dropdowns, agreement party names).
/// They match the first page of the Pharmacies screen, so the two share one
/// request instead of replacing each other's data.
const pharmacyListParams = <String, dynamic>{'limit': 200, 'offset': 0};

/// Reloads [resource] with the params it was last loaded with.
void reloadAdmin(BuildContext context, AdminResource resource) {
  final store = StoreProvider.of<AppState>(context, listen: false);
  final slot = store.state.adminState.of(resource);
  store.dispatch(FetchAdminResourceAction(resource, params: slot.params));
}

/// Rebuilds with the current [RemoteData] for [resource]. When [load] is
/// given, the resource is fetched with those params as the widget mounts.
class AdminResourceBuilder extends StatelessWidget {
  final AdminResource resource;
  final Map<String, dynamic>? load;
  final Widget Function(BuildContext context, RemoteData data) builder;

  const AdminResourceBuilder({
    super.key,
    required this.resource,
    required this.builder,
    this.load,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RemoteData>(
      converter: (store) => store.state.adminState.of(resource),
      distinct: true,
      onInit: load == null
          ? null
          : (store) {
              final slot = store.state.adminState.of(resource);
              if (slot.isIdle || !sameParams(slot.params, load!)) {
                store.dispatch(
                    FetchAdminResourceAction(resource, params: load!));
              }
            },
      builder: builder,
    );
  }
}

/// Rebuilds with whether the mutation [mutationKey] is running.
class PendingBuilder extends StatelessWidget {
  final String mutationKey;
  final Widget Function(BuildContext context, bool pending) builder;

  const PendingBuilder(
      {super.key, required this.mutationKey, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, bool>(
      converter: (store) => store.state.adminState.isPending(mutationKey),
      distinct: true,
      builder: builder,
    );
  }
}

/// Dispatches the action [build] makes, waits for it, and reports the outcome
/// in a snackbar. [success] may use the response data to word the message.
Future<({bool ok, dynamic data})> runAdminMutation(
  BuildContext context,
  AdminMutationAction Function(Completer<dynamic> completer) build, {
  String? success,
  String Function(dynamic data)? successFrom,
}) async {
  final store = StoreProvider.of<AppState>(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final completer = Completer<dynamic>();
  store.dispatch(build(completer));
  try {
    final data = await completer.future;
    final message = successFrom?.call(data) ?? success;
    if (message != null) showAdminSnack(messenger, message);
    return (ok: true, data: data);
  } catch (error) {
    showAdminSnack(
      messenger,
      error is Failure ? error.message : 'Something went wrong.',
      isError: true,
    );
    return (ok: false, data: null);
  }
}

/// [isWarning] is for an action that went through only in part, e.g. a
/// ticket reply that was saved but could not be emailed.
void showAdminSnack(ScaffoldMessengerState? messenger, String message,
    {bool isError = false, bool isWarning = false}) {
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? AppColors.danger
          : isWarning
              ? const Color(0xFFB7791F)
              : AppColors.chipBlack,
      behavior: SnackBarBehavior.floating,
      width: 420,
    ));
}

Future<bool> confirmAdmin(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AdminDialog(
      title: title,
      width: 480,
      actions: [
        SecondaryButton(
            label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
        PrimaryButton(
          label: confirmLabel,
          color: destructive ? AppColors.danger : AppColors.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      child: Text(message,
          style: const TextStyle(
              fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
    ),
  );
  return result ?? false;
}

// ─── Async states ─────────────────────────────────────────────────────────────

/// Loading, error and idle states around [builder]. Once data has arrived it
/// stays on screen during a reload, under a thin progress bar.
class AsyncContent extends StatelessWidget {
  final RemoteData data;
  final VoidCallback? onRetry;
  final Widget Function(dynamic data) builder;
  final String idleMessage;

  /// Give [builder]'s widget all the remaining height, for content that
  /// scrolls itself (a sticky-header table). Needs a bounded parent height.
  final bool expand;

  const AsyncContent({
    super.key,
    required this.data,
    required this.builder,
    this.onRetry,
    this.idleMessage = 'Nothing loaded yet.',
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isIdle) return EmptyState(message: idleMessage);
    if (!data.hasData) {
      if (data.hasError) {
        final panel = ErrorPanel(message: data.error!, onRetry: onRetry);
        return expand ? Align(alignment: Alignment.topCenter, child: panel) : panel;
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.activeNavBackground,
            ),
          ),
        if (data.hasError) ...[
          ErrorPanel(message: data.error!, onRetry: onRetry, compact: true),
          const SizedBox(height: 12),
        ],
        if (expand) Expanded(child: builder(data.data)) else builder(data.data),
      ],
    );
  }
}

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorPanel(
      {super.key, required this.message, this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textPrimary)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Retry', style: TextStyle(fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState(
      {super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Never rendered, whatever an endpoint returns. Group detail, for one, lists
/// member pharmacies as `p.*`, which includes `password_hash`.
bool isHiddenKey(String key) {
  final k = key.toLowerCase();
  return k.contains('password') || k.contains('token') || k.contains('secret');
}

// ─── Layout ───────────────────────────────────────────────────────────────────

/// The white rounded card every screen section sits in.
class SectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  /// Stretch [child] to fill the card's height. The card itself must then
  /// have a bounded height (e.g. inside an [Expanded]).
  final bool expand;

  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || trailing != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title!,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (expand) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// A bold label above a block inside a card or dialog.
class SubHeading extends StatelessWidget {
  final String text;
  const SubHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      );
}

/// Stat cards in a row that wraps on narrow windows, sized like the
/// Pharmacies screen's.
class StatGrid extends StatelessWidget {
  final List<StatCardData> stats;
  final int perRow;

  const StatGrid({super.key, required this.stats, this.perRow = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 14.0;
      final columns = constraints.maxWidth > 900 ? perRow : 2;
      final width =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final stat in stats)
            SizedBox(width: width.clamp(180, 600), child: StatCard(data: stat)),
        ],
      );
    });
  }
}

/// Label/value tiles for one record.
class KeyValueGrid extends StatelessWidget {
  final Map<String, dynamic> values;
  final Set<String> exclude;
  final Map<String, String Function(dynamic)> formatters;
  final double tileWidth;

  const KeyValueGrid({
    super.key,
    required this.values,
    this.exclude = const {},
    this.formatters = const {},
    this.tileWidth = 210,
  });

  @override
  Widget build(BuildContext context) {
    final entries = values.entries
        .where((e) => !exclude.contains(e.key) && !isHiddenKey(e.key))
        .where((e) => e.value is! Map && e.value is! List)
        .toList();
    if (entries.isEmpty) return const EmptyState(message: 'No details.');
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final e in entries)
          Container(
            width: tileWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.contentBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(humanize(e.key),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 3),
                Text(
                  formatters[e.key]?.call(e.value) ?? formatValue(e.value),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Tables ───────────────────────────────────────────────────────────────────

class RecordColumn {
  final String label;
  final double width;

  /// The row key shown by default. Keys ending in `status` render as a
  /// [StatusBadge].
  final String? field;
  final Widget Function(Map<String, dynamic> row)? cell;

  const RecordColumn(this.label,
      {this.field, this.width = 140, this.cell});
}

/// A data table in the app's table style. With [columns] omitted, columns are
/// derived from the rows' own keys — used for payloads whose columns follow
/// backend SQL that may change.
class RecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final List<RecordColumn>? columns;
  final Widget Function(Map<String, dynamic> row)? actions;
  final double actionsWidth;
  final void Function(Map<String, dynamic> row)? onRowTap;
  final String emptyMessage;
  final int maxAutoColumns;

  /// Keep the column headings in place and scroll only the rows. Needs a
  /// bounded parent height; see [ScrollableTable.stickyHeader].
  final bool stickyHeader;

  const RecordTable({
    super.key,
    required this.rows,
    this.columns,
    this.actions,
    this.actionsWidth = 120,
    this.onRowTap,
    this.emptyMessage = 'No records yet.',
    this.maxAutoColumns = 8,
    this.stickyHeader = false,
  });

  List<RecordColumn> get _columns {
    if (columns != null) return columns!;
    final keys = <String>[];
    for (final row in rows.take(20)) {
      for (final e in row.entries) {
        if (e.value is Map || keys.contains(e.key) || isHiddenKey(e.key)) {
          continue;
        }
        if (e.value is List && (e.value as List).any((v) => v is Map)) {
          continue;
        }
        keys.add(e.key);
      }
    }
    return [
      for (final key in keys.take(maxAutoColumns))
        RecordColumn(humanize(key),
            field: key, width: key == 'id' || key.endsWith('_id') ? 90 : 150),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      final empty = EmptyState(message: emptyMessage);
      return stickyHeader ? Align(alignment: Alignment.topCenter, child: empty) : empty;
    }
    final cols = _columns;
    final minWidth = cols.fold<double>(0, (sum, c) => sum + c.width) +
        (actions == null ? 0 : actionsWidth);

    return ScrollableTable(
      minWidth: minWidth,
      stickyHeader: stickyHeader,
      header: Row(
        children: [
          for (final c in cols) AppTableHeaderCell(label: c.label, width: c.width),
          if (actions != null)
            AppTableHeaderCell(label: 'Actions', width: actionsWidth),
        ],
      ),
      rows: [
        for (final row in rows)
          _TableRow(
            onTap: onRowTap == null ? null : () => onRowTap!(row),
            child: Row(
              children: [
                for (final c in cols)
                  AppTableCell(
                    width: c.width,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: c.cell?.call(row) ?? _defaultCell(c, row),
                    ),
                  ),
                if (actions != null)
                  AppTableCell(width: actionsWidth, child: actions!(row)),
              ],
            ),
          ),
      ],
    );
  }

  static Widget _defaultCell(RecordColumn c, Map<String, dynamic> row) {
    final value = c.field == null ? null : row[c.field];
    if (c.field != null && c.field!.endsWith('status') && value != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: StatusBadge(status: humanize(value.toString())),
      );
    }
    return CellText(formatValue(value));
  }
}

class _TableRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TableRow({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Table cell text in the app's secondary style.
class CellText extends StatelessWidget {
  final String text;
  final bool strong;
  final String? subtitle;

  const CellText(this.text, {super.key, this.strong = false, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final main = Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: strong ? 13 : 12.5,
        color: strong ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      ),
    );
    if (subtitle == null) return main;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        const SizedBox(height: 2),
        Text(subtitle!,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

/// A small icon button for table rows.
class RowIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  const RowIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon,
              size: 16, color: onPressed == null ? AppColors.textMuted : color),
        ),
      ),
    );
  }
}

// ─── Controls ─────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final Color color;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          else if (icon != null)
            Icon(icon, size: 16),
          if (busy || icon != null) const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton(
      {super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// A row of pill filters; the selected one is filled black like the app's
/// other chips. A `null` value is the "All" option.
class FilterPills<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const FilterPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          _Pill(
            label: label,
            selected: value == selected,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.chipBlack : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Forms ────────────────────────────────────────────────────────────────────

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;

  const LabeledField(
      {super.key,
      required this.label,
      required this.child,
      this.required = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(text: label, children: [
            if (required)
              const TextSpan(
                  text: ' *', style: TextStyle(color: AppColors.danger)),
          ]),
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

BoxDecoration get _inputDecoration => BoxDecoration(
      color: AppColors.contentBackground,
      borderRadius: BorderRadius.circular(10),
    );

class AdminTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  const AdminTextInput({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: maxLines == 1 ? 42 : 84),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      alignment: Alignment.centerLeft,
      decoration: _inputDecoration,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        onSubmitted: onSubmitted,
        style: TextStyle(
            fontSize: 13,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle:
              const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class AdminDropdown<T> extends StatelessWidget {
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final String hint;

  const AdminDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select',
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = items.any((i) => i.$1 == value);
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _inputDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: hasValue ? value : null,
          isExpanded: true,
          hint: Text(hint,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final (v, label) in items)
              DropdownMenuItem<T>(
                  value: v,
                  child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// A date field that opens the date picker. Shows and returns local dates;
/// use [apiDate] to send one.
class AdminDateInput extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hint;
  final bool clearable;

  const AdminDateInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Pick a date',
    this.clearable = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 10),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _inputDecoration,
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? hint : formatDate(apiDate(value!)),
                style: TextStyle(
                    fontSize: 13,
                    color: value == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary),
              ),
            ),
            if (clearable && value != null)
              InkWell(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close,
                    size: 15, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lays form fields out two per row on wide dialogs, one per row otherwise.
class FormGrid extends StatelessWidget {
  final List<Widget> children;

  const FormGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final twoUp = constraints.maxWidth > 460;
      final width =
          twoUp ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    });
  }
}

/// The app's dialog frame: white, rounded, title row with a close button,
/// scrollable body, actions on the right.
class AdminDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double width;

  const AdminDialog({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.width = 620,
  });

  @override
  Widget build(BuildContext context) {
    // Opened with showAdminDetail inside a screen: fill the table's place.
    final inline = AdminDetailScope.maybeOf(context);
    if (inline != null) {
      return _InlineDetailPanel(
        title: title,
        subtitle: subtitle,
        actions: actions,
        nested: inline.depth > 0,
        child: child,
      );
    }
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => closeAdminDetail(context),
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Flexible(child: SingleChildScrollView(child: child)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 22),
                // Wrap, not Row: long labels on a narrow dialog drop to a
                // second line instead of overflowing.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// [AdminDialog]'s look when it is shown in place of a table: a full-height
/// card with Back above the title, the body scrolling, and the actions
/// pinned at the bottom.
class _InlineDetailPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// Opened from another detail, so Back returns to that detail.
  final bool nested;

  const _InlineDetailPanel({
    required this.title,
    required this.child,
    required this.actions,
    required this.nested,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => closeAdminDetail(context),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(nested ? 'Back' : 'Back to list', style: const TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SectionCard(
            expand: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 18),
                Expanded(child: SingleChildScrollView(child: child)),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A screen-level title row with optional trailing controls, for screens that
/// don't use the search-centric [PageHeader].
class ScreenTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const ScreenTitle(
      {super.key,
      required this.title,
      required this.subtitle,
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          actions[i],
        ],
      ],
    );
  }
}

// ─── Pinned page layout ───────────────────────────────────────────────────────

/// Below this height there is no room to pin a page's header and still show
/// a useful number of rows, so the whole page scrolls instead.
const minPinnedHeight = 560.0;

/// A screen body whose [header] (title, filters, stats) stays put.
///
/// For a page built around one table, [body] gets `pinned: true` when there
/// is room, and must then fill the height it is given (see [TableCard]): the
/// table keeps its column headings and only its rows scroll. With
/// [sections], the body is several blocks that scroll together under the
/// pinned header. On a short window the whole page scrolls.
class PinnedPage extends StatelessWidget {
  final List<Widget> header;
  final Widget Function(bool pinned) body;
  final bool sections;

  const PinnedPage({
    super.key,
    required this.header,
    required this.body,
    this.sections = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final pinned = constraints.maxHeight >= minPinnedHeight;
      if (!pinned) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [...header, body(false)],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...header,
          Expanded(
            child: sections
                ? SingleChildScrollView(child: body(false))
                : body(true),
          ),
        ],
      );
    });
  }
}

/// A [SectionCard] around one table's [AsyncContent]. When [pinned], it fills
/// the remaining height of a [Column] and [builder] should build its table
/// with `stickyHeader: true`.
class TableCard extends StatelessWidget {
  final bool pinned;
  final RemoteData data;
  final VoidCallback? onRetry;
  final Widget Function(dynamic data) builder;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final String idleMessage;

  const TableCard({
    super.key,
    required this.pinned,
    required this.data,
    required this.builder,
    this.onRetry,
    this.title,
    this.subtitle,
    this.trailing,
    this.idleMessage = 'Nothing loaded yet.',
  });

  @override
  Widget build(BuildContext context) {
    final card = SectionCard(
      expand: pinned,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      child: AsyncContent(
        data: data,
        expand: pinned,
        onRetry: onRetry,
        idleMessage: idleMessage,
        builder: builder,
      ),
    );
    return pinned ? Expanded(child: card) : card;
  }
}
