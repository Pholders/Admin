import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/account_ui.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/common/page_header.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

/// The shared body of the Patients and Doctors screens: header with search,
/// stat cards, status filter, and the account table with View and status
/// actions.
///
/// One page of [pageSize] rows (the server's maximum) is loaded newest first.
/// Search, the status filter and the stat cards work on that page — which is
/// every account until there are more than [pageSize], and the screen says
/// so once there are.
class AccountDirectory extends StatefulWidget {
  static const pageSize = 200;

  final String role;
  final AdminResource resource;

  /// Key of the row list in the response, e.g. `patients`.
  final String listKey;
  final String pageTitle;
  final String subtitle;
  final String searchHint;
  final List<String> searchFields;

  /// Stat cards from the loaded rows. `total` is the server's count of every
  /// account; `filter` lets a card filter the table when clicked and show
  /// whether its filter is the one applied.
  final List<StatCardData> Function(
    List<Map<String, dynamic>> rows,
    int total,
    StatusFilter filter,
  ) stats;

  /// Table columns. `open` shows an account's View dialog.
  final List<RecordColumn> Function(
      void Function(Map<String, dynamic> row) open) columns;

  const AccountDirectory({
    super.key,
    required this.role,
    required this.resource,
    required this.listKey,
    required this.pageTitle,
    required this.subtitle,
    required this.searchHint,
    required this.searchFields,
    required this.stats,
    required this.columns,
  });

  @override
  State<AccountDirectory> createState() => _AccountDirectoryState();
}

/// The status filter as the stat cards see it. `null` means every account.
/// `suspended` covers suspended and blocked together, like its card.
class StatusFilter {
  final String? current;
  final void Function(String? status) _apply;

  const StatusFilter(this.current, this._apply);

  bool isOn(String? status) => current == status;

  /// A card's click handler for [status]: applies it, or clears it if it is
  /// already applied. Total passes `null` to show everyone.
  VoidCallback by(String? status) => () => _apply(status);
}

class _AccountDirectoryState extends State<AccountDirectory> {
  static const _statuses = ['active', 'pending', 'suspended', 'blocked'];

  String? _status;
  String _query = '';
  int _offset = 0;

  Map<String, dynamic> get _params =>
      {'limit': AccountDirectory.pageSize, 'offset': _offset};

  void _goTo(int offset) {
    setState(() => _offset = offset < 0 ? 0 : offset);
    loadAdmin(context, widget.resource, params: _params);
  }

  /// Clicking the card of the filter already applied clears it.
  void _filterBy(String? status) =>
      setState(() => _status = (_status == status ? null : status));

  /// [context] must be one inside the app shell (the table's), so the
  /// details open in place of the table rather than in a pop-up.
  void _open(BuildContext context, Map<String, dynamic> row) =>
      showAccountDetail(context, role: widget.role, account: row);

  List<Map<String, dynamic>> _visible(List<Map<String, dynamic>> rows) {
    Iterable<Map<String, dynamic>> list = rows;
    if (_status == 'suspended') {
      // The "Suspended/Blocked" card filters to both.
      list = list
          .where((r) => r['status'] == 'suspended' || r['status'] == 'blocked');
    } else if (_status != null) {
      list = list.where((r) => r['status'] == _status);
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) =>
          widget.searchFields.any(
              (f) => r[f] != null && '${r[f]}'.toLowerCase().contains(q)) ||
          accountName(r).toLowerCase().contains(q));
    }
    return list.toList();
  }

  /// Below this height there is no room to pin the header and stats and
  /// still show a useful number of rows, so the whole page scrolls instead.
  static const _minPinnedHeight = 560.0;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: widget.pageTitle,
      body: LayoutBuilder(builder: (context, constraints) {
        // Pinned: header, stats and filters stay put; only the table's rows
        // scroll, under its fixed column headings.
        final pinned = constraints.maxHeight >= _minPinnedHeight;
        final header = PageHeader(
          title: widget.pageTitle,
          subtitle: widget.subtitle,
          searchHint: widget.searchHint,
          onSearchChanged: (v) => setState(() => _query = v),
        );
        final content = _content(pinned);
        if (!pinned) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [header, const SizedBox(height: 20), content],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 20),
            Expanded(child: content)
          ],
        );
      }),
    );
  }

  Widget _content(bool pinned) {
    return AdminResourceBuilder(
      resource: widget.resource,
      load: _params,
      builder: (context, data) {
        final body = mapOf(data.data);
        final rows = recordsOf(data.data, [widget.listKey]);
        final total = (numOf(body['total']) ?? rows.length).toInt();
        final visible = _visible(rows);
        final paged = total > rows.length || _offset > 0;
        int count(String s) => rows.where((r) => r['status'] == s).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.hasData) ...[
              StatGrid(
                  perRow: 5,
                  stats: widget.stats(rows, total, StatusFilter(_status, _filterBy))),
              const SizedBox(height: 18),
              FilterPills<String?>(
                options: [
                  (null, 'All (${rows.length})'),
                  for (final s in _statuses)
                    (s, '${humanize(s)} (${count(s)})'),
                ],
                selected: _status,
                onSelected: (v) => setState(() => _status = v),
              ),
              if (paged) ...[
                const SizedBox(height: 12),
                _PageBar(
                  from: rows.isEmpty ? 0 : _offset + 1,
                  to: _offset + rows.length,
                  total: total,
                  onPrevious: _offset == 0
                      ? null
                      : () => _goTo(_offset - AccountDirectory.pageSize),
                  onNext: _offset + rows.length >= total
                      ? null
                      : () => _goTo(_offset + AccountDirectory.pageSize),
                ),
              ],
              const SizedBox(height: 18),
            ],
            _maybeExpanded(
              pinned,
              SectionCard(
                expand: pinned,
                child: AsyncContent(
                  data: data,
                  expand: pinned,
                  onRetry: () => reloadAdmin(context, widget.resource),
                  builder: (_) => RecordTable(
                    rows: visible,
                    stickyHeader: pinned,
                    emptyMessage: rows.isEmpty
                        ? 'No ${widget.pageTitle.toLowerCase()} have registered yet.'
                        : 'No ${widget.pageTitle.toLowerCase()} match this search or filter.',
                    columns: widget.columns((r) => _open(context, r)),
                    actionsWidth: 80,
                    actions: (r) => Row(children: [
                      RowIconButton(
                          icon: Icons.visibility_outlined,
                          tooltip: 'View',
                          onPressed: () => _open(context, r)),
                      AccountActionsMenu(role: widget.role, account: r),
                    ]),
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

class _PageBar extends StatelessWidget {
  final int from;
  final int to;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PageBar({
    required this.from,
    required this.to,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(
          'Showing $from–$to of $total, newest first. Search, filters and the cards above cover this page.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
      RowIconButton(
          icon: Icons.chevron_left, tooltip: 'Newer', onPressed: onPrevious),
      RowIconButton(
          icon: Icons.chevron_right, tooltip: 'Older', onPressed: onNext),
    ]);
  }
}
