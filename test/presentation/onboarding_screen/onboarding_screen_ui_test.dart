import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/network/network_info.dart';
import 'package:hafiz_app/core/utils/image_constant.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/onboarding_screen/onboarding_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/test_app_widget.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() async {
    await setupTestDependencies();

    // Bypass SVG exceptions by pointing to a real PNG
    ImageConstant.imgQuranOnboarding = ImageConstant.imgBismillah;
    ImageConstant.imgGroupCircles = ImageConstant.imgBismillah;
  });

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();

    setupStrictOverflowHandler();

    // Default connectivity
    when(() => mockNetworkInfo.isConnected()).thenAnswer((_) async => true);
    when(
      () => mockNetworkInfo.onConnectivityChanged,
    ).thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

    if (sl.isRegistered<NetworkInfo>()) sl.unregister<NetworkInfo>();
    sl.registerLazySingleton<NetworkInfo>(() => mockNetworkInfo);
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return mountTestWidget(
      Builder(
        builder: (context) {
          return OnboardingScreen.builder(context);
        },
      ),
      screenSize: screenSize,
      routes: {'/onboarding': (context) => OnboardingScreen.builder(context)},
    );
  }

  group('OnboardingScreen UI Tests', () {
    testWidgets('renders normally', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          Builder(
            builder: (context) {
              return OnboardingScreen.builder(context);
            },
          ),
          screenSize: const Size(360, 800),
        ),
      );

      // Wait for animations to finish
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('get_started_key')), findsOneWidget);
    });

    testWidgets('shows offline indicator when disconnected', (
      WidgetTester tester,
    ) async {
      when(() => mockNetworkInfo.isConnected()).thenAnswer((_) async => false);
      when(
        () => mockNetworkInfo.onConnectivityChanged,
      ).thenAnswer((_) => Stream.value([ConnectivityResult.none]));

      await tester.pumpWidget(
        mountTestWidget(
          Builder(
            builder: (context) {
              return OnboardingScreen.builder(context);
            },
          ),
          screenSize: const Size(360, 800),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Internet Connection'), findsOneWidget);
    });

    testWidgets('renders layout correctly in landscape without overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(screenSize: const Size(800, 360)),
      );
      await tester.pump();
    });
  });
}
