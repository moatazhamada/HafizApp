import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/input_formatters.dart';
import 'package:hafiz_app/core/utils/input_validators.dart';
import 'package:hafiz_app/injection_container.dart' as di;
import 'package:hafiz_app/core/quran/quran_word_service.dart';
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_post/qf_post_remote_data_source.dart';
import 'bloc/verse_study_bloc.dart';
import 'widgets/word_by_word_section.dart';

class VerseStudyScreen extends StatelessWidget {
  final String verseKey;

  const VerseStudyScreen({super.key, required this.verseKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerseStudyBloc(
        dataSource: di.sl<QfVerseStudyRemoteDataSource>(),
        wordService: di.sl<QuranWordService>(),
        postDataSource: di.sl<QfPostRemoteDataSource>(),
      )..add(LoadVerseStudy(verseKey)),
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text('lbl_verse_study_title'.tr.replaceAll('{key}', verseKey)),
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'lbl_tab_overview'.tr),
                Tab(text: 'lbl_tab_tafsir'.tr),
                Tab(text: 'lbl_tab_translation'.tr),
                Tab(text: 'lbl_tab_word_by_word'.tr),
                Tab(text: 'lbl_tab_reflections'.tr),
              ],
            ),
          ),
          body: const _VerseStudyView(),
        ),
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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.of(context).needsReviewStatus,
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
          return TabBarView(
            children: [
              _OverviewTab(state: state),
              _TafsirTab(state: state),
              _TranslationTab(state: state),
              WordByWordSection(words: state.words),
              _ReflectionsTab(state: state),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const _OverviewTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.arabicText.isNotEmpty) ...[
            _SectionCard(
              title: 'lbl_arabic'.tr,
              icon: Icons.format_quote,
              color: AppColors.of(context).statBookmark,
              child: Semantics(
              label: 'lbl_quran_text'.tr,
              textDirection: TextDirection.rtl,
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
            ),
            const SizedBox(height: 20),
          ],
          if (state.translation.isNotEmpty) ...[
            _SectionCard(
              title: 'lbl_translation'.tr,
              icon: Icons.translate,
              color: Theme.of(context).colorScheme.primary,
              child: SelectableText(_stripHtml(state.translation)),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _TafsirTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const _TafsirTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: _tafsirTitleForId(state.selectedTafsirId),
            icon: Icons.menu_book,
            color: Theme.of(context).colorScheme.tertiary,
            trailing: IconButton(
              icon: const Icon(Icons.tune, size: 18),
              tooltip: 'lbl_select_tafsir'.tr,
              onPressed: () => _showSourceSelector(
                context,
                title: 'lbl_select_tafsir'.tr,
                options: _tafsirOptions(context),
                selectedId: state.selectedTafsirId,
                onSelected: (id) => context.read<VerseStudyBloc>().add(
                  ChangeTafsirSource(id: id, verseKey: state.verseKey!),
                ),
              ),
            ),
            child:
                state.tafsir.isNotEmpty
                    ? SelectableText(_stripHtml(state.tafsir))
                    : Text('lbl_loading'.tr),
          ),
        ],
      ),
    );
  }
}

class _TranslationTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const _TranslationTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'lbl_translation'.tr,
            icon: Icons.translate,
            color: Theme.of(context).colorScheme.primary,
            trailing: IconButton(
              icon: const Icon(Icons.tune, size: 18),
              tooltip: 'lbl_select_translation'.tr,
              onPressed: () => _showSourceSelector(
                context,
                title: 'lbl_select_translation'.tr,
                options: _translationOptions,
                selectedId: state.selectedTranslationId,
                onSelected: (id) => context.read<VerseStudyBloc>().add(
                  ChangeTranslationSource(id: id, verseKey: state.verseKey!),
                ),
              ),
            ),
            child:
                state.translation.isNotEmpty
                    ? SelectableText(_stripHtml(state.translation))
                    : Text('lbl_loading'.tr),
          ),
        ],
      ),
    );
  }
}

class _ReflectionsTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const _ReflectionsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _ReflectionsSection(
        verseKey: state.verseKey ?? '',
        reflections: state.reflections,
        isLoading: state.reflectionsLoading,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final rowChildren = <Widget>[
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
    if (trailing != null) {
      rowChildren.add(trailing!);
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: rowChildren),
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

String _tafsirTitleForId(String id) {
  switch (id) {
    case '169':
      return 'Ibn Kathir (Abridged)';
    case '168':
      return "Ma'arif al-Qur'an";
    case '817':
      return 'Tazkirul Quran';
    case '16':
      return 'Muyassar';
    case '93':
      return 'Al-Wasit';
    case '14':
      return 'Ibn Kathir';
    case '15':
      return 'Tabari';
    case '90':
      return 'Qurtubi';
    case '91':
      return "Sa'di";
    case '94':
      return 'Baghawy';
    default:
      return 'Tafsir';
  }
}

List<Map<String, String>> _tafsirOptions(BuildContext context) {
  final isAr = AppLocalization.of()?.locale.languageCode == 'ar';
  if (isAr) {
    return const [
      {'id': '16', 'name': 'الميسر'},
      {'id': '93', 'name': 'الوسيط'},
      {'id': '14', 'name': 'ابن كثير'},
      {'id': '15', 'name': 'الطبري'},
      {'id': '90', 'name': 'القرطبي'},
      {'id': '91', 'name': 'السعدي'},
      {'id': '94', 'name': 'البغوي'},
    ];
  }
  return const [
    {'id': '169', 'name': 'Ibn Kathir (Abridged)'},
    {'id': '168', 'name': "Ma'arif al-Qur'an"},
    {'id': '817', 'name': 'Tazkirul Quran'},
  ];
}

const List<Map<String, String>> _translationOptions = [
  {'id': '85', 'name': 'Clear Quran'},
  {'id': '131', 'name': 'Pickthall'},
  {'id': '84', 'name': 'Muhsin Khan'},
  {'id': '101', 'name': 'Sahih International'},
];

void _showSourceSelector(
  BuildContext context, {
  required String title,
  required List<Map<String, String>> options,
  required String selectedId,
  required ValueChanged<String> onSelected,
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
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id']!;
                final name = option['name']!;
                final isSelected = id == selectedId;
                return ListTile(
                  title: Text(name),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
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
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReflectionsSection oldWidget) {
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
    return _SectionCard(
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
                (r) => _ReflectionCard(
                  text: r['text'] as String? ?? '',
                  date: r['createdAt'] as String? ?? '',
                  postId: r['id']?.toString() ?? '',
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  final parts = widget.verseKey.split(':');
                  if (parts.length == 2) {
                    final surah = parts[0];
                    final ayah = parts[1];
                    launchUrl(Uri.parse('https://quranreflect.com/join/$surah/$ayah'));
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text('lbl_share_to_quran_reflect'.tr),
              ),
            ),
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
