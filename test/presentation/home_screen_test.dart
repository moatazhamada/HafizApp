import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/analytics/analytics_helper.dart';
import 'package:hafiz_app/core/analytics/analytics_route_observer.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/network/network_info.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/scroll/scroll_position_cubit.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/home_screen/bloc/home_bloc.dart';
import 'package:hafiz_app/presentation/home_screen/home_screen.dart';
import 'package:hafiz_app/theme/bloc/theme_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/test_app_widget.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

class MockScrollPositionCubit extends MockCubit<Map<String, double>>
    implements ScrollPositionCubit {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockAnalyticsHelper extends Mock implements AnalyticsHelper {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAnalyticsRouteObserver extends Mock
    implements AnalyticsRouteObserver {}

void main() {
  late MockHomeBloc mockHomeBloc;
  late MockThemeBloc mockThemeBloc;
  late MockScrollPositionCubit mockScrollCubit;
  late MockNetworkInfo mockNetworkInfo;
  late MockAnalyticsHelper mockAnalyticsHelper;
  late MockAnalyticsService mockAnalyticsService;
  late MockAnalyticsRouteObserver mockRouteObserver;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockHomeBloc = MockHomeBloc();
    mockThemeBloc = MockThemeBloc();
    mockScrollCubit = MockScrollPositionCubit();
    mockNetworkInfo = MockNetworkInfo();
    mockAnalyticsHelper = MockAnalyticsHelper();
    mockAnalyticsService = MockAnalyticsService();
    mockRouteObserver = MockAnalyticsRouteObserver();

    setupStrictOverflowHandler();

    // Setup default values
    when(() => mockHomeBloc.state).thenReturn(const HomeState());
    when(() => mockThemeBloc.state).thenReturn(LightThemeState());
    when(() => mockScrollCubit.state).thenReturn({});
    when(() => mockScrollCubit.getOffset(any())).thenReturn(null);
    when(() => mockNetworkInfo.isConnected()).thenAnswer((_) async => true);
    when(
      () => mockNetworkInfo.onConnectivityChanged,
    ).thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

    // Register mocks in GetIt
    if (sl.isRegistered<HomeBloc>()) {
      sl.unregister<HomeBloc>();
    }
    sl.registerFactory<HomeBloc>(() => mockHomeBloc);

    if (sl.isRegistered<ThemeBloc>()) {
      sl.unregister<ThemeBloc>();
    }
    sl.registerFactory<ThemeBloc>(() => mockThemeBloc);

    if (sl.isRegistered<ScrollPositionCubit>()) {
      sl.unregister<ScrollPositionCubit>();
    }
    sl.registerLazySingleton<ScrollPositionCubit>(() => mockScrollCubit);

    if (sl.isRegistered<NetworkInfo>()) {
      sl.unregister<NetworkInfo>();
    }
    sl.registerLazySingleton<NetworkInfo>(() => mockNetworkInfo);

    if (sl.isRegistered<AnalyticsHelper>()) {
      sl.unregister<AnalyticsHelper>();
    }
    sl.registerLazySingleton<AnalyticsHelper>(() => mockAnalyticsHelper);

    if (sl.isRegistered<AnalyticsService>()) {
      sl.unregister<AnalyticsService>();
    }
    sl.registerLazySingleton<AnalyticsService>(() => mockAnalyticsService);

    if (sl.isRegistered<AnalyticsRouteObserver>()) {
      sl.unregister<AnalyticsRouteObserver>();
    }
    sl.registerLazySingleton<AnalyticsRouteObserver>(() => mockRouteObserver);
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return mountTestWidget(const HomeScreen(), screenSize: screenSize);
  }

  group('HomeScreen UI Tests', () {
    testWidgets('renders basic layout with surah list correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // HomeScreen uses SliverList in CustomScrollView, not ListView
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.textContaining('Al-Baqarah'), findsWidgets);
    });

    testWidgets('displays offline banner when network is disconnected', (
      WidgetTester tester,
    ) async {
      when(() => mockNetworkInfo.isConnected()).thenAnswer((_) async => false);
      when(
        () => mockNetworkInfo.onConnectivityChanged,
      ).thenAnswer((_) => Stream.value([ConnectivityResult.none]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.textContaining('You are offline'), findsOneWidget);
    });

    testWidgets('displays Last Read Card if provided in state', (
      WidgetTester tester,
    ) async {
      final surah = Surah(1, 'Al-Fatiha', 'الفاتحة');
      when(
        () => mockHomeBloc.state,
      ).thenReturn(UpdateLastReadSurah(surah: surah));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.textContaining('Resume Reading'), findsOneWidget);
      expect(find.text('Al-Fatiha'), findsWidgets);
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
