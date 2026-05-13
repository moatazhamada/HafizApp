part of '../surah_screen.dart';

class _AudioControlBar extends StatelessWidget {
  final bool isListeningMode;
  final VoidCallback onToggle;

  const _AudioControlBar({
    required this.isListeningMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isListeningMode
          ? 'lbl_stop_listening'.tr
          : 'lbl_start_listening'.tr,
      child: Tooltip(
        message: isListeningMode
            ? 'lbl_stop_listening'.tr
            : 'lbl_start_listening'.tr,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isListeningMode ? Icons.headset : Icons.headset_outlined,
              color: isListeningMode ? AppColors.of(context).warning : Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
