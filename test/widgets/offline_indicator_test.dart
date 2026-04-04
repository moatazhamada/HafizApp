import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/offline_indicator.dart';

import '../utils/test_app_widget.dart';

void main() {
  group('OfflineIndicator Tests', () {
    testWidgets('renders without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          const Scaffold(body: OfflineIndicator(child: SizedBox())),
        ),
      );

      expect(find.byType(OfflineIndicator), findsOneWidget);
    });
  });
}
