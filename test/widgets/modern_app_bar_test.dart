import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/modern_app_bar.dart';

import '../utils/test_app_widget.dart';

void main() {
  group('ModernAppBar Tests', () {
    testWidgets('renders title and essential actions without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        mountTestWidget(
          const Scaffold(
            appBar: ModernAppBar(
              title: 'Modern Title',
              leadingIcon: Icons.menu,
              actions: [
                Icon(Icons.search, key: ValueKey('action_1')),
                Icon(Icons.settings, key: ValueKey('action_2')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Modern Title'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byKey(const ValueKey('action_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('action_2')), findsOneWidget);
    });

    testWidgets('moves excess actions to overflow menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        mountTestWidget(
          const Scaffold(
            appBar: ModernAppBar(
              title: 'Overflow Title',
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: null,
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: null,
                  tooltip: 'Settings',
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: null,
                  tooltip: 'Share',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      // 'Share' should be in the popup menu, not directly visible as an action icon
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });
}
