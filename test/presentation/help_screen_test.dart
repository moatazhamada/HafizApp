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

  Widget createWidgetUnderTest() {
    return mountTestWidget(
      const HelpScreen(),
      screenSize: const Size(360, 800),
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
  });
}
