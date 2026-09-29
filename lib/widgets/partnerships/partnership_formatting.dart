import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';

import 'package:pholders_admin/store.dart';
import '../../theme/app_colors.dart';

/// Turns a snake_case database value into something readable —
/// `pending_verification` becomes `Pending verification`.
String titleCase(String raw) {
  final words = raw.replaceAll('_', ' ').trim();
  if (words.isEmpty) return raw;
  return words[0].toUpperCase() + words.substring(1);
}

/// Maps `pharmacies.status` onto the wording [StatusBadge] colours.
///
/// The column stores `pending_verification`, which the badge would otherwise
/// render in its neutral fallback colour; `Pending` is a colour it knows.
String humanizePharmacyStatus(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'pending_verification':
      return 'Pending';
    case 'inactive':
      return 'Suspended';
    default:
      return titleCase(status);
  }
}

/// Agreement status values, which already read well enough to pass straight
/// through the badge's colour map.
String humanizeAgreementStatus(String status) => titleCase(status);

/// A stable colour per record, so a pharmacy keeps the same avatar between
/// refreshes instead of shuffling as the list re-sorts.
Color avatarColorFor(int id) {
  const palette = [
    Color(0xFF14B8A9),
    Color(0xFF7C6FEA),
    Color(0xFF2F80ED),
    Color(0xFFE0577B),
    Color(0xFFE0A83C),
    Color(0xFF1FA97C),
    Color(0xFF8A5A3B),
    Color(0xFF5B6BF0),
  ];
  return palette[id.abs() % palette.length];
}

/// Up to two initials from a name, for the avatar circle.
String initialsFor(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

final _dayFormat = DateFormat('d MMM yyyy');
final _monthFormat = DateFormat('MMM yyyy');

String formatDay(DateTime? value) =>
    value == null ? '—' : _dayFormat.format(value);

String formatMonth(DateTime? value) =>
    value == null ? '—' : _monthFormat.format(value);

/// Renders a rate stored as a percentage (`DECIMAL(5,2)`), not a fraction.
String formatPercent(double? value, {int decimals = 0}) =>
    value == null ? '—' : '${value.toStringAsFixed(decimals)}%';

String formatRand(double? value) =>
    value == null ? '—' : NumberFormat.currency(symbol: 'R', decimalDigits: 2)
        .format(value);

/// Seconds as a human duration — routing times are stored in seconds and are
/// routinely hours long.
String formatDuration(double? seconds) {
  if (seconds == null) return '—';
  final total = seconds.round();
  if (total < 60) return '${total}s';
  if (total < 3600) return '${(total / 60).round()}m';
  return '${(total / 3600).toStringAsFixed(1)}h';
}

/// The premium/standard/basic pill used wherever a tier is shown.
class TierChip extends StatelessWidget {
  const TierChip({super.key, required this.tier});

  final String tier;

  Color get _color {
    switch (tier.toLowerCase()) {
      case 'premium':
        return const Color(0xFF7C6FEA);
      case 'standard':
        return AppColors.primaryDark;
      case 'basic':
        return AppColors.textSecondary;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        titleCase(tier),
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Surfaces the result of a partnership mutation once, then clears it.
///
/// Called from a `StoreConnector.onDidChange`, which runs mid-frame — the
/// snackbar and the follow-up dispatch are deferred to the next frame so
/// they do not mutate the store while it is being read.
void showPartnershipActionBanner(
  BuildContext context, {
  required PartnershipsState? previous,
  required PartnershipsState current,
}) {
  final message = current.actionMessage;
  final error = current.actionError;

  final isNewMessage = message != null && message != previous?.actionMessage;
  final isNewError = error != null && error != previous?.actionError;
  if (!isNewMessage && !isNewError) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isNewError ? error : message!),
        backgroundColor: isNewError ? AppColors.danger : null,
      ),
    );
    StoreProvider.of<AppState>(context)
        .dispatch(const ClearPartnershipMessagesAction());
  });
}
