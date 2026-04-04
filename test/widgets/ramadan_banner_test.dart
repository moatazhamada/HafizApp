import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/ramadan_banner.dart';

import '../utils/test_app_widget.dart';

// We mock RamadanTheme in a way we can control if possible, or we just test the branch it takes.
// RamadanTheme is static, so we might not be able to mock it easily without changing code.
// However, the test should at least render without crashing.

void main() {
  group('RamadanBanner Tests', () {
    testWidgets('renders without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          const Scaffold(body: Column(children: [RamadanBanner()])),
        ),
      );

      // It may render SizedBox.shrink or the actual banner depending on the date.
      // We just ensure it builds without RenderFlex overflow exceptions.
      expect(find.byType(RamadanBanner), findsOneWidget);
    });
  });
}
