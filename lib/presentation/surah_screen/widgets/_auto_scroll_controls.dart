part of '../surah_screen.dart';

class _AutoScrollControls extends StatelessWidget {
  final bool isAutoScrolling;
  final double autoScrollSpeed;
  final VoidCallback onToggle;
  final VoidCallback onShowSpeedDialog;

  const _AutoScrollControls({
    required this.isAutoScrolling,
    required this.autoScrollSpeed,
    required this.onToggle,
    required this.onShowSpeedDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isAutoScrolling
          ? 'lbl_stop_autoscroll'.tr
          : 'lbl_start_autoscroll'.tr,
      child: Tooltip(
        message: 'lbl_scroll_speed'.tr,
        child: InkWell(
          onTap: onToggle,
          onLongPress: onShowSpeedDialog,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Badge(
              isLabelVisible: autoScrollSpeed != 0.5,
              label: Text('${autoScrollSpeed}x'),
              child: Icon(
                isAutoScrolling
                    ? Icons.pause_circle
                    : Icons.play_circle_outline,
                color: isAutoScrolling ? Colors.amber : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
