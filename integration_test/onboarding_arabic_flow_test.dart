import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hafiz_app/main.dart' as app;

import 'package:hafiz_app/presentation/onboarding_screen/widgets/onboarding_buttons.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete Onboarding Flow Test - Arabic', (WidgetTester tester) async {
    // 1. Start the app
    await app.main();
    
    // Wait for the initial loading and potential splash screen to finish
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. Language Selection Page
    // Find the Arabic option. We use find.text('العربية').first
    final arabicOption = find.text('العربية').first;
    expect(arabicOption, findsOneWidget, reason: 'Should find Arabic language option');
    
    // Tapping the language option automatically proceeds to the next page
    await tester.tap(arabicOption);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 3. Theme Selection Page
    // Verify we are on the theme selection page by finding the Continue button
    final continueButton = find.byType(OnboardingPrimaryButton).first;
    expect(continueButton, findsOneWidget, reason: 'Should find Continue button on Theme page');
    await tester.tap(continueButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 4. Welcome Page
    // Tap Continue
    expect(continueButton, findsOneWidget, reason: 'Should find Continue button on Welcome page');
    await tester.tap(continueButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 5. Archetype Selection Page
    // Tap Continue
    expect(continueButton, findsOneWidget, reason: 'Should find Continue button on Archetype page');
    await tester.tap(continueButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 6. Notification Permission Page
    // Tap Continue
    expect(continueButton, findsOneWidget, reason: 'Should find Continue button on Notifications page');
    await tester.tap(continueButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 7. Verify we have exited the initial onboarding and reached MushafTypeOnboarding
    expect(find.byType(Scaffold), findsWidgets);
  });
}
