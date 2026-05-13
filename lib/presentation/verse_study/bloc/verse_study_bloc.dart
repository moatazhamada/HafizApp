import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/quran/quran_word_models.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/quran/quran_word_service.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_post/qf_post_remote_data_source.dart';

part 'verse_study_event.dart';
part 'verse_study_state.dart';

class VerseStudyBloc extends Bloc<VerseStudyEvent, VerseStudyState> {
  final QfVerseStudyRemoteDataSource dataSource;
  final QfPostRemoteDataSource? postDataSource;
  final QuranWordService wordService;

  VerseStudyBloc({
    required this.dataSource,
    required this.wordService,
    this.postDataSource,
  }) : super(const VerseStudyInitial()) {
    on<LoadVerseStudy>(_onLoadVerseStudy);
    on<LoadVerseStudyWithSources>(_onLoadVerseStudyWithSources);
    on<LoadReflections>(_onLoadReflections);
    on<CreateReflection>(_onCreateReflection);
    on<DeleteReflection>(_onDeleteReflection);
    on<ChangeTafsirSource>(_onChangeTafsirSource);
    on<ChangeTranslationSource>(_onChangeTranslationSource);
  }

  Future<void> _onLoadVerseStudy(
    LoadVerseStudy event,
    Emitter<VerseStudyState> emit,
  ) async {
    final tafsirId = PrefUtils().getPreferredTafsirId();
    final translationId = PrefUtils().getPreferredTranslationId();
    await _fetchAndEmit(
      event.verseKey,
      tafsirId: tafsirId,
      translationId: translationId,
      emit: emit,
    );
  }

  Future<void> _onLoadVerseStudyWithSources(
    LoadVerseStudyWithSources event,
    Emitter<VerseStudyState> emit,
  ) async {
    final tafsirId = event.tafsirId ?? PrefUtils().getPreferredTafsirId();
    final translationId =
        event.translationId ?? PrefUtils().getPreferredTranslationId();
    await _fetchAndEmit(
      event.verseKey,
      tafsirId: tafsirId,
      translationId: translationId,
      emit: emit,
    );
  }

  Future<void> _fetchAndEmit(
    String verseKey, {
    required String tafsirId,
    required String translationId,
    required Emitter<VerseStudyState> emit,
    VerseWordData? existingWords,
    List<Map<String, dynamic>>? existingReflections,
    bool? existingReflectionsLoading,
  }) async {
    emit(VerseStudyLoading(verseKey: verseKey));
    try {
      final results = await Future.wait([
        dataSource.getVerseStudy(
          verseKey,
          tafsirId: tafsirId,
          translationId: translationId,
        ),
        wordService.fetchVerseWords(verseKey),
      ]);
      final data = results[0] as VerseStudyData;
      final words = results[1] as VerseWordData?;
      emit(
        VerseStudyLoaded(
          arabicText: data.arabicText,
          translation: data.translation,
          tafsir: data.tafsir,
          verseKey: verseKey,
          selectedTafsirId: tafsirId,
          selectedTranslationId: translationId,
          words: words,
          reflections: existingReflections ?? const [],
          reflectionsLoading: existingReflectionsLoading ?? false,
        ),
      );
      // Auto-load reflections if authenticated
      if (postDataSource != null) {
        add(LoadReflections(verseKey));
      }
    } catch (e) {
      emit(VerseStudyError(message: e.toString(), verseKey: verseKey));
    }
  }

  Future<void> _onLoadReflections(
    LoadReflections event,
    Emitter<VerseStudyState> emit,
  ) async {
    final current = state;
    if (current is! VerseStudyLoaded || postDataSource == null) return;

    emit(current.copyWith(reflectionsLoading: true));
    try {
      final reflections = await postDataSource!.getReflections(event.verseKey);
      emit(
        current.copyWith(reflections: reflections, reflectionsLoading: false),
      );
    } catch (e) {
      Logger.warning('Failed to load reflections: $e', feature: 'VerseStudyBloc');
      emit(current.copyWith(reflectionsLoading: false));
    }
  }

  Future<void> _onCreateReflection(
    CreateReflection event,
    Emitter<VerseStudyState> emit,
  ) async {
    final current = state;
    if (current is! VerseStudyLoaded || postDataSource == null) return;

    final result = await postDataSource!.createReflection(
      verseKey: event.verseKey,
      text: event.text,
    );
    if (result != null) {
      final updated = [result, ...current.reflections];
      emit(current.copyWith(reflections: updated));
    }
  }

  Future<void> _onDeleteReflection(
    DeleteReflection event,
    Emitter<VerseStudyState> emit,
  ) async {
    final current = state;
    if (current is! VerseStudyLoaded || postDataSource == null) return;

    await postDataSource!.deletePost(event.postId);
    final updated = current.reflections
        .where((r) => r['id']?.toString() != event.postId)
        .toList();
    emit(current.copyWith(reflections: updated));
  }

  Future<void> _onChangeTafsirSource(
    ChangeTafsirSource event,
    Emitter<VerseStudyState> emit,
  ) async {
    final current = state;
    if (current is! VerseStudyLoaded) return;

    await PrefUtils().setPreferredTafsirId(event.id);
    await _fetchAndEmit(
      event.verseKey,
      tafsirId: event.id,
      translationId: current.selectedTranslationId,
      emit: emit,
      existingWords: current.words,
      existingReflections: current.reflections,
      existingReflectionsLoading: current.reflectionsLoading,
    );
  }

  Future<void> _onChangeTranslationSource(
    ChangeTranslationSource event,
    Emitter<VerseStudyState> emit,
  ) async {
    final current = state;
    if (current is! VerseStudyLoaded) return;

    await PrefUtils().setPreferredTranslationId(event.id);
    await _fetchAndEmit(
      event.verseKey,
      tafsirId: current.selectedTafsirId,
      translationId: event.id,
      emit: emit,
      existingWords: current.words,
      existingReflections: current.reflections,
      existingReflectionsLoading: current.reflectionsLoading,
    );
  }
}
