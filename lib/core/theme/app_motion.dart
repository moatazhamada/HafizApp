import 'package:flutter/material.dart';

/// Material 3 Expressive motion tokens.
///
/// Uses high-damping spring configs for a calm, respectful feel
/// appropriate for a Quran app — smooth, not bouncy.
class AppMotion {
  const AppMotion._();

  /// Standard spring — balanced responsiveness (damping 30).
  static const SpringDescription standardSpring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 30,
  );

  /// Gentle spring — softer, slower settle (damping 25).
  static const SpringDescription gentleSpring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 25,
  );

  /// Snappy spring — quick response (damping 35).
  static const SpringDescription snappySpring = SpringDescription(
    mass: 1,
    stiffness: 800,
    damping: 35,
  );

  // Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 350);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Easing curves (M3E emphasized curves)
  static const Curve emphasizedDecelerate = Curves.easeOutCubic;
  static const Curve emphasizedAccelerate = Curves.easeInCubic;
  static const Curve standardCurve = Curves.easeInOut;
}
