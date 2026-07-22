import 'package:flutter/material.dart';

/// Centralized color palette pulled from the Figma design.
/// Keep every hardcoded color in the app referencing this file
/// so re-theming later is a one-file change.
class AppColors {
  AppColors._();

  // Brand / accent
  static const Color primary = Color(0xFF14B8A9); // main teal
  static const Color primaryDark = Color(0xFF0E9187);
  static const Color primaryLight = Color(0xFF6FD3C7);

  // Backgrounds
  static const Color pageBackground = Color(0xFFF6F9F8); // outer app bg
  static const Color contentBackground = Color(0xFFE8F5F3); // teal-tinted panel
  static const Color sidebarBackground = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color activeNavBackground = Color(0xFFD9F0EC);

  // Text
  static const Color textPrimary = Color(0xFF1F2B34);
  static const Color textSecondary = Color(0xFF8A97A0);
  static const Color textMuted = Color(0xFFB0BAC2);

  // Status / misc accents
  static const Color alertBackground = Color(0xFFFBEEDB);
  static const Color alertIcon = Color(0xFFE6A23C);
  static const Color danger = Color(0xFFE85D5D);
  static const Color chipBlack = Color(0xFF1F2B34);

  // Chart palette
  static const Color chartTealDark = Color(0xFF1B9C93);
  static const Color chartTealLight = Color(0xFF8FDDD3);
  static const Color chartTealPale = Color(0xFFCDEFEA);

  static const Color divider = Color(0xFFEDF2F1);
}
