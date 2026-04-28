/// Centralized spacing and dimension tokens.
///
/// Usage: `AppSpacing.sm`, `AppSpacing.md`, `AppSpacing.touchTarget`
class AppSpacing {
  const AppSpacing._();

  // Spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Touch target minimum (Material Design)
  static const double touchTarget = 48.0;

  // Common widget sizes
  static const double badgeSize = 28.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Border radii
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircular = 100.0;

  // Elevation
  static const double elevationLow = 1.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}
