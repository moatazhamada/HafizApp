import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/custom_elevated_button.dart';

import '../utils/test_app_widget.dart';

void main() {
  group('CustomElevatedButton Tests', () {
    testWidgets('renders text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          CustomElevatedButton(text: 'Click Me', onPressed: () {}),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        mountTestWidget(
          CustomElevatedButton(
            text: 'Tap Me',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(pressed, isTrue);
    });
  });
}
