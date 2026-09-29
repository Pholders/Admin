import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Scroll room reserved below a table whose rows open an actions menu.
///
/// Flutter clamps a [PopupMenuButton]'s menu inside the window rather than
/// letting it run off the bottom, so a menu opened on one of the last rows is
/// pinned to the window edge and paints over the rows above it - including the
/// row it belongs to. Reserving a menu's height of scrolling below the table
/// means the last row can always be scrolled clear of the edge, so the menu
/// opens downward into empty space instead.
///
/// This is padding *inside* the scroll view, so it costs nothing visually
/// until the content is long enough to scroll.
///
/// Sized for the tallest menu in the app: four items plus the menu's own
/// vertical padding.
const double kTableActionMenuClearance = 220;

/// Fixed-width header cell. Using fixed widths (instead of Expanded/flex)
/// keeps header and row cells pixel-aligned even when the table scrolls
/// horizontally on narrow screens.
class AppTableHeaderCell extends StatelessWidget {
  final String label;
  final double width;
  const AppTableHeaderCell({super.key, required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
class ScrollableTable extends StatelessWidget {
  final Widget header;
  final List<Widget> rows;
  final double minWidth;

  const ScrollableTable({
    super.key,
    required this.header,
    required this.rows,
    required this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
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
}
