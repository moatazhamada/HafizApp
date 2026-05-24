import 'package:flutter/material.dart';

/// Material 3 Expressive shape tokens.
///
/// Uses organic, non-uniform border radii for a more natural,
/// handcrafted feel while staying respectful for a Quran app.
class AppShapes {
  const AppShapes._();

  /// Standard card — slightly asymmetric for expressiveness.
  static const ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    ),
  );

  /// Small card — uniform moderate radius.
  static const ShapeBorder cardShapeSmall = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  /// Featured / hero card — larger, more expressive radii.
  static const ShapeBorder featuredShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(28),
      topRight: Radius.circular(28),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    ),
  );

  /// Pill shape for buttons, chips, badges.
  static const ShapeBorder pillShape = StadiumBorder();

  /// Dialog shape — uniform large radius.
  static const ShapeBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  /// Bottom sheet shape — large top radii.
  static const ShapeBorder bottomSheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  /// Input field shape.
  static const ShapeBorder inputShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );

  /// Chip shape — expressive rounded rectangle.
  static const RoundedRectangleBorder chipShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  /// Navigation indicator shape.
  static const ShapeBorder navIndicatorShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
}
