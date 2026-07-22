import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shell/app_shell.dart';

/// Shown for any sidebar route that doesn't have a real screen yet
/// (Doctors, Pharmacies, Tracking, Billing, Settings, ...). Keeps
/// navigation from breaking while those screens are built out.
class ComingSoonScreen extends StatelessWidget {
  final String pageTitle;
  const ComingSoonScreen({super.key, required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: pageTitle,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              '$pageTitle is coming soon',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Send over the Figma design for this screen and it\'ll be built out next.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
