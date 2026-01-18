import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SurahRepository repository;

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(const Duration(milliseconds: 500)),
    );
  }

  EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      final query = event.query.toLowerCase();
      // 1. Search Surah Names (In-Memory, fast)
      final surahResults = QuranIndex.quranSurahs.where((surah) {
        final matchesEnglish = surah.nameEnglish.toLowerCase().contains(query);
        final matchesArabic = surah.nameArabic.contains(query);
        final matchesId = surah.id.toString().contains(query);
        return matchesEnglish || matchesArabic || matchesId;
      }).toList();

      List<Verse> verseResults = [];

      // 2. Search Verses (Async, heavier) - only if query is meaningful (>2 chars) or explicit
      if (query.length > 2) {
        final result = await repository.searchVerses(query);
        result.fold(
          (failure) => null, // Ignore failure for now, just show empty
          (verses) => verseResults = verses,
        );
      }

      if (surahResults.isEmpty && verseResults.isEmpty) {
        emit(const SearchEmpty());
      } else {
        emit(SearchLoaded(surahResults, verseResults: verseResults));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
