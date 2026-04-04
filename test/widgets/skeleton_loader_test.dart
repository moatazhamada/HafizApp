import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/skeleton_loader.dart';

import '../utils/test_app_widget.dart';

void main() {
  group('SkeletonLoader Tests', () {
    testWidgets('renders shimmer container without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        mountTestWidget(
          Scaffold(
            body: SkeletonLoader(
              width: 100,
              height: 20,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}
