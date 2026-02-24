import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/presentation/statistics_screen/statistics_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/test_app_widget.dart';

class MockBookmarkBloc extends MockBloc<BookmarkEvent, BookmarkState>
    implements BookmarkBloc {}

class MockRecitationErrorBloc
    extends MockBloc<RecitationErrorEvent, RecitationErrorState>
    implements RecitationErrorBloc {}

void main() {
  late MockBookmarkBloc mockBookmarkBloc;
  late MockRecitationErrorBloc mockRecitationErrorBloc;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockBookmarkBloc = MockBookmarkBloc();
    mockRecitationErrorBloc = MockRecitationErrorBloc();

    when(() => mockBookmarkBloc.state).thenReturn(const BookmarkLoaded([]));
    when(
      () => mockRecitationErrorBloc.state,
    ).thenReturn(const RecitationErrorLoaded([]));

    setupStrictOverflowHandler();
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookmarkBloc>.value(value: mockBookmarkBloc),
        BlocProvider<RecitationErrorBloc>.value(value: mockRecitationErrorBloc),
      ],
      child: mountTestWidget(const StatisticsScreen(), screenSize: screenSize),
    );
  }

  group('StatisticsScreen UI Tests', () {
    testWidgets('renders layout correctly and handles loaded states', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders layout correctly in landscape without overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(screenSize: const Size(800, 360)),
      );
      await tester.pump();
    });
  });
}
