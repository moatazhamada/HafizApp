import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/analytics/analytics_helper.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:hafiz_app/presentation/search/bloc/search_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockSurahRepository extends Mock implements SurahRepository {}

class MockAnalyticsHelper extends Mock implements AnalyticsHelper {}

void main() {
  late MockSurahRepository mockRepository;
  late MockAnalyticsHelper mockAnalytics;
  late SearchBloc searchBloc;
  final sl = GetIt.instance;

  final testVerses = [
    const Verse(
      chapterId: 1,
      verseNumber: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
    ),
  ];

  setUpAll(() {
    // Register mock analytics
    if (!sl.isRegistered<AnalyticsHelper>()) {
      sl.registerLazySingleton<AnalyticsHelper>(() => MockAnalyticsHelper());
    }
  });

  setUp(() {
    mockRepository = MockSurahRepository();
    mockAnalytics = sl<AnalyticsHelper>() as MockAnalyticsHelper;
    searchBloc = SearchBloc(repository: mockRepository);

    // Stub analytics methods
    when(
      () => mockAnalytics.logSearchPerformed(any(), any()),
    ).thenAnswer((_) async => Future.value());
  });

  tearDown(() => searchBloc.close());

  tearDownAll(() {
    sl.reset();
  });

  test('initial state is SearchInitial', () {
    expect(searchBloc.state, isA<SearchInitial>());
  });

  group('SearchQueryChanged', () {
    blocTest<SearchBloc, SearchState>(
      'emits [SearchInitial] when query is empty',
      build: () => searchBloc,
      act: (bloc) => bloc.add(const SearchQueryChanged('')),
      wait: const Duration(milliseconds: 600), // Account for debounce
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
        ).thenAnswer((_) async => Left(CacheFailure('Search failed')));
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('Fatiha')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>(), // Still succeeds with surah-name-only results
      ],
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
  });
}
