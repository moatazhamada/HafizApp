import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../core/theme/app_motion.dart';

/// A wrapper that adds M3E-style press feedback: subtle scale-down
/// with spring physics on press, spring-back on release.
///
/// Replaces plain InkWell tap feedback with a tactile, responsive feel.
class ExpressivePress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final SpringDescription? spring;

  const ExpressivePress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.spring,
  });

  @override
  State<ExpressivePress> createState() => _ExpressivePressState();
}

class _ExpressivePressState extends State<ExpressivePress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.shortDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _SpringCurve(AppMotion.standardSpring),
        reverseCurve: _SpringCurve(AppMotion.gentleSpring),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
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
