import 'package:flutter/material.dart';

/// A wrapper that adds a staggered fade + slide entry animation to list items.
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// A sliver variant for use inside CustomScrollView.
class StaggeredSliverListItem extends StatelessWidget {
  final Widget child;
  final int index;

  const StaggeredSliverListItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 40 * index);

    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final isReady = snapshot.connectionState == ConnectionState.done;
        return AnimatedOpacity(
          opacity: isReady ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
          child: AnimatedSlide(
            offset: isReady ? Offset.zero : const Offset(0, 0.1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
            child: child,
          ),
        );
      },
    );
  }
}
