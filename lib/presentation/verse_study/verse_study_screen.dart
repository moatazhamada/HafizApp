import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/injection_container.dart' as di;
import 'package:hafiz_app/core/quran/quran_word_service.dart';
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_post/qf_post_remote_data_source.dart';
import 'bloc/verse_study_bloc.dart';
import 'widgets/overview_tab.dart';
import 'widgets/tafsir_tab.dart';
import 'widgets/translation_tab.dart';
import 'widgets/word_by_word_section.dart';
import 'package:hafiz_app/widgets/loading_indicator.dart';

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
        length: 4,
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
                // TODO: Re-enable reflections tab when QuranReflect integration is ready
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
          return const LoadingIndicator();
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
              OverviewTab(state: state),
              TafsirTab(state: state),
              TranslationTab(state: state),
              WordByWordSection(words: state.words),
              // TODO: Re-enable reflections tab when QuranReflect integration is ready
              // ReflectionsTab(state: state),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
