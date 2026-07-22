import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Colored pill used in every data table's Status column. Centralizing the
/// color mapping here means "Completed" looks the same whether it's on the
/// Orders table or a future Billing table.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'approved':
      case 'delivered':
      case 'published':
      case 'closed':
        return const Color(0xFF1FA97C);
      case 'processing':
        return AppColors.primaryDark;
      case 'in transit':
      case 'in progress':
      case 'low':
        return const Color(0xFF2F80ED);
      case 'out for delivery':
        return const Color(0xFF7C6FEA);
      case 'pending':
      case 'pending review':
        return const Color(0xFFE0577B);
      case 'delayed':
        return const Color(0xFFE0577B);
      case 'medium':
        return const Color(0xFFE0A83C);
      case 'cancelled':
      case 'rejected':
      case 'failed delivery':
      case 'open':
      case 'high':
        return AppColors.danger;
      case 'returned':
        return const Color(0xFF8A97A0);
      case 'suspended':
      case 'blocked':
        return const Color(0xFF8A5A3B);
      case 'draft':
        return AppColors.textMuted;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
