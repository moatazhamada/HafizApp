import 'package:flutter/material.dart';
import '../../../core/models/surface_type.dart';
import '../../../core/theme/app_motion.dart';

/// Wraps surface widgets with a spring-physics cross-fade animation
/// when switching surfaces on the home screen.
///
/// Upgrades from a simple fade to a spring-driven crossfade with a
/// micro-slide for more expressive transitions.
class AnimatedSurfaceSwitcher extends StatelessWidget {
  final SurfaceType surfaceType;
  final Widget child;

  const AnimatedSurfaceSwitcher({
    super.key,
    required this.surfaceType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.mediumDuration,
      switchInCurve: AppMotion.emphasizedDecelerate,
      switchOutCurve: AppMotion.emphasizedAccelerate,
      transitionBuilder: (child, animation) {
        final slideIn = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasizedDecelerate,
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideIn,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(surfaceType),
        child: child,
      ),
    );
  }
}
