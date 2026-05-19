import 'package:flutter/material.dart';

/// Maximum stagger delay to prevent long lists from taking forever to animate.
const _kMaxStaggerDelay = Duration(milliseconds: 120);

/// A wrapper that adds a quick fade entry animation to list items.
///
/// Uses a subtle opacity fade with a short capped delay for a modern,
/// snappier feel without the heavy slide effect.
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 4),
    this.duration = const Duration(milliseconds: 180),
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
          child: child,
        );
      },
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
    this.delayPerItem = const Duration(milliseconds: 4),
    this.duration = const Duration(milliseconds: 180),
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
          child: child,
        );
      },
    );
  }
}
