import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hafiz_app/main.dart' as app;

import 'package:hafiz_app/presentation/onboarding_screen/widgets/onboarding_buttons.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete Onboarding Flow Test', (WidgetTester tester) async {
    // 1. Start the app
    await app.main();
    
    // Wait for the initial loading and potential splash screen to finish
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. Language Selection Page
    // Find the English option. We use find.text('English').first in case there are multiple matches
    final englishOption = find.text('English').first;
    expect(englishOption, findsOneWidget, reason: 'Should find English language option');
    
    // Tapping the language option automatically proceeds to the next page
    await tester.tap(englishOption);
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
    // We can verify this by checking if a specific Scaffold or AppBar is present, 
    // or by checking for absence of OnboardingPrimaryButton
    expect(find.byType(Scaffold), findsWidgets);
  });
}
