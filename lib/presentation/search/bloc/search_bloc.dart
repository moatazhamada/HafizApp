import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/data/datasource/qf_search/qf_search_remote_data_source.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SurahRepository repository;
  final QfSearchRemoteDataSource searchRemoteDataSource;

  SearchBloc({required this.repository, required this.searchRemoteDataSource})
    : super(SearchInitial()) {
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
      Failure? verseSearchFailure;

      // 2. Determine if this is a semantic/natural language query
      final isSemanticQuery = _isSemanticQuery(query);

      // 3. Search Verses (local first)
      if (query.length > 2) {
        final result = await repository.searchVerses(query);
        result.fold(
          (failure) => verseSearchFailure = failure,
          (verses) => verseResults = verses,
        );
      }

      // 4. If local search yielded no results and query looks semantic, try QF search
      if (verseResults.isEmpty &&
          surahResults.isEmpty &&
          isSemanticQuery &&
          query.length > 3) {
        try {
          final qfResults = await searchRemoteDataSource.search(
            event.query,
            size: 20,
          );
          if (qfResults.isNotEmpty) {
            // QF search results include verse_key which we map to Verse objects
            final semanticVerses = _mapQfResultsToVerses(qfResults);
            if (semanticVerses.isNotEmpty) {
              emit(
                SearchLoaded(
                  surahResults,
                  verseResults: semanticVerses,
                  isSemantic: true,
                ),
              );
              return;
            }
          }
        } catch (e) {
          Logger.warning(
            'QF semantic search failed, using local fallback: $e',
            feature: 'Search',
          );
        }
      }

      if (surahResults.isEmpty && verseResults.isEmpty) {
        if (verseSearchFailure != null) {
          emit(SearchError(verseSearchFailure.toString()));
        } else {
          emit(const SearchEmpty());
        }
      } else {
        emit(SearchLoaded(surahResults, verseResults: verseResults));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  /// Detect if a query is a natural language / semantic query rather than
  /// an exact Arabic text search or surah reference.
  bool _isSemanticQuery(String query) {
    // If query contains Latin letters and spaces, likely a semantic query
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(query);
    final hasSpaces = query.contains(' ');
    final hasLatinWords = hasLatin && hasSpaces && query.split(' ').length >= 2;

    // Common semantic query patterns in English
    final semanticPatterns = [
      RegExp(r'\b(verse|verses|about|surah|chapter)\b', caseSensitive: false),
      RegExp(
        r'\b(patience|mercy|forgiveness|prayer|faith|peace|love)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(hardship|guidance|heaven|hell|paradise|grace)\b',
        caseSensitive: false,
      ),
    ];

    if (hasLatinWords) return true;
    for (final pattern in semanticPatterns) {
      if (pattern.hasMatch(query)) return true;
    }
    return false;
  }

  /// Map QF search API results to Verse objects.
  List<Verse> _mapQfResultsToVerses(List<Map<String, dynamic>> results) {
    final verses = <Verse>[];
    for (final result in results) {
      try {
        final verseKey = result['verse_key'] ?? result['verseKey'] ?? '';
        final text =
            result['text'] ??
            result['verse_text'] ??
            result['textUthmani'] ??
            '';
        if (verseKey.isEmpty) continue;

        final parts = verseKey.split(':');
        if (parts.length != 2) continue;

        final surahId = int.tryParse(parts[0]) ?? 0;
        final verseNum = int.tryParse(parts[1]) ?? 0;
        if (surahId < 1 || surahId > 114) continue;

        verses.add(
          Verse(
            chapterNumber: surahId,
            verseNumber: verseNum,
            arabicText: text,
            translationText: result['translation'] ?? result['translated_text'],
            audioTimestampMs: 0,
          ),
        );
      } catch (e) {
        Logger.warning('Failed to map QF search result: $e', feature: 'Search');
      }
    }
    return verses;
  }
}
