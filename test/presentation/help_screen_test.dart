import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/presentation/help_screen/help_screen.dart';

import '../utils/test_app_widget.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    setupStrictOverflowHandler();
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return mountTestWidget(
      const HelpScreen(),
      screenSize: screenSize,
    );
  }

  group('HelpScreen UI Tests', () {
    testWidgets('renders basic layout correctly without overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(
        find.textContaining('App Guide'),
        findsOneWidget,
      ); // Translated title
    });

    testWidgets('renders layout correctly in landscape without overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(screenSize: const Size(800, 360)));
      await tester.pump();
    });
  });
}
