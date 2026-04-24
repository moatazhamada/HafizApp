import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/injection_container.dart' as di;
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'bloc/verse_study_bloc.dart';

class VerseStudyScreen extends StatelessWidget {
  final String verseKey;

  const VerseStudyScreen({super.key, required this.verseKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          VerseStudyBloc(dataSource: di.sl<QfVerseStudyRemoteDataSource>())
            ..add(LoadVerseStudy(verseKey)),
      child: Scaffold(
        appBar: AppBar(title: Text('Verse Study: $verseKey')),
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
                      LoadVerseStudy(
                        context.read<VerseStudyBloc>().state.toString(),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
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
                    title: 'Arabic',
                    icon: Icons.format_quote,
                    color: Colors.teal,
                    child: SelectableText(
                      state.arabicText,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 2.0,
                        fontFamily: 'NotoNaskhArabic',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (state.translation.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Translation',
                    icon: Icons.translate,
                    color: Colors.blue,
                    child: SelectableText(_stripHtml(state.translation)),
                  ),
                  const SizedBox(height: 20),
                ],
                if (state.tafsir.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Tafsir (Ibn Kathir)',
                    icon: Icons.menu_book,
                    color: Colors.deepPurple,
                    child: SelectableText(_stripHtml(state.tafsir)),
                  ),
                ],
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
