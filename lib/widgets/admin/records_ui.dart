import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import '../../core/error/failures.dart';
import '../../theme/app_colors.dart';
import '../common/status_badge.dart';
import '../shell/app_shell.dart';
import 'admin_format.dart';
import 'admin_ui.dart';

/// Building blocks for the admin record screens (orders, payments,
/// appointments, prescriptions, tickets, reviews, security alerts): a filter
/// bar, a server-paginated list, and detail dialogs that fetch on open.

// ─── Filters ──────────────────────────────────────────────────────────────────

/// One control in a [RecordFilterBar]. The bar turns the controls into the
/// list endpoint's query params; an unset control sends nothing.
sealed class RecordFilter {
  final String label;
  const RecordFilter(this.label);
}

/// A dropdown over the values the backend accepts, plus "All".
class ChoiceFilter extends RecordFilter {
  final String key;
  final List<(String, String)> options;
  final double width;

  const ChoiceFilter(this.key, super.label, this.options, {this.width = 170});

  /// Options labelled by humanizing the values: `in_progress` → `In Progress`.
  ChoiceFilter.values(this.key, String label, List<String> values,
      {this.width = 170})
      : options = [for (final v in values) (v, humanize(v))],
        super(label);
}

/// A positive-integer id (patient, doctor, pharmacy). Applied on Enter or
/// when the field loses focus.
class IdFilter extends RecordFilter {
  final String key;
  const IdFilter(this.key, super.label);
}

/// Free text, applied on Enter.
class TextFilter extends RecordFilter {
  final String key;
  final int maxLength;
  final String? hint;
  const TextFilter(this.key, super.label, {this.maxLength = 100, this.hint});
}

/// `from`/`to` as South African calendar dates, both days included.
class DateRangeFilter extends RecordFilter {
  const DateRangeFilter(super.label);
}

/// A row of filter controls. [values] is the current query (without
/// limit/offset); [onChanged] receives the next one.
class RecordFilterBar extends StatefulWidget {
  final List<RecordFilter> filters;
  final Map<String, dynamic> values;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const RecordFilterBar({
    super.key,
    required this.filters,
    required this.values,
    required this.onChanged,
  });

  @override
  State<RecordFilterBar> createState() => _RecordFilterBarState();
}

class _RecordFilterBarState extends State<RecordFilterBar> {
  final _controllers = <String, TextEditingController>{};
  String? _error;

  TextEditingController _controller(String key) => _controllers.putIfAbsent(
      key, () => TextEditingController(text: widget.values[key]?.toString() ?? ''));

  @override
  void didUpdateWidget(RecordFilterBar old) {
    super.didUpdateWidget(old);
    // Keep text fields in step when a filter is set from outside (e.g.
    // "Clear filters", or drilling in from another tab).
    // Only fields whose value changed: a half-typed id must survive picking
    // a status in the dropdown next to it.
    for (final e in _controllers.entries) {
      if (old.values[e.key] == widget.values[e.key]) continue;
      final value = widget.values[e.key]?.toString() ?? '';
      if (e.value.text != value) e.value.text = value;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(String key, dynamic value) {
    final next = {...widget.values};
    if (value == null || value.toString().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    if (!sameParams(next, widget.values)) widget.onChanged(next);
  }

  void _applyId(IdFilter f) {
    final text = _controller(f.key).text.trim();
    if (text.isEmpty) {
      setState(() => _error = null);
      return _set(f.key, null);
    }
    final id = int.tryParse(text);
    if (id == null || id < 1) {
      setState(() => _error = '${f.label} must be a positive whole number.');
      return;
    }
    setState(() => _error = null);
    _set(f.key, id);
  }

  void _applyText(TextFilter f) =>
      _set(f.key, _controller(f.key).text.trim());

  DateTime? _date(String key) {
    final v = widget.values[key];
    return v == null ? null : DateTime.tryParse(v.toString());
  }

  /// Keeps `from` on or before `to` by moving the other end along, rather
  /// than sending a range the server would refuse.
  void _setDates(DateTime? from, DateTime? to) {
    if (from != null && to != null && from.isAfter(to)) to = from;
    final next = {...widget.values}
      ..remove('from')
      ..remove('to');
    if (from != null) next['from'] = apiDate(from);
    if (to != null) next['to'] = apiDate(to);
    if (!sameParams(next, widget.values)) widget.onChanged(next);
  }

  Widget _field(RecordFilter f) {
    switch (f) {
      case ChoiceFilter():
        return SizedBox(
          width: f.width,
          child: LabeledField(
            label: f.label,
            child: AdminDropdown<String?>(
              value: widget.values[f.key]?.toString(),
              items: [(null, 'All'), ...f.options],
              hint: 'All',
              onChanged: (v) => _set(f.key, v),
            ),
          ),
        );
      case IdFilter():
        return SizedBox(
          width: 130,
          child: LabeledField(
            label: f.label,
            child: Focus(
              onFocusChange: (has) => has ? null : _applyId(f),
              child: AdminTextInput(
                controller: _controller(f.key),
                hint: 'Any',
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _applyId(f),
              ),
            ),
          ),
        );
      case TextFilter():
        return SizedBox(
          width: 240,
          child: LabeledField(
            label: f.label,
            child: _LimitedInput(
              controller: _controller(f.key),
              hint: f.hint ?? 'Press Enter to search',
              maxLength: f.maxLength,
              onSubmitted: (_) => _applyText(f),
            ),
          ),
        );
      case DateRangeFilter():
        final from = _date('from');
        final to = _date('to');
        return LabeledField(
          label: f.label,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 160,
              child: AdminDateInput(
                value: from,
                hint: 'From',
                clearable: true,
                onChanged: (d) => _setDates(d, to),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(color: AppColors.textSecondary)),
            ),
            SizedBox(
              width: 160,
              child: AdminDateInput(
                value: to,
                hint: 'To',
                clearable: true,
                onChanged: (d) => _setDates(from, d),
              ),
            ),
          ]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final f in widget.filters) _field(f),
            if (widget.values.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  for (final c in _controllers.values) {
                    c.clear();
                  }
                  setState(() => _error = null);
                  widget.onChanged(const {});
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('Clear filters', style: TextStyle(fontSize: 12.5)),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          ErrorPanel(message: _error!, compact: true),
        ],
      ],
    );
  }
}

