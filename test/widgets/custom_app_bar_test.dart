import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/custom_app_bar.dart';

import '../utils/test_app_widget.dart';

void main() {
  group('CustomAppBar Tests', () {
    testWidgets('renders title and back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          const Scaffold(
            appBar: CustomAppBar(
              title: Text('Test Title'),
              leading: Icon(Icons.arrow_back),
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          const Scaffold(
            appBar: CustomAppBar(
              actions: [Icon(Icons.search, key: ValueKey('search_key'))],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('search_key')), findsOneWidget);
    });
  });
}
