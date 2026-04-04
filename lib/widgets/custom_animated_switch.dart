import 'package:flutter/material.dart';

class CustomAnimatedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? iconOn;
  final IconData? iconOff;
  final String? textOn;
  final String? textOff;
  final Color activeColor;
  final Color inactiveColor;

  const CustomAnimatedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.iconOn = Icons.view_sidebar_outlined,
    this.iconOff = Icons.view_headline_rounded,
    this.textOn = 'Horizontal',
    this.textOff = 'Vertical',
    this.activeColor = const Color(0xFF004B40),
    this.inactiveColor = Colors.grey,
  });

  @override
  State<CustomAnimatedSwitch> createState() => _CustomAnimatedSwitchState();
}

class _CustomAnimatedSwitchState extends State<CustomAnimatedSwitch> {
  @override
  Widget build(BuildContext context) {
    bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 130,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.value
              ? widget.activeColor.withValues(alpha: 0.2)
              : widget.inactiveColor.withValues(alpha: 0.1),
          border: Border.all(
            color: widget.value
                ? widget.activeColor.withValues(alpha: 0.3)
                : widget.inactiveColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Text Layer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: widget.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.textOn ?? '',
                        style: TextStyle(
                          color: widget.activeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: !widget.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.textOff ?? '',
                        style: TextStyle(
                          color: widget.inactiveColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Floating Knob
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              alignment: widget.value
                  ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
                  : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value ? widget.activeColor : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.value ? widget.iconOn : widget.iconOff,
                  size: 16,
                  color: widget.value ? Colors.white : widget.inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
