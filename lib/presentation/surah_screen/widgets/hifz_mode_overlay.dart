import 'package:flutter/material.dart';

class HifzModeOverlay extends StatelessWidget {
  final String text;
  final bool isBlurred;
  final Color textColor;
  final TextStyle baseStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;

  const HifzModeOverlay({
    super.key,
    required this.text,
    required this.isBlurred,
    required this.textColor,
    required this.baseStyle,
    required this.textAlign,
    required this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      textDirection: textDirection,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
      style: isBlurred
          ? baseStyle.copyWith(
              color: Colors.transparent,
              shadows: [
                Shadow(
                  color: textColor,
                  blurRadius: 20.0,
                  offset: Offset.zero,
                ),
              ],
            )
          : baseStyle,
    );
  }

}
