import 'package:flutter/material.dart';

/// Maximum stagger delay to prevent long lists from taking forever to animate.
const _kMaxStaggerDelay = Duration(milliseconds: 200);

/// A wrapper that adds a staggered fade + slide entry animation to list items.
///
/// [delayPerItem] controls the stagger between consecutive items.
/// The delay is automatically capped so large lists still feel responsive.
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 6),
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(
      milliseconds: (delayPerItem.inMilliseconds * index).clamp(
        0,
        _kMaxStaggerDelay.inMilliseconds,
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: FutureBuilder(
        // Small delay to create the stagger effect
        future: Future.delayed(delay),
        builder: (context, snapshot) {
          final isReady = snapshot.connectionState == ConnectionState.done;
          return AnimatedOpacity(
            opacity: isReady ? 1.0 : 0.0,
            duration: duration,
            curve: Curves.easeOutQuad,
            child: AnimatedSlide(
              offset: isReady ? Offset.zero : const Offset(0, 0.05),
              duration: duration,
              curve: Curves.easeOutQuad,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// A sliver variant for use inside CustomScrollView.
///
/// Uses the same capped stagger delay so long sliver lists (e.g. 114 surahs)
/// don't leave the user staring at an apparently empty screen.
class StaggeredSliverListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  const StaggeredSliverListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 6),
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(
      milliseconds: (delayPerItem.inMilliseconds * index).clamp(
        0,
        _kMaxStaggerDelay.inMilliseconds,
      ),
    );

    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final isReady = snapshot.connectionState == ConnectionState.done;
        return AnimatedOpacity(
          opacity: isReady ? 1.0 : 0.0,
          duration: duration,
          curve: Curves.easeOutQuad,
          child: AnimatedSlide(
            offset: isReady ? Offset.zero : const Offset(0, 0.05),
            duration: duration,
            curve: Curves.easeOutQuad,
            child: child,
          ),
        );
      },
    );
  }
}
