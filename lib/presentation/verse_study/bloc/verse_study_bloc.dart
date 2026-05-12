import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_post/qf_post_remote_data_source.dart';

part 'verse_study_event.dart';
part 'verse_study_state.dart';

class VerseStudyBloc extends Bloc<VerseStudyEvent, VerseStudyState> {
  final QfVerseStudyRemoteDataSource dataSource;
  final QfPostRemoteDataSource? postDataSource;

  VerseStudyBloc({required this.dataSource, this.postDataSource})
    : super(const VerseStudyInitial()) {
    on<LoadVerseStudy>(_onLoadVerseStudy);
    on<LoadReflections>(_onLoadReflections);
    on<CreateReflection>(_onCreateReflection);
    on<DeleteReflection>(_onDeleteReflection);
  }

  Future<void> _onLoadVerseStudy(
    LoadVerseStudy event,
    Emitter<VerseStudyState> emit,
  ) async {
    emit(VerseStudyLoading(verseKey: event.verseKey));
    try {
      final data = await dataSource.getVerseStudy(event.verseKey);
      emit(
        VerseStudyLoaded(
          arabicText: data.arabicText,
          translation: data.translation,
          tafsir: data.tafsir,
          verseKey: event.verseKey,
        ),
      );
      // Auto-load reflections if authenticated
      if (postDataSource != null) {
        add(LoadReflections(event.verseKey));
      }
    } catch (e) {
      emit(VerseStudyError(message: e.toString(), verseKey: event.verseKey));
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
    } catch (_) {
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
}
