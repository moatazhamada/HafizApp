import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/analytics/analytics_helper.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/search/bloc/search_bloc.dart';
import 'package:hafiz_app/presentation/search/search_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/test_app_widget.dart';

class MockSearchBloc extends MockBloc<SearchEvent, SearchState>
    implements SearchBloc {}

class MockAnalyticsHelper extends Mock implements AnalyticsHelper {}

void main() {
  late MockSearchBloc mockSearchBloc;
  late MockAnalyticsHelper mockAnalyticsHelper;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockSearchBloc = MockSearchBloc();
    mockAnalyticsHelper = MockAnalyticsHelper();

    if (sl.isRegistered<SearchBloc>()) {
      sl.unregister<SearchBloc>();
    }
    sl.registerFactory<SearchBloc>(() => mockSearchBloc);

    if (sl.isRegistered<AnalyticsHelper>()) {
      sl.unregister<AnalyticsHelper>();
    }
    sl.registerLazySingleton<AnalyticsHelper>(() => mockAnalyticsHelper);

    when(
      () => mockAnalyticsHelper.logSearchResultTapped(any(), any()),
    ).thenAnswer((_) async {});

    setupStrictOverflowHandler();
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return mountTestWidget(
      const SearchScreen(),
      screenSize: screenSize, // Small screen to catch overflows
    );
  }

  group('SearchScreen UI Tests', () {
    testWidgets('renders initial state correctly', (WidgetTester tester) async {
      when(() => mockSearchBloc.state).thenReturn(SearchInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.textContaining('Search for a Surah or verse'),
        findsOneWidget,
      ); // Translated key or fallback
    });

    testWidgets('renders loading state correctly', (WidgetTester tester) async {
      when(() => mockSearchBloc.state).thenReturn(SearchLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      // Should find multiple SkeletonListItems (which contains SkeletonLoader)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders empty state correctly', (WidgetTester tester) async {
      when(() => mockSearchBloc.state).thenReturn(SearchEmpty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining('No results found'), findsOneWidget);
    });

    testWidgets('renders loaded state with results correctly', (
      WidgetTester tester,
    ) async {
      final results = [Surah(1, 'Al-Fatiha', 'الفاتحة')];
      final verseResults = [
        const Verse(
          chapterId: 1,
          verseNumber: 1,
          text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        ),
      ];

      when(
        () => mockSearchBloc.state,
      ).thenReturn(SearchLoaded(results, verseResults: verseResults));

      await tester.pumpWidget(createWidgetUnderTest());

      // Should display both Surahs and Verses headers
      expect(find.textContaining('Surahs'), findsOneWidget);
      expect(find.textContaining('Verses'), findsOneWidget);

      // Should display the specific surah and verse
      expect(find.textContaining('Al-Fatiha'), findsWidgets);
    });

    testWidgets('renders error state correctly', (WidgetTester tester) async {
      when(() => mockSearchBloc.state).thenReturn(SearchError('Server error'));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining('Server error'), findsOneWidget);
    });

    testWidgets('renders layout correctly in landscape without overflows', (
      WidgetTester tester,
    ) async {
      when(() => mockSearchBloc.state).thenReturn(SearchInitial());
      await tester.pumpWidget(
        createWidgetUnderTest(screenSize: const Size(800, 360)),
      );
      await tester.pump();
    });
  });
}
