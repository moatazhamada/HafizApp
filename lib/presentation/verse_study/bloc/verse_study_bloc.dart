import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';

part 'verse_study_event.dart';
part 'verse_study_state.dart';

class VerseStudyBloc extends Bloc<VerseStudyEvent, VerseStudyState> {
  final QfVerseStudyRemoteDataSource dataSource;

  VerseStudyBloc({required this.dataSource}) : super(VerseStudyInitial()) {
    on<LoadVerseStudy>(_onLoadVerseStudy);
  }

  Future<void> _onLoadVerseStudy(
    LoadVerseStudy event,
    Emitter<VerseStudyState> emit,
  ) async {
    emit(VerseStudyLoading());
    try {
      final data = await dataSource.getVerseStudy(event.verseKey);
      emit(
        VerseStudyLoaded(
          arabicText: data.arabicText,
          translation: data.translation,
          tafsir: data.tafsir,
        ),
      );
    } catch (e) {
      emit(VerseStudyError(e.toString()));
    }
  }
}
