import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/bookmarks/bookmarks_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/test_app_widget.dart';

class MockBookmarkBloc extends MockBloc<BookmarkEvent, BookmarkState>
    implements BookmarkBloc {}

void main() {
  late MockBookmarkBloc mockBookmarkBloc;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockBookmarkBloc = MockBookmarkBloc();
    setupStrictOverflowHandler();
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return BlocProvider<BookmarkBloc>.value(
      value: mockBookmarkBloc,
      child: mountTestWidget(
        const BookmarksScreen(),
        // Small screen size to easily catch overflows
        screenSize: screenSize,
      ),
    );
  }

  group('BookmarksScreen UI Tests', () {
    testWidgets('renders loading skeleton when state is BookmarkLoading', (
      WidgetTester tester,
    ) async {
      when(() => mockBookmarkBloc.state).thenReturn(BookmarkLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      // Should find multiple SkeletonListItems
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders empty state when state is BookmarkLoaded and empty', (
      WidgetTester tester,
    ) async {
      when(() => mockBookmarkBloc.state).thenReturn(const BookmarkLoaded([]));

      await tester.pumpWidget(createWidgetUnderTest());

      // Should find the empty state icon and button icon
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('renders list of bookmarks when state is BookmarkLoaded', (
      WidgetTester tester,
    ) async {
      final bookmarks = [
        BookmarkModel(
          surahId: 1,
          surahName: 'Al-Fatiha',
          verseNumber: 1,
          createdAt: DateTime.now(),
        ),
        BookmarkModel(
          surahId: 2,
          surahName: 'Al-Baqarah',
          verseNumber: 255,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockBookmarkBloc.state).thenReturn(BookmarkLoaded(bookmarks));

      await tester.pumpWidget(createWidgetUnderTest());

      // the UI uses a ListView.separated
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Dismissible), findsNWidgets(2));
    });

    testWidgets('renders error message when state is BookmarkError', (
      WidgetTester tester,
    ) async {
      when(
        () => mockBookmarkBloc.state,
      ).thenReturn(const BookmarkError('Failed to load'));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining('Failed to load'), findsOneWidget);
    });

    testWidgets('renders layout correctly in landscape without overflows', (
      WidgetTester tester,
    ) async {
      when(() => mockBookmarkBloc.state).thenReturn(const BookmarkLoaded([]));
      await tester.pumpWidget(
        createWidgetUnderTest(screenSize: const Size(800, 360)),
      );
      await tester.pump();
    });
  });
}
