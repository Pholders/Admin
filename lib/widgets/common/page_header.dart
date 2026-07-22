import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'search_bar.dart';

/// The "Patients / All Orders / Returns" header row: title + subtitle on
/// the left, a search field and grid icon on the right. Shared so every
/// list-style screen looks consistent. Pass [actionLabel] (e.g. "Add FAQ",
/// "Export") to show a pill button instead of the default grid icon.
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.onSearchChanged,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        const Spacer(),
        AppSearchField(hintText: searchHint, onChanged: onSearchChanged),
        const SizedBox(width: 12),
        if (actionLabel != null)
          ElevatedButton(
            onPressed: onActionTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chipBlack,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
          )
        else
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.textPrimary),
          ),
      ],
    );
  }
}
