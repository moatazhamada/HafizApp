import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

void showAutoScrollSpeedPicker(
  BuildContext context, {
  required double currentSpeed,
  required void Function(double speed) onSpeedSelected,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'lbl_scroll_speed'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...[0.25, 0.5, 1.0, 1.5, 2.0, 3.0].map(
            (speed) => ListTile(
              title: Text(
                speed < 1
                    ? '${(speed * 100).round()}% (${'lbl_slow'.tr})'
                    : speed == 1.0
                    ? '1.0x (${'lbl_normal'.tr})'
                    : '${speed}x (${'lbl_fast'.tr})',
              ),
              trailing: currentSpeed == speed
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                onSpeedSelected(speed);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
