import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Fixed-width header cell. Using fixed widths (instead of Expanded/flex)
/// keeps header and row cells pixel-aligned even when the table scrolls
/// horizontally on narrow screens.
class AppTableHeaderCell extends StatelessWidget {
  final String label;
  final double width;
  const AppTableHeaderCell(
      {super.key, required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class AppTableCell extends StatelessWidget {
  final double width;
  final Widget child;
  const AppTableCell({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

/// Wraps a header row + data rows in a horizontally-scrollable region so
/// wide tables (7-8 columns) never get visually crushed on smaller windows.
///
/// With [stickyHeader], the table fills the height it is given: the header
/// row stays in place and only the rows scroll beneath it. The parent must
/// then give it a bounded height (e.g. inside an [Expanded]).
class ScrollableTable extends StatelessWidget {
  final Widget header;
  final List<Widget> rows;
  final double minWidth;
  final bool stickyHeader;

  const ScrollableTable({
    super.key,
    required this.header,
    required this.rows,
    required this.minWidth,
    this.stickyHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    if (stickyHeader) return _buildSticky();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const Divider(height: 24),
            for (final row in rows) ...[row, const SizedBox(height: 14)],
          ],
        ),
      ),
    );
  }

  /// Header and rows share one horizontal scroll, so the columns stay
  /// aligned; the rows alone scroll vertically.
  Widget _buildSticky() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: rows[i],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
