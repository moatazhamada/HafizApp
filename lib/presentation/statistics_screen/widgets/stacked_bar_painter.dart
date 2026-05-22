import 'package:flutter/material.dart';

class StackedBarPainter extends CustomPainter {
  final int memorized;
  final int inProgress;
  final int notStarted;
  final int total;
  final Color backgroundColor;
  final Color memorizedColor;
  final Color inProgressColor;

  StackedBarPainter({
    required this.memorized,
    required this.inProgress,
    required this.notStarted,
    required this.total,
    required this.backgroundColor,
    required this.memorizedColor,
    required this.inProgressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, bgPaint);

    final memFrac = total > 0 ? memorized / total : 0.0;
    final progFrac = total > 0 ? inProgress / total : 0.0;

    if (memFrac > 0) {
      final memPaint = Paint()..color = memorizedColor;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          0,
          0,
          size.width * memFrac,
          size.height,
          topLeft: const Radius.circular(12),
          bottomLeft: const Radius.circular(12),
          topRight: progFrac == 0 && memFrac == 1
              ? const Radius.circular(12)
              : Radius.zero,
          bottomRight: progFrac == 0 && memFrac == 1
              ? const Radius.circular(12)
              : Radius.zero,
        ),
        memPaint,
      );
    }

    if (progFrac > 0) {
      final progPaint = Paint()..color = inProgressColor;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          size.width * memFrac,
          0,
          size.width * (memFrac + progFrac),
          size.height,
          topLeft: memFrac == 0 ? const Radius.circular(12) : Radius.zero,
          bottomLeft: memFrac == 0 ? const Radius.circular(12) : Radius.zero,
          topRight: (memFrac + progFrac) >= 0.999
              ? const Radius.circular(12)
              : Radius.zero,
          bottomRight: (memFrac + progFrac) >= 0.999
              ? const Radius.circular(12)
              : Radius.zero,
        ),
        progPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StackedBarPainter oldDelegate) {
    return memorized != oldDelegate.memorized ||
        inProgress != oldDelegate.inProgress ||
        notStarted != oldDelegate.notStarted ||
        backgroundColor != oldDelegate.backgroundColor ||
        memorizedColor != oldDelegate.memorizedColor ||
        inProgressColor != oldDelegate.inProgressColor;
  }
}
