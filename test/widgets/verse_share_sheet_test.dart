import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/analytics/analytics_helper.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/widgets/verse_share_sheet.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/test_app_widget.dart';

class MockAnalyticsHelper extends Mock implements AnalyticsHelper {}

void main() {
  late MockAnalyticsHelper mockAnalyticsHelper;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockAnalyticsHelper = MockAnalyticsHelper();

    when(
      () => mockAnalyticsHelper.logVerseShared(any(), any(), any()),
    ).thenAnswer((_) async {});

    if (sl.isRegistered<AnalyticsHelper>()) sl.unregister<AnalyticsHelper>();
    sl.registerLazySingleton<AnalyticsHelper>(() => mockAnalyticsHelper);
  });

  testWidgets('renders Share Sheet correctly', (WidgetTester tester) async {
    final surah = Surah(1, 'Test', 'Test Arabic');
    const verse = Verse(chapterId: 1, verseNumber: 1, text: 'Bismillah');

    await tester.pumpWidget(
      mountTestWidget(
        Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.showVerseShareSheet(surah: surah, verse: verse);
                  },
                  child: const Text('Open Menu'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Initial state has button
    expect(find.text('Open Menu'), findsOneWidget);

    // Tap to open sheet
    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();

    // Verify sheet items
    expect(find.byType(VerseShareSheet), findsOneWidget);
    // Finds elements by key or text. E.g. 'Test (1)'
    expect(find.text('Test (1)'), findsOneWidget);
    expect(find.byIcon(Icons.link), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
  });
}
