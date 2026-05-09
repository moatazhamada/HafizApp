import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hafiz_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Surah reading flow', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(AppBar), findsWidgets);
    expect(find.text('Al-Fatihah'), findsOneWidget);
  });
}
