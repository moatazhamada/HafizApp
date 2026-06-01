import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';

/// Maximum stagger delay to prevent long lists from taking forever to animate.
const _kMaxStaggerDelay = Duration(milliseconds: 120);

/// A wrapper that adds a spring-driven fade + slide entry animation to list items.
///
/// Uses [AnimationController] with spring physics instead of [FutureBuilder]
/// for a smoother, more expressive entrance with a subtle upward slide.
class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 4),
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final delay = Duration(
      milliseconds: (widget.delayPerItem.inMilliseconds * widget.index).clamp(
        0,
        _kMaxStaggerDelay.inMilliseconds,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.015),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A sliver variant for use inside CustomScrollView.
///
/// Uses the same capped stagger delay and spring-driven animation
/// so long sliver lists (e.g. 114 surahs) don't leave the user
/// staring at an apparently empty screen.
class StaggeredSliverListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  const StaggeredSliverListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 4),
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<StaggeredSliverListItem> createState() =>
      _StaggeredSliverListItemState();
}

class _StaggeredSliverListItemState extends State<StaggeredSliverListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final delay = Duration(
      milliseconds: (widget.delayPerItem.inMilliseconds * widget.index).clamp(
        0,
        _kMaxStaggerDelay.inMilliseconds,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.015),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
