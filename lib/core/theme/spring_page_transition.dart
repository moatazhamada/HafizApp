import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'app_motion.dart';

/// A Material 3 Expressive page transition using spring physics.
///
/// Combines a subtle upward slide (16px) with a fade for enter,
/// and a downward slide with fade for exit. Spring settling gives
/// a smooth, calm feel appropriate for a Quran app.
class SpringPageTransition extends PageTransitionsBuilder {
  const SpringPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SpringTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _SpringTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _SpringTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = animation.drive(
      Tween<double>(begin: 0, end: 1).chain(
        CurveTween(curve: _SpringCurve(AppMotion.standardSpring)),
      ),
    );

    final secondaryCurved = secondaryAnimation.drive(
      Tween<double>(begin: 0, end: 1).chain(
        CurveTween(curve: _SpringCurve(AppMotion.gentleSpring)),
      ),
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, 0.015),
          ).animate(secondaryCurved),
          child: child,
        ),
      ),
    );
  }
}

/// A curve driven by a [SpringSimulation].
class _SpringCurve extends Curve {
  final SpringDescription spring;
  final double _duration;

  _SpringCurve(this.spring) : _duration = _computeDuration(spring);

  @override
  double transform(double t) {
    if (_duration == 0) return 1;
    final sim = SpringSimulation(spring, 0, 1, 0);
    return sim.x(t * _duration).clamp(0, 1);
  }

  static double _computeDuration(SpringDescription spring) {
    final sim = SpringSimulation(spring, 0, 1, 0);
    var t = 0.0;
    const step = 0.005;
    while (t < 2.0) {
      if (sim.isDone(t)) break;
      t += step;
    }
    return t;
  }
}
