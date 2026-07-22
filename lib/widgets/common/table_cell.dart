import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
