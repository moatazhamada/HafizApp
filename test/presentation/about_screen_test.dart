import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/about_screen/about_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/test_app_widget.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockAnalyticsService mockAnalyticsService;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockAnalyticsService = MockAnalyticsService();
    setupStrictOverflowHandler();

    if (sl.isRegistered<AnalyticsService>()) sl.unregister<AnalyticsService>();
    sl.registerLazySingleton<AnalyticsService>(() => mockAnalyticsService);
  });

  Widget createWidgetUnderTest() {
    return mountTestWidget(
      const AboutScreen(),
      screenSize: const Size(360, 800),
    );
  }

  group('AboutScreen UI Tests', () {
    testWidgets('renders basic layout correctly without overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(
        find.textContaining('About Hafiz'),
        findsOneWidget,
      ); // Translated title
    });
  });
}
