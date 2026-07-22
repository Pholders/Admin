import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TopBar extends StatelessWidget {
  final String breadcrumbTrail; // e.g. "Pholders"
  final String currentPage; // e.g. "Dashboard"

  const TopBar({
    super.key,
    required this.breadcrumbTrail,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$breadcrumbTrail  >  ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        Text(
          currentPage,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        const _AvatarStack(),
        const SizedBox(width: 20),
        _IconBadge(icon: Icons.notifications_none, badgeCount: 10),
        const SizedBox(width: 20),
        const _SearchField(),
        const SizedBox(width: 20),
        const _ProfileAvatar(),
      ],
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.orange, Colors.blueGrey, Colors.teal];
    return SizedBox(
      width: 84,
      height: 36,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 20.0,
              child: CircleAvatar(radius: 18, backgroundColor: colors[i]),
            ),
          Positioned(
            left: colors.length * 20.0,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  const _IconBadge({required this.icon, required this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 24),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text(
            'Search anything',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Spacer(),
          Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const CircleAvatar(backgroundColor: Colors.deepOrange, radius: 15),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
      ],
    );
  }
}
