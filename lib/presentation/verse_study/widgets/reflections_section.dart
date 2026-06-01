import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/input_formatters.dart';
import 'package:hafiz_app/core/utils/input_validators.dart';
import 'section_card.dart';
import 'reflection_card.dart';
import '../bloc/verse_study_bloc.dart';

class ReflectionsSection extends StatefulWidget {
  final String verseKey;
  final List<Map<String, dynamic>> reflections;
  final bool isLoading;

  const ReflectionsSection({
    super.key,
    required this.verseKey,
    required this.reflections,
    required this.isLoading,
  });

  @override
  State<ReflectionsSection> createState() => _ReflectionsSectionState();
}

class _ReflectionsSectionState extends State<ReflectionsSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReflectionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSubmitting &&
        oldWidget.reflections.length != widget.reflections.length) {
      setState(() => _isSubmitting = false);
    }
  }

  void _submitReflection() {
    final text = _controller.text.trim();
    final validator = InputValidators.compose([
      InputValidators.required(),
      InputValidators.maxLength(2000),
    ]);
    final error = validator(text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    context.read<VerseStudyBloc>().add(
      CreateReflection(verseKey: widget.verseKey, text: text),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'lbl_reflections'.tr,
      icon: Icons.edit_note,
      color: AppColors.of(context).statBookmark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              inputFormatters: [
                AppInputFormatters.maxLength(2000),
                AppInputFormatters.noLeadingSpaces,
              ],
              decoration: InputDecoration(
                hintText: 'lbl_write_reflection'.tr,
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitReflection,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text('lbl_post_reflection'.tr),
              ),
            ),
            if (widget.reflections.isNotEmpty) ...[
              const Divider(height: 32),
              ...widget.reflections.map(
                (r) => ReflectionCard(
                  text: r['text'] as String? ?? '',
                  date: r['createdAt'] as String? ?? '',
                  postId: r['id']?.toString() ?? '',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
