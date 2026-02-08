import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/app_constants.dart';
import 'package:hafiz_app/core/analytics/analytics_helper.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:rxdart/rxdart.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SurahRepository repository;
  final _analytics = sl<AnalyticsHelper>();

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(AppConstants.searchDebounceDelay),
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
      Failure? verseSearchFailure;

      // 2. Search Verses (Async, heavier) - only if query is meaningful or explicit
      if (query.length > AppConstants.searchMinQueryLength) {
        final result = await repository.searchVerses(query);
        result.fold(
          (failure) => verseSearchFailure = failure,
          (verses) => verseResults = verses,
        );
      }

      if (surahResults.isEmpty && verseResults.isEmpty) {
        if (verseSearchFailure != null) {
          emit(SearchError(verseSearchFailure.toString()));
        } else {
          emit(const SearchEmpty());
        }
      } else {
        // Log analytics
        final totalResults = surahResults.length + verseResults.length;
        _analytics.logSearchPerformed(query, totalResults);
        emit(SearchLoaded(surahResults, verseResults: verseResults));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
