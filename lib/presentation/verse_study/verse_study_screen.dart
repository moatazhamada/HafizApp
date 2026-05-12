import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/injection_container.dart' as di;
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_post/qf_post_remote_data_source.dart';
import 'bloc/verse_study_bloc.dart';

class VerseStudyScreen extends StatelessWidget {
  final String verseKey;

  const VerseStudyScreen({super.key, required this.verseKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerseStudyBloc(
        dataSource: di.sl<QfVerseStudyRemoteDataSource>(),
        postDataSource: di.sl<QfPostRemoteDataSource>(),
      )..add(LoadVerseStudy(verseKey)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('lbl_verse_study_title'.tr.replaceAll('{key}', verseKey)),
        ),
        body: const _VerseStudyView(),
      ),
    );
  }
}

class _VerseStudyView extends StatelessWidget {
  const _VerseStudyView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerseStudyBloc, VerseStudyState>(
      builder: (context, state) {
        if (state is VerseStudyLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is VerseStudyError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.read<VerseStudyBloc>().add(
                      LoadVerseStudy(state.verseKey!),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: Text('lbl_retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is VerseStudyLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.arabicText.isNotEmpty) ...[
                  _SectionCard(
                    title: 'lbl_arabic'.tr,
                    icon: Icons.format_quote,
                    color: Colors.teal,
                    child: SelectableText(
                      state.arabicText,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: PrefUtils().getQuranFontSize(),
                        height: 2.0,
                        fontFamily: 'NotoNaskhArabic',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (state.translation.isNotEmpty) ...[
                  _SectionCard(
                    title: 'lbl_translation'.tr,
                    icon: Icons.translate,
                    color: Colors.blue,
                    child: SelectableText(_stripHtml(state.translation)),
                  ),
                  const SizedBox(height: 20),
                ],
                if (state.tafsir.isNotEmpty) ...[
                  _SectionCard(
                    title: 'lbl_tafsir_ibn_kathir'.tr,
                    icon: Icons.menu_book,
                    color: Colors.deepPurple,
                    child: SelectableText(_stripHtml(state.tafsir)),
                  ),
                  const SizedBox(height: 20),
                ],
                _ReflectionsSection(
                  verseKey: state.verseKey ?? '',
                  reflections: state.reflections,
                  isLoading: state.reflectionsLoading,
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

String _stripHtml(String htmlText) {
  final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(regex, '').trim();
}

class _ReflectionsSection extends StatefulWidget {
  final String verseKey;
  final List<Map<String, dynamic>> reflections;
  final bool isLoading;

  const _ReflectionsSection({
    required this.verseKey,
    required this.reflections,
    required this.isLoading,
  });

  @override
  State<_ReflectionsSection> createState() => _ReflectionsSectionState();
}

class _ReflectionsSectionState extends State<_ReflectionsSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReflectionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset submitting state once the bloc adds the new reflection.
    if (_isSubmitting &&
        oldWidget.reflections.length != widget.reflections.length) {
      setState(() => _isSubmitting = false);
    }
  }

  void _submitReflection() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    context.read<VerseStudyBloc>().add(
      CreateReflection(verseKey: widget.verseKey, text: text),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'lbl_reflections'.tr,
      icon: Icons.edit_note,
      color: Colors.teal,
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
              decoration: InputDecoration(
                hintText: 'lbl_write_reflection'.tr,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
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
                (r) => _ReflectionCard(
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

class _ReflectionCard extends StatelessWidget {
  final String text;
  final String date;
  final String postId;

  const _ReflectionCard({
    required this.text,
    required this.date,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'lbl_delete'.tr,
                  onPressed: () => context.read<VerseStudyBloc>().add(
                    DeleteReflection(postId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
