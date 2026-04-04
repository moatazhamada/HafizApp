import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/recitation_error_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/test_app_widget.dart';

class MockRecitationErrorBloc
    extends MockBloc<RecitationErrorEvent, RecitationErrorState>
    implements RecitationErrorBloc {}

void main() {
  late MockRecitationErrorBloc mockBloc;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockBloc = MockRecitationErrorBloc();
    setupStrictOverflowHandler();
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return BlocProvider<RecitationErrorBloc>.value(
      value: mockBloc,
      child: mountTestWidget(
        const RecitationErrorScreen(),
        screenSize: screenSize,
      ),
    );
  }

  group('RecitationErrorScreen UI Tests', () {
    testWidgets(
      'renders loading skeleton when state is RecitationErrorLoading',
      (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(const RecitationErrorLoading());

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'renders empty state when state is RecitationErrorLoaded and empty',
      (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(const RecitationErrorLoaded([]));

        await tester.pumpWidget(createWidgetUnderTest());

        expect(
          find.textContaining('No verses marked for practice'),
          findsOneWidget,
        ); // Translated msg
      },
    );

    testWidgets('renders list of errors when state is RecitationErrorLoaded', (
      WidgetTester tester,
    ) async {
      final errors = [
        RecitationErrorModel(
          surahId: 1,
          surahName: 'Al-Fatiha',
          verseId: 1,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockBloc.state).thenReturn(RecitationErrorLoaded(errors));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.textContaining('Al-Fatiha'), findsOneWidget);
    });

    testWidgets('renders error message when state is RecitationErrorError', (
      WidgetTester tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const RecitationErrorError('Failed to load'));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(
        find.textContaining('Error'),
        findsOneWidget,
      ); // Translated lbl_error
      expect(find.textContaining('Failed to load'), findsOneWidget);
    });

    testWidgets('renders layout correctly in landscape without overflows', (
      WidgetTester tester,
    ) async {
      when(() => mockBloc.state).thenReturn(const RecitationErrorLoaded([]));
      await tester.pumpWidget(
        createWidgetUnderTest(screenSize: const Size(800, 360)),
      );
      await tester.pump();
    });
  });
}
