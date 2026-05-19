import 'package:flutter/material.dart';
import '../../../core/models/surface_type.dart';

/// Wraps surface widgets with a cross-fade animation when switching.
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
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
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
