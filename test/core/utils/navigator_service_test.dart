import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/utils/navigator_service.dart';

void main() {
  group('NavigatorService', () {
    test('navigatorKey is a GlobalKey<NavigatorState>', () {
      expect(NavigatorService.navigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    testWidgets('pushNamed navigates to specified route', (tester) async {
      final key = GlobalKey<NavigatorState>();
      NavigatorService.navigatorKey = key;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const SizedBox.shrink(),
          routes: {'/test': (context) => const Text('Test Route')},
        ),
      );

      NavigatorService.pushNamed('/test');
      await tester.pumpAndSettle();

      expect(find.text('Test Route'), findsOneWidget);
    });

    testWidgets('goBack pops the current route', (tester) async {
      final key = GlobalKey<NavigatorState>();
      NavigatorService.navigatorKey = key;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Text('Home'),
          routes: {'/second': (context) => const Text('Second')},
        ),
      );

      NavigatorService.pushNamed('/second');
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);

      NavigatorService.goBack();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
