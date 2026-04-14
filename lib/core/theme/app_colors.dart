import 'package:flutter/material.dart';

class AppColors {
  final Color textColor;
  final Color badgeBorder;
  final Color badgeText;
  final List<Color> badgeGradient;
  final Color highlightBackground;
  final Color errorBackground;
  final Color bookmarkBackground;
  final Color appBarBackground;
  final List<Color> appBarGradient;
  final Color scaffoldBackground;
  final Color bismillahColor;

  const AppColors({
    required this.textColor,
    required this.badgeBorder,
    required this.badgeText,
    required this.badgeGradient,
    required this.highlightBackground,
    required this.errorBackground,
    required this.bookmarkBackground,
    required this.appBarBackground,
    required this.appBarGradient,
    required this.scaffoldBackground,
    required this.bismillahColor,
  });

  factory AppColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _light = AppColors(
    textColor: Color(0xFF004B40),
    badgeBorder: Color(0xFF006754),
    badgeText: Color(0xFF004B40),
    badgeGradient: [Color(0xFFFAF6EB), Color(0xFFEDE6D6)],
    highlightBackground: Color(0xFFB2DFDB),
    errorBackground: Color(0xFFFFEBEE),
    bookmarkBackground: Color(0xFFE8F5E9),
    appBarBackground: Color(0xFF006754),
    appBarGradient: [Color(0xFF006754), Color(0xDB87D1A4)],
    scaffoldBackground: Color(0xFFFFFFFF),
    bismillahColor: Color(0xFF004B40),
  );

  static const _dark = AppColors(
    textColor: Color(0xFFFFFFFF),
    badgeBorder: Color(0xFF87D1A4),
    badgeText: Color(0xFFFAF6EB),
    badgeGradient: [Color(0xFF113C35), Color(0xFF0B2D28)],
    highlightBackground: Color(0xFF2A4A42),
    errorBackground: Color(0xFF5C1B1B),
    bookmarkBackground: Color(0xFF1E3A35),
    appBarBackground: Color(0xFF006754),
    appBarGradient: [Color(0xFF006754), Color(0xDB87D1A4)],
    scaffoldBackground: Color(0xFF000000),
    bismillahColor: Color(0xFFFFFFFF),
  );
}
