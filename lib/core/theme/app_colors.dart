import 'package:flutter/material.dart';

/// Centralized color tokens for the entire app.
///
/// Usage: `AppColors.of(context).primary` or `AppColors.of(context).surface`
class AppColors {
  // Primary palette
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color onPrimary;
  final Color accent;

  // Surfaces
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color scaffoldBackground;
  final Color appBarBackground;

  // Semantic
  final Color error;
  final Color onError;
  final Color success;
  final Color warning;

  // Quran-specific
  final Color bismillahColor;
  final Color badgeBorder;
  final Color badgeText;
  final List<Color> badgeGradient;
  final Color highlightBackground;
  final Color errorBackground;
  final Color bookmarkBackground;
  final List<Color> appBarGradient;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  /// Quran verse text color (dark green in light, white in dark).
  /// Kept for backward compatibility with surah_screen.
  Color get textColor => bismillahColor;

  // Mushaf
  final Color mushafPageBg;
  final Color mushafPageBorder;
  final Color mushafVerseHover;
  final Color mushafTextPrimary;
  final Color mushafSurahHeaderColor;
  final Color mushafJuzMarkerColor;

  const AppColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.onPrimary,
    required this.accent,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.scaffoldBackground,
    required this.appBarBackground,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.bismillahColor,
    required this.badgeBorder,
    required this.badgeText,
    required this.badgeGradient,
    required this.highlightBackground,
    required this.errorBackground,
    required this.bookmarkBackground,
    required this.appBarGradient,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.mushafPageBg,
    required this.mushafPageBorder,
    required this.mushafVerseHover,
    required this.mushafTextPrimary,
    required this.mushafSurahHeaderColor,
    required this.mushafJuzMarkerColor,
  });

  factory AppColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _light = AppColors(
    primary: Color(0xFF006754),
    primaryDark: Color(0xFF00332C),
    primaryLight: Color(0xFFE0F2F1),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF87D1A4),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF5F5F5),
    onSurface: Color(0xFF1A1A1A),
    onSurfaceVariant: Color(0xFF4A4A4A),
    scaffoldBackground: Color(0xFFFFFFFF),
    appBarBackground: Color(0xFF006754),
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF9800),
    bismillahColor: Color(0xFF004B40),
    badgeBorder: Color(0xFF006754),
    badgeText: Color(0xFF004B40),
    badgeGradient: [Color(0xFFFAF6EB), Color(0xFFEDE6D6)],
    highlightBackground: Color(0xFFB2DFDB),
    errorBackground: Color(0xFFFFEBEE),
    bookmarkBackground: Color(0xFFE8F5E9),
    appBarGradient: [Color(0xFF006754), Color(0xDB87D1A4)],
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    textHint: Color(0xFF9E9E9E),
    mushafPageBg: Color(0xFFFFFBF0),
    mushafPageBorder: Color(0xFFE8D5B7),
    mushafVerseHover: Color(0xFFB2DFDB),
    mushafTextPrimary: Color(0xFF1A1A1A),
    mushafSurahHeaderColor: Color(0xFF006754),
    mushafJuzMarkerColor: Color(0xFF8B4513),
  );

  static const _dark = AppColors(
    primary: Color(0xFF006754),
    primaryDark: Color(0xFF00332C),
    primaryLight: Color(0xFF1E3A35),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF87D1A4),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2D2D2D),
    onSurface: Color(0xFFE0E0E0),
    onSurfaceVariant: Color(0xFFB0B0B0),
    scaffoldBackground: Color(0xFF121212),
    appBarBackground: Color(0xFF006754),
    error: Color(0xFFEF5350),
    onError: Color(0xFF000000),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFA726),
    bismillahColor: Color(0xFFFFFFFF),
    badgeBorder: Color(0xFF87D1A4),
    badgeText: Color(0xFFFAF6EB),
    badgeGradient: [Color(0xFF113C35), Color(0xFF0B2D28)],
    highlightBackground: Color(0xFF2A4A42),
    errorBackground: Color(0xFF5C1B1B),
    bookmarkBackground: Color(0xFF1E3A35),
    appBarGradient: [Color(0xFF006754), Color(0xDB87D1A4)],
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFFBDBDBD),
    textHint: Color(0xFFAAAAAA),
    mushafPageBg: Color(0xFF1E1A1A),
    mushafPageBorder: Color(0xFF3D2E2E),
    mushafVerseHover: Color(0xFF2A4A42),
    mushafTextPrimary: Color(0xFFE8D5B7),
    mushafSurahHeaderColor: Color(0xFF87D1A4),
    mushafJuzMarkerColor: Color(0xFFD4A574),
  );
}
