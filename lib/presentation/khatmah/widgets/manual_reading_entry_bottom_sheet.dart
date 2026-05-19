import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import 'package:hafiz_app/core/utils/input_formatters.dart';
import 'package:hafiz_app/core/utils/input_validators.dart';

class ManualReadingEntryBottomSheet extends StatefulWidget {
  final Function(int verses) onSubmit;

  const ManualReadingEntryBottomSheet({super.key, required this.onSubmit});

  @override
  State<ManualReadingEntryBottomSheet> createState() => _ManualReadingEntryBottomSheetState();
}

class _ManualReadingEntryBottomSheetState extends State<ManualReadingEntryBottomSheet> {
  final _controller = TextEditingController();
  bool _isPages = true;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _errorText = 'val_invalid_number'.tr);
      return;
    }

    final mushafType = MushafType.fromString(PrefUtils().getMushafType());
    final validator = _isPages
        ? InputValidators.numericRange(min: 1, max: mushafType.totalPages)
        : InputValidators.numericRange(min: 1, max: 6236);
    final error = validator(value.toString());
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    setState(() => _errorText = null);
    final verses = _isPages ? value * 15 : value;
    widget.onSubmit(verses);
    Navigator.of(context).pop();
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
          Semantics(
            label: 'lbl_log_type_selector'.tr,
            child: SegmentedButton<bool>(
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
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            textField: true,
            label: _isPages ? 'lbl_number_of_pages'.tr : 'lbl_number_of_verses'.tr,
            hint: 'msg_enter_amount'.tr,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                AppInputFormatters.digitsOnly,
                AppInputFormatters.maxLength(_isPages ? 3 : 4),
              ],
              decoration: InputDecoration(
                labelText: _isPages ? 'lbl_number_of_pages'.tr : 'lbl_number_of_verses'.tr,
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            button: true,
            label: 'lbl_save_reading_log'.tr,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('lbl_save'.tr),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
