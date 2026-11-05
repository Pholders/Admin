import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StatCardData {
  final String label;
  final String value;
  final IconData icon;

  /// What clicking the card does, e.g. "View all doctors". Shown as the
  /// card's tooltip, not as text on the card.
  final String? actionLabel;

  /// Makes the whole card clickable.
  final VoidCallback? onAction;

  /// Marks the card as the filter currently applied to the table below.
  final bool selected;

  const StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.selected = false,
  });
}

class StatCard extends StatefulWidget {
  final StatCardData data;
  const StatCard({super.key, required this.data});

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final clickable = data.onAction != null;
    final radius = BorderRadius.circular(16);

    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final card = Material(
      color: data.selected
          ? AppColors.activeNavBackground.withValues(alpha: 0.55)
          : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          // A clickable card firms up its border on hover; the selected
          // filter's card keeps it.
          color: data.selected || _hovered
              ? AppColors.primary
              : AppColors.primaryLight.withValues(alpha: 0.5),
          width: data.selected ? 1.8 : 1.4,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: clickable
          ? InkWell(
              onTap: data.onAction,
              onHover: (h) => setState(() => _hovered = h),
              hoverColor: AppColors.activeNavBackground.withValues(alpha: 0.45),
              splashColor: AppColors.activeNavBackground,
              highlightColor: AppColors.activeNavBackground.withValues(alpha: 0.6),
              child: content,
            )
          : content,
    );

    if (!clickable || data.actionLabel == null) return card;
    return Tooltip(message: data.actionLabel!, waitDuration: const Duration(milliseconds: 400), child: card);
  }
}