/// A one-line text input that refuses input past [maxLength].
class _LimitedInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final ValueChanged<String> onSubmitted;

  const _LimitedInput({
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
          prefixIconConstraints: const BoxConstraints(minWidth: 26),
        ),
      ),
    );
  }
}

// ─── Paged list ───────────────────────────────────────────────────────────────

/// One page of a list endpoint, with the server's `total` driving the count
/// and the page controls. Changing [filters] goes back to the first page.
class PagedRecordList extends StatefulWidget {
  static const defaultPageSize = 50;

  final AdminResource resource;

  /// Key of the row list in the response, e.g. `orders`.
  final String listKey;

  /// Plural noun for the count line and empty state, e.g. `orders`.
  final String noun;
  final Map<String, dynamic> filters;
  final List<RecordColumn> columns;
  final void Function(Map<String, dynamic> row)? onRowTap;
  final Widget Function(Map<String, dynamic> row)? actions;
  final double actionsWidth;
  final int pageSize;

  /// Shown above the table once data has arrived, e.g. summary cards built
  /// from the response body.
  final Widget Function(Map<String, dynamic> body, List<Map<String, dynamic>> rows)?
      header;

  const PagedRecordList({
    super.key,
    required this.resource,
    required this.listKey,
    required this.noun,
    required this.filters,
    required this.columns,
    this.onRowTap,
    this.actions,
    this.actionsWidth = 110,
    this.pageSize = defaultPageSize,
    this.header,
    this.expand = false,
  });

  /// Fill the remaining height and scroll only the table rows, under fixed
  /// column headings, with the page controls pinned below. Needs a bounded
  /// parent height (e.g. inside an [Expanded]).
  final bool expand;

  @override
  State<PagedRecordList> createState() => _PagedRecordListState();
}

class _PagedRecordListState extends State<PagedRecordList> {
  int _offset = 0;

  Map<String, dynamic> get _params =>
      {...widget.filters, 'limit': widget.pageSize, 'offset': _offset};

  @override
  void didUpdateWidget(PagedRecordList old) {
    super.didUpdateWidget(old);
    if (!sameParams(old.filters, widget.filters)) {
      _offset = 0;
      _loadAfterBuild();
    }
  }

