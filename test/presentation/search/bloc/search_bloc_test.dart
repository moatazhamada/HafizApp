import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/datasource/qf_search/qf_search_remote_data_source.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:hafiz_app/presentation/search/bloc/search_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockSurahRepository extends Mock implements SurahRepository {}

class MockQfSearchRemoteDataSource extends Mock
    implements QfSearchRemoteDataSource {}

void main() {
  late MockSurahRepository mockRepository;
  late MockQfSearchRemoteDataSource mockSearchRemote;
  late SearchBloc searchBloc;

  final testVerses = [
    const Verse(
      chapterNumber: 1,
      verseNumber: 1,
      arabicText: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      audioTimestampMs: 0,
    ),
  ];

  setUp(() {
    mockRepository = MockSurahRepository();
    mockSearchRemote = MockQfSearchRemoteDataSource();
    searchBloc = SearchBloc(
      repository: mockRepository,
      searchRemoteDataSource: mockSearchRemote,
    );

    // Default: online search returns empty (simulates offline or no online results)
    when(
      () => mockSearchRemote.search(
        any(),
        size: any(named: 'size'),
        page: any(named: 'page'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => []);
  });

  tearDown(() => searchBloc.close());

  test('initial state is SearchInitial', () {
    expect(searchBloc.state, isA<SearchInitial>());
  });

  group('SearchQueryChanged', () {
    blocTest<SearchBloc, SearchState>(
      'emits [SearchInitial] when query is empty',
      build: () => searchBloc,
      act: (bloc) => bloc.add(const SearchQueryChanged('')),
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<SearchInitial>()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] when searching for surah name',
      build: () {
        when(
          () => mockRepository.searchVerses(any()),
        ).thenAnswer((_) async => const Right([]));
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('Fatiha')),
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<SearchLoading>(), isA<SearchLoaded>()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] with verse results',
      build: () {
        when(
          () => mockRepository.searchVerses(any()),
        ).thenAnswer((_) async => Right(testVerses));
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('الله')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<SearchLoading>(),
        predicate<SearchState>((state) {
          if (state is SearchLoaded) {
            return state.verseResults.isNotEmpty;
          }
          return false;
        }),
      ],
      verify: (_) {
        verify(() => mockRepository.searchVerses(any())).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchEmpty] when no results found',
      build: () {
        when(
          () => mockRepository.searchVerses(any()),
        ).thenAnswer((_) async => const Right([]));
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('xyz123')),
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<SearchLoading>(), isA<SearchEmpty>()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] even when repository fails (graceful fallback)',
      build: () {
        when(
          () => mockRepository.searchVerses(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Search failed')));
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('Fatiha')),
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<SearchLoading>(), isA<SearchLoaded>()],
    );

    blocTest<SearchBloc, SearchState>(
      'does not search verses when query is 2 chars or less',
      build: () {
        when(
          () => mockRepository.searchVerses(any()),
        ).thenAnswer((_) async => Right(testVerses));
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('Al')),
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<SearchLoading>(), isA<SearchLoaded>()],
      verify: (_) {
        verifyNever(() => mockRepository.searchVerses(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'merges online results when local results are sparse',
      build: () {
        when(
          () => mockRepository.searchVerses(any()),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => mockSearchRemote.search(
            any(),
            size: any(named: 'size'),
            page: any(named: 'page'),
            language: any(named: 'language'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'verse_key': '2:255',
              'text': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
              'translations': [
                {
                  'text':
                      'Allah - there is no deity except Him, the Ever-Living.',
                },
              ],
            },
          ],
        );
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('Allah')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<SearchLoading>(),
        predicate<SearchState>((state) {
          if (state is SearchLoaded) {
            return state.verseResults.isNotEmpty && state.isSemantic;
          }
          return false;
        }),
      ],
      verify: (_) {
        verify(
          () => mockSearchRemote.search(
            any(),
            size: any(named: 'size'),
            page: any(named: 'page'),
            language: any(named: 'language'),
          ),
        ).called(1);
      },
    );
  });
}
