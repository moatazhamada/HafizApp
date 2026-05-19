import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class GoalCelebration extends StatefulWidget {
  final Widget child;
  final bool showConfetti;

  const GoalCelebration({
    super.key,
    required this.child,
    this.showConfetti = false,
  });

  @override
  State<GoalCelebration> createState() => _GoalCelebrationState();
}

class _GoalCelebrationState extends State<GoalCelebration> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.showConfetti) {
      _controller.play();
    }
  }

  @override
  void didUpdateWidget(GoalCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: [
              AppColors.of(context).primary,
              AppColors.of(context).accent,
              AppColors.of(context).memorizedStatus,
              Colors.orange,
              Colors.pink,
            ],
          ),
        ),
      ],
    );
  }
}