  /// Dispatching mid-build would rebuild the store's listeners during this
  /// frame, so the fetch waits for the frame to finish.
  void _loadAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loadAdmin(context, widget.resource, params: _params);
    });
  }

  void _goTo(int offset) {
    setState(() => _offset = offset < 0 ? 0 : offset);
    loadAdmin(context, widget.resource, params: _params);
  }

  @override
  Widget build(BuildContext context) {
    return AdminResourceBuilder(
      resource: widget.resource,
      load: _params,
      builder: (context, data) {
        final body = mapOf(data.data);
        var rows = recordsOf(data.data, [widget.listKey]);
        // The envelope is `{total, limit, offset, <items>}`; if the items
        // arrive under another name, use the one list the body holds.
        if (rows.isEmpty && body[widget.listKey] == null) {
          final list = body.values.whereType<List>().firstOrNull;
          if (list != null) rows = recordsOf(list);
        }
        final total = (numOf(body['total']) ?? rows.length).toInt();
        final filtered = widget.filters.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.hasData && widget.header != null) ...[
              widget.header!(body, rows),
              const SizedBox(height: 18),
            ],
            _maybeExpanded(
             widget.expand,
             SectionCard(
              expand: widget.expand,
              child: AsyncContent(
                data: data,
                expand: widget.expand,
                onRetry: () => reloadAdmin(context, widget.resource),
                builder: (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _maybeExpanded(
                     widget.expand,
                     RecordTable(
                      stickyHeader: widget.expand,
                      rows: rows,
                      columns: widget.columns,
                      onRowTap: widget.onRowTap,
                      actions: widget.actions,
                      actionsWidth: widget.actionsWidth,
                      emptyMessage: filtered
                          ? 'No ${widget.noun} match these filters.'
                          : 'No ${widget.noun} yet.',
                     ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 12),
                      PageControls(
                        offset: _offset,
                        shown: rows.length,
                        total: total,
                        noun: widget.noun,
                        onPrevious: _offset == 0
                            ? null
                            : () => _goTo(_offset - widget.pageSize),
                        onNext: _offset + rows.length >= total
                            ? null
                            : () => _goTo(_offset + widget.pageSize),
                      ),
                    ],
                  ],
                ),
              ),
             ),
            ),
          ],
        );
      },
    );
  }

  static Widget _maybeExpanded(bool expand, Widget child) =>
      expand ? Expanded(child: child) : child;
}

/// "137 results · 1–50" with previous/next buttons.
class PageControls extends StatelessWidget {
  final int offset;
  final int shown;
  final int total;
  final String noun;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PageControls({
    super.key,
    required this.offset,
    required this.shown,
    required this.total,
    required this.noun,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final range = shown == 0 ? '' : ' · showing ${offset + 1}–${offset + shown}';
    return Row(children: [
      Expanded(
        child: Text('${formatNumber(total)} $noun$range',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ),
      RowIconButton(icon: Icons.chevron_left, tooltip: 'Previous page', onPressed: onPrevious),
      RowIconButton(icon: Icons.chevron_right, tooltip: 'Next page', onPressed: onNext),
    ]);
  }
}

// ─── Detail dialogs ───────────────────────────────────────────────────────────

/// Fetches one record through the middleware, outside the store.
Future<Map<String, dynamic>> fetchAdminRecord(
    BuildContext context, AdminRecordKind kind, Object id) async {
  final completer = Completer<dynamic>();
  StoreProvider.of<AppState>(context, listen: false)
      .dispatch(FetchAdminRecordAction(kind, id, completer));
  return mapOf(await completer.future);
}

/// Loads [kind]/[id] once as it opens and rebuilds through [builder] with the
/// list row merged under the full record. Until the record arrives, [row]'s
/// own fields show; a failure is shown above them.
class RecordDetailLoader extends StatefulWidget {
  final AdminRecordKind kind;
  final Object id;
  final Map<String, dynamic> row;
  final Widget Function(BuildContext context, RecordDetailState state) builder;

  const RecordDetailLoader({
    super.key,
    required this.kind,
    required this.id,
    required this.builder,
    this.row = const {},
  });

  @override
  State<RecordDetailLoader> createState() => RecordDetailState();
}

class RecordDetailState extends State<RecordDetailLoader> {
  late Map<String, dynamic> record = {...widget.row};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (error != null || !loading) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final full = await fetchAdminRecord(context, widget.kind, widget.id);
      if (!mounted) return;
      setState(() {
        record = {...widget.row, ...full};
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e is Failure ? e.message : 'Could not load this record.';
        loading = false;
      });
    }
  }

  void reload() => _load();

  /// Replaces the local copy with a record a write returned.
  void replace(Map<String, dynamic> next) => setState(() => record = next);

  /// Progress bar and error panel for the top of the dialog body.
  Widget get statusBar => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                  minHeight: 2, color: AppColors.primary, backgroundColor: AppColors.activeNavBackground),
            ),
          if (error != null) ...[
            ErrorPanel(
              message: widget.row.isEmpty
                  ? error!
                  : 'Showing the list details only — the full record could not be loaded: $error',
              compact: true,
              onRetry: reload,
            ),
            const SizedBox(height: 12),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) => widget.builder(context, this);
}

