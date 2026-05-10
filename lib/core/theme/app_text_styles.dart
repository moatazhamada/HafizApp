import 'package:flutter/material.dart';

/// Centralized typography tokens.
///
/// Usage: `AppTextStyles.of(context).headingLarge` or
/// `AppTextStyles.arabicLarge(context)` for Quran text.
class AppTextStyles {
  const AppTextStyles._();

  // Font families
  static const String arabicFont = 'NotoNaskhArabic';
  static const String latinFont = 'Poppins';

  // --- Heading styles ---

  static const TextStyle headingLarge = TextStyle(
    fontFamily: latinFont,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: latinFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: latinFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // --- Body styles ---

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: latinFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: latinFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: latinFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // --- Label styles ---

  static const TextStyle labelLarge = TextStyle(
    fontFamily: latinFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: latinFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: latinFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // --- Caption / overline ---

  static const TextStyle caption = TextStyle(
    fontFamily: latinFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // --- Arabic / Quran text styles ---

  static const TextStyle quranXLarge = TextStyle(
    fontFamily: arabicFont,
    fontSize: 36,
    fontWeight: FontWeight.normal,
    height: 2.0,
  );

  static const TextStyle quranLarge = TextStyle(
    fontFamily: arabicFont,
    fontSize: 28,
    fontWeight: FontWeight.normal,
    height: 2.0,
  );

  static const TextStyle quranMedium = TextStyle(
    fontFamily: arabicFont,
    fontSize: 22,
    fontWeight: FontWeight.normal,
    height: 1.8,
  );

  static const TextStyle quranSmall = TextStyle(
    fontFamily: arabicFont,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.8,
  );

  static const TextStyle quranVerseBadge = TextStyle(
    fontFamily: arabicFont,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    height: 1.2,
  );

  // --- Numeric styles (surah IDs, page numbers, etc.) ---

  static const TextStyle numericLarge = TextStyle(
    fontFamily: latinFont,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle numericMedium = TextStyle(
    fontFamily: latinFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // --- Helper to apply color from theme ---

  /// Returns the bodyLarge style with the theme's body text color.
  static TextStyle bodyLargeThemed(BuildContext context) {
    return bodyLarge.copyWith(
      color: DefaultTextStyle.of(context).style.color,
    );
  }

  static TextStyle bodyMediumThemed(BuildContext context) {
    return bodyMedium.copyWith(
      color: DefaultTextStyle.of(context).style.color,
    );
  }
}
