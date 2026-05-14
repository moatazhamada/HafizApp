import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';

class ManualReadingEntryBottomSheet extends StatefulWidget {
  final Function(int verses) onSubmit;

  const ManualReadingEntryBottomSheet({super.key, required this.onSubmit});

  @override
  State<ManualReadingEntryBottomSheet> createState() => _ManualReadingEntryBottomSheetState();
}

class _ManualReadingEntryBottomSheetState extends State<ManualReadingEntryBottomSheet> {
  final _controller = TextEditingController();
  bool _isPages = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim()) ?? 0;
    if (value > 0) {
      final verses = _isPages ? value * 15 : value; // Estimate 15 verses per page if pages selected
      widget.onSubmit(verses);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_log_manual_reading'.tr,
            style: AppTextStyles.headingMedium.copyWith(color: colors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'msg_log_manual_reading_desc'.tr,
            style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: true,
                label: Text('lbl_pages'.tr),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('lbl_verses'.tr),
              ),
            ],
            selected: {_isPages},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isPages = newSelection.first;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isPages ? 'lbl_number_of_pages'.tr : 'lbl_number_of_verses'.tr,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('lbl_save'.tr),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