/// Label/value tiles in a fixed order, for detail dialogs.
class FactGrid extends StatelessWidget {
  final List<(String, Widget)> facts;
  final double tileWidth;

  const FactGrid(this.facts, {super.key, this.tileWidth = 210});

  /// A plain-text fact; null or empty shows `—`.
  static (String, Widget) text(String label, dynamic value) =>
      (label, _FactText(formatValue(value)));

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (label, value) in facts)
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
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 3),
                value,
              ],
            ),
          ),
      ],
    );
  }
}

class _FactText extends StatelessWidget {
  final String text;
  const _FactText(this.text);

  @override
  Widget build(BuildContext context) => SelectableText(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
}

/// A tappable fact value that opens another record.
class RecordLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const RecordLink(this.label, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return _FactText(label);
    return InkWell(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                  decoration: TextDecoration.underline)),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.open_in_new, size: 13, color: AppColors.primaryDark),
      ]),
    );
  }
}

/// A status value as a badge, humanized: `no-show` → `No Show`.
Widget statusBadge(dynamic value, {Color? color}) => Align(
      alignment: Alignment.centerLeft,
      child: StatusBadge(status: value == null ? '—' : humanize('$value'), color: color),
    );

/// `"Thandi Nkosi"` with `#8` underneath, for a person column.
Widget personCell(Map<String, dynamic> row, String prefix) => CellText(
      formatValue(row['${prefix}_name']),
      strong: true,
      subtitle: row['${prefix}_id'] == null ? null : '#${row['${prefix}_id']}',
    );

/// A timestamp cell in SAST.
Widget dateCell(dynamic value, {bool withTime = true}) =>
    CellText(formatDate(value, withTime: withTime));

// ─── Screen scaffold ──────────────────────────────────────────────────────────

/// Title, filters and a [PagedRecordList], for the record screens that are a
/// filtered list and nothing else.
class RecordListScreen extends StatefulWidget {
  final String currentPage;
  final String title;
  final String subtitle;
  final AdminResource resource;
  final String listKey;
  final String noun;
  final List<RecordFilter> filters;
  final Map<String, dynamic> initialFilters;
  final List<RecordColumn> Function(BuildContext context) columns;
  final void Function(BuildContext context, Map<String, dynamic> row)? onRowTap;
  final Widget Function(BuildContext context, Map<String, dynamic> row)? actions;
  final double actionsWidth;
  final Widget Function(Map<String, dynamic> body, List<Map<String, dynamic>> rows)? header;

  /// A note under the title, e.g. that the records are view-only.
  final String? note;

  const RecordListScreen({
    super.key,
    required this.currentPage,
    required this.title,
    required this.subtitle,
    required this.resource,
    required this.listKey,
    required this.noun,
    required this.filters,
    required this.columns,
    this.initialFilters = const {},
    this.onRowTap,
    this.actions,
    this.actionsWidth = 110,
    this.header,
    this.note,
  });

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  late Map<String, dynamic> _filters = {...widget.initialFilters};

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: widget.currentPage,
      body: LayoutBuilder(builder: (context, constraints) {
        // Pinned: title, note and filters stay put; only the table's rows
        // scroll, under its fixed column headings.
        final pinned = constraints.maxHeight >= minPinnedHeight;
        final list = PagedRecordList(
          resource: widget.resource,
          listKey: widget.listKey,
          noun: widget.noun,
          filters: _filters,
          columns: widget.columns(context),
          onRowTap: widget.onRowTap == null ? null : (r) => widget.onRowTap!(context, r),
          actions: widget.actions == null ? null : (r) => widget.actions!(context, r),
          actionsWidth: widget.actionsWidth,
          header: widget.header,
          expand: pinned,
        );
        final children = [
          ScreenTitle(
            title: widget.title,
            subtitle: widget.subtitle,
            actions: [
              SecondaryButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () => reloadAdmin(context, widget.resource)),
            ],
          ),
          if (widget.note != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(widget.note!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ]),
          ],
          const SizedBox(height: 18),
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: RecordFilterBar(
              filters: widget.filters,
              values: _filters,
              onChanged: (v) => setState(() => _filters = v),
            ),
          ),
          const SizedBox(height: 18),
          if (pinned) Expanded(child: list) else list,
        ];
        final column = Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
        return pinned ? column : SingleChildScrollView(child: column);
      }),
    );
  }
}
