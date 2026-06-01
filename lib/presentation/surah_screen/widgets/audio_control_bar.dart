import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class AudioControlBar extends StatelessWidget {
  final bool isListeningMode;
  final VoidCallback onToggle;

  const AudioControlBar({
    super.key,
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
              color: isListeningMode ? AppColors.of(context).warning : AppColors.of(context).onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
