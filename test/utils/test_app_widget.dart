import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.svg')) {
      final String svgStr =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"></svg>';
      return ByteData.view(Uint8List.fromList(svgStr.codeUnits).buffer);
    }
    return rootBundle.load(key);
  }
}

/// Wraps a widget with MaterialApp and necessary Localization delegates for testing.
Widget mountTestWidget(
  Widget child, {
  Size screenSize = const Size(360, 640),
  double textScaleFactor = 1.0,
  GlobalKey<NavigatorState>? navigatorKey,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) {
  return MaterialApp(
    navigatorKey: navigatorKey ?? NavigatorService.navigatorKey,
    routes: routes,
    localizationsDelegates: const [
      AppLocalizationDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', 'US'), Locale('ar', 'EG')],
    locale: const Locale(
      'en',
      'US',
    ), // default to English for tests, can be changed later
    home: MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: DefaultAssetBundle(
        bundle: MockAssetBundle(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Initializes necessary dependencies (like SharedPreferences mock) for UI tests.
Future<void> setupTestDependencies() async {
  SharedPreferences.setMockInitialValues({});
  await PrefUtils().init();
}

/// A custom error handler block that will strictly fail the test if a RenderFlex overflow occurs.
/// Call this inside `setUp()` or at the start of the `testWidgets` block.
void setupStrictOverflowHandler() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    // ignore: avoid_print
    print('FlutterError detected: ${details.exceptionAsString()}');
    if (details.exceptionAsString().contains('A RenderFlex overflowed') ||
        details.exceptionAsString().contains('overflowed by')) {
      fail('RenderFlex Overflow detected: ${details.exceptionAsString()}');
    }
    // Call the original handler for other errors
    if (originalOnError != null) {
      originalOnError(details);
    }
  };
}
