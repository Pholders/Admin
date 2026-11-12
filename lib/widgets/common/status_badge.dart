import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Colored pill used in every data table's Status column. Centralizing the
/// color mapping here means "Completed" looks the same whether it's on the
/// Orders table or a future Billing table.
class StatusBadge extends StatelessWidget {
  final String status;

  /// Overrides the colour looked up from [status], for statuses whose word
  /// means something different on another screen (a `pending` prescription
  /// is grey, not the pink of a pending account).
  final Color? color;

  const StatusBadge({super.key, required this.status, this.color});

  Color get _color {
    if (color != null) return color!;
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
      case 'inactive':
        return AppColors.textMuted;
      // Partnership tiers
      case 'premium':
        return const Color(0xFF7C6FEA);
      case 'standard':
        return const Color(0xFF2F80ED);
      case 'basic':
        return const Color(0xFF8A97A0);
      // Agreements and audit outcomes
      case 'expired':
      case 'no agreements':
        return const Color(0xFF8A97A0);
      case 'terminated':
      case 'failed':
      case 'failure':
      case 'poor':
        return AppColors.danger;
      case 'success':
      case 'excellent':
        return const Color(0xFF1FA97C);
      case 'good':
        return AppColors.primaryDark;
      case 'fair':
        return const Color(0xFFE0A83C);
      // Orders, appointments, tickets and payments
      case 'accepted':
      case 'awaiting claim':
      case 'claim approved':
      case 'preparing':
      case 'scheduled':
      case 'rescheduled':
        return const Color(0xFF2F80ED);
      case 'ready':
      case 'picked up':
      case 'resolved':
      case 'visible':
        return const Color(0xFF1FA97C);
      case 'pending payment':
        return const Color(0xFFE0A83C);
      case 'claim rejected':
      case 'no show':
      case 'urgent':
        return AppColors.danger;
      case 'normal':
      case 'hidden':
        return const Color(0xFF8A97A0);
      // Security alerts
      case 'critical':
      case 'verified threat':
        return AppColors.danger;
      case 'unreviewed':
        return const Color(0xFFE0A83C);
      case 'verified legit':
        return const Color(0xFF1FA97C);
      case 'dismissed':
        return const Color(0xFF8A97A0);
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
          // Flexible so a long status truncates inside a narrow table cell
          // instead of overflowing it.
          Flexible(
            child: Text(
              status,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
