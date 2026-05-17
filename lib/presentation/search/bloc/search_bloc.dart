import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/quran/arabic_normalizer.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
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
      final normalizedQuery = ArabicNormalizer.forDisplay(query);
      final surahResults = QuranIndex.quranSurahs.where((surah) {
        final matchesEnglish = surah.nameEnglish.toLowerCase().contains(query);
        final matchesArabic = ArabicNormalizer.forDisplay(surah.nameArabic)
            .contains(normalizedQuery);
        final matchesId = surah.id.toString().contains(query);
        return matchesEnglish || matchesArabic || matchesId;
      }).toList();

      List<Verse> verseResults = [];
      bool usedOnlineSearch = false;

      // 2. Search local verses (offline) for queries > 2 chars
      if (query.length > 2) {
        final result = await repository.searchVerses(query);
        result.fold((failure) {
          Logger.warning('Local search failed: $failure', feature: 'Search');
        }, (verses) => verseResults = List.of(verses));
      }

      // 3. If local search returned few/no results, try online search
      if (verseResults.length < 5 && query.length > 2) {
        try {
          final isArabicQuery = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
          final onlineResults = await searchRemoteDataSource.search(
            event.query,
            size: 20,
            language: isArabicQuery ? null : 'en',
          );
          if (onlineResults.isNotEmpty) {
            final onlineVerses = _mapSearchResultsToVerses(onlineResults);
            if (onlineVerses.isNotEmpty) {
              // Merge with local results, avoiding duplicates
              final existingKeys = verseResults
                  .map((v) => '${v.chapterNumber}:${v.verseNumber}')
                  .toSet();
              for (final v in onlineVerses) {
                final key = '${v.chapterNumber}:${v.verseNumber}';
                if (!existingKeys.contains(key)) {
                  verseResults.add(v);
                  existingKeys.add(key);
                }
              }
              usedOnlineSearch = true;
            }
          }
        } catch (e) {
          Logger.warning(
            'Online search failed, using local results: $e',
            feature: 'Search',
          );
        }
      }

      if (surahResults.isEmpty && verseResults.isEmpty) {
        emit(const SearchEmpty());
      } else {
        emit(
          SearchLoaded(
            surahResults,
            verseResults: verseResults,
            isSemantic: usedOnlineSearch,
          ),
        );
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  /// Map search API results to Verse objects.
  /// Handles both Quran.com v4 format and generic formats.
  List<Verse> _mapSearchResultsToVerses(List<Map<String, dynamic>> results) {
    final verses = <Verse>[];
    for (final result in results) {
      try {
        final verseKey = result['verse_key'] ?? result['verseKey'] ?? '';
        if (verseKey.isEmpty) continue;

        final parts = verseKey.split(':');
        if (parts.length != 2) continue;

        final surahId = int.tryParse(parts[0]) ?? 0;
        final verseNum = int.tryParse(parts[1]) ?? 0;
        if (surahId < 1 || surahId > 114) continue;

        // Extract Arabic text
        final text =
            result['text'] ??
            result['verse_text'] ??
            result['textUthmani'] ??
            '';

        // Extract translation from nested translations array (Quran.com v4)
        String? translation;
        final translations = result['translations'];
        if (translations is List && translations.isNotEmpty) {
          final first = translations[0];
          if (first is Map<String, dynamic>) {
            translation = first['text'] as String?;
          }
        }
        // Fallback to flat field
        translation ??= result['translation'] ?? result['translated_text'];

        verses.add(
          Verse(
            chapterNumber: surahId,
            verseNumber: verseNum,
            arabicText: text.toString(),
            translationText: translation,
            audioTimestampMs: 0,
          ),
        );
      } catch (e) {
        Logger.warning('Failed to map search result: $e', feature: 'Search');
      }
    }
    return verses;
  }
}
