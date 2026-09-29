import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Wraps a data-backed panel with its loading, error and empty states.
///
/// Keeps the three apart deliberately: a first load shows a spinner, a
/// refresh over existing data leaves the data on screen, and an empty result
/// reads as "nothing here yet" rather than an unexplained blank.
class AsyncSection extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.isLoading,
    required this.hasLoaded,
    required this.error,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
    this.onRetry,
  });

  final bool isLoading;

  /// Whether a load has completed at least once — tells "not asked yet" apart
  /// from "asked, and there was nothing".
  final bool hasLoaded;

  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Only block the panel on the *first* load. A refresh keeps the previous
    // rows visible so the table does not collapse and jump.
    if (isLoading && !hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 28, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      );
    }

    if (isEmpty && hasLoaded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                size: 28, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A failed refresh over good data: keep the rows, say so above them.
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 15, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.danger),
                  ),
                ),
                if (onRetry != null)
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        child,
      ],
    );
  }
}
