import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/analytics/analytics_helper.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/settings_screen/settings_screen.dart';
import 'package:hafiz_app/theme/bloc/theme_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/test_app_widget.dart';

class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

class MockAnalyticsHelper extends Mock implements AnalyticsHelper {}

void main() {
  late MockThemeBloc mockThemeBloc;
  late MockAnalyticsHelper mockAnalyticsHelper;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockThemeBloc = MockThemeBloc();
    mockAnalyticsHelper = MockAnalyticsHelper();

    setupStrictOverflowHandler();

    when(() => mockThemeBloc.state).thenReturn(LightThemeState());

    if (sl.isRegistered<ThemeBloc>()) sl.unregister<ThemeBloc>();
    sl.registerFactory<ThemeBloc>(() => mockThemeBloc);

    if (sl.isRegistered<AnalyticsHelper>()) sl.unregister<AnalyticsHelper>();
    sl.registerLazySingleton<AnalyticsHelper>(() => mockAnalyticsHelper);
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return mountTestWidget(const SettingsScreen(), screenSize: screenSize);
  }

  group('SettingsScreen UI Tests', () {
    testWidgets('renders basic layout correctly without overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
