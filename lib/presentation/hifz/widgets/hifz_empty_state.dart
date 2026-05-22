import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class HifzEmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const HifzEmptyState({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: AppColors.of(context).notStartedStatus,
            ),
            const SizedBox(height: 24),
            Text(
              'lbl_hifz_empty_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'lbl_hifz_empty_subtitle'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.of(context).notStartedStatus,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onAddPressed,
              child: Text('lbl_add_hifz_entry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
