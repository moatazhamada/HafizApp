import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hafiz_app/core/services/app_initializer.dart';
import 'package:hafiz_app/core/services/app_lifecycle_manager.dart';

import 'core/app_export.dart';
import 'core/network/connectivity_cubit.dart';
import 'core/theme/app_text_styles.dart';
import 'core/services/app_review_service.dart';
import 'injection_container.dart';

import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import 'package:hafiz_app/presentation/auth/bloc/qf_auth_bloc.dart';

import 'dart:async';
import 'core/i18n/locale_controller.dart';
import 'core/analytics/analytics_route_observer.dart';
import 'core/services/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'presentation/force_update/force_update_screen.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF006754), // deep green accent
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFFFFB300), // gold
    tertiary: const Color(0xFF1565C0), // sapphire
    surfaceContainer: const Color(0xFFF5F5F5),
  ),
  textTheme: const TextTheme(
    headlineLarge: AppTextStyles.headingLarge,
    headlineMedium: AppTextStyles.headingMedium,
    headlineSmall: AppTextStyles.headingSmall,
    titleLarge: AppTextStyles.headingSmall,
    titleMedium: AppTextStyles.labelLarge,
    titleSmall: AppTextStyles.labelMedium,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  cardTheme: const CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  dialogTheme: const DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  dividerTheme: const DividerThemeData(space: 1),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  appBarTheme: const AppBarTheme(centerTitle: true),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF87D1A4), // soft green tint for dark
    brightness: Brightness.dark,
  ).copyWith(
    secondary: const Color(0xFFFFCA28), // gold
    tertiary: const Color(0xFF42A5F5), // sapphire
    surfaceContainer: const Color(0xFF2D2D2D),
  ),
  textTheme: const TextTheme(
    headlineLarge: AppTextStyles.headingLarge,
    headlineMedium: AppTextStyles.headingMedium,
    headlineSmall: AppTextStyles.headingSmall,
    titleLarge: AppTextStyles.headingSmall,
    titleMedium: AppTextStyles.labelLarge,
    titleSmall: AppTextStyles.labelMedium,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  cardTheme: const CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  dialogTheme: const DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  dividerTheme: const DividerThemeData(space: 1),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  appBarTheme: const AppBarTheme(centerTitle: true),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  ThemeMode _getThemeMode() {
    final mode = PrefUtils().getThemeMode(); // 'system', 'light', 'dark'
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  final themeBloc = sl<ThemeBloc>();
  final bookmarkBloc = sl<BookmarkBloc>();
  final recitationErrorBloc = sl<RecitationErrorBloc>();
  final cloudSyncBloc = sl<CloudSyncBloc>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: themeBloc),
        BlocProvider.value(
          value: bookmarkBloc..add(const LoadBookmarksEvent()),
        ),
        BlocProvider.value(
          value: recitationErrorBloc..add(const LoadRecitationErrorsEvent()),
        ),
        BlocProvider.value(
          value: sl<QfAuthBloc>()..add(QfAuthCheckRequested()),
        ),
        BlocProvider.value(value: sl<ConnectivityCubit>()),
        BlocProvider.value(value: cloudSyncBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return ValueListenableBuilder<Locale>(
            valueListenable: LocaleController.notifier,
            builder: (_, locale, _) => MaterialApp(
              themeMode: _getThemeMode(),
              theme: lightTheme,
              darkTheme: darkTheme, // Important for automatic switching
              locale: locale,
              title: 'Hafiz',
              navigatorKey: NavigatorService.navigatorKey,
              navigatorObservers: [sl<AnalyticsRouteObserver>()],
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizationDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en', 'US'), Locale('ar', 'EG')],
              initialRoute: PrefUtils().getOnboardingCompleted()
                  ? AppRoutes.homeScreen
                  : AppRoutes.onboardingScreen,
              routes: AppRoutes.routes,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final clampedScale = mediaQuery.textScaler
                    .scale(1.0)
                    .clamp(0.8, 2.0);
                return AppLifecycleManager(
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: TextScaler.linear(clampedScale),
                    ),
                    child: child!,
                  ),
                );
              },
              // Clamp text scale to prevent broken layouts at extreme accessibility
              // sizes while still supporting users who need larger text.
              // Handled by AppLifecycleManager wrapper above.
              // Silently handle unknown routes from navigation state restoration.
              onUnknownRoute: (_) => null,
            ),
          );
        },
      ),
    );
  }
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _ready = false;
  bool _forceUpdate = false;
  bool _initFailed = false;
  String _initError = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final initializer = AppInitializer();
    final success = await initializer.init();

    if (!mounted) return;

    if (!success) {
      setState(() {
        _initFailed = true;
        _initError = initializer.error ?? 'Unknown error';
      });
      return;
    }

    try {
      await initializer.postInitHeavyTasks().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      Logger.warning('Heavy init failed or timed out: $e', feature: 'Bootstrap');
    }

    if (mounted) {
      setState(() {
        _ready = true;
        _forceUpdate = initializer.forceUpdate;
      });
      Future.delayed(const Duration(seconds: 2), () {
        AppReviewService.maybeRequestReview();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_forceUpdate) {
      return ForceUpdateScreen(
        message: sl.isRegistered<RemoteConfigService>()
            ? sl<RemoteConfigService>().forceUpdateMessage
            : '',
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _ready ? const _ReadyApp() : const _SplashScaffold(),
    );
  }
}

class _ReadyApp extends StatefulWidget {
  const _ReadyApp();

  @override
  State<_ReadyApp> createState() => _ReadyAppState();
}

class _ReadyAppState extends State<_ReadyApp> {
  @override
  void initState() {
    super.initState();
    _maybeShowChangelog();
  }

  Future<void> _maybeShowChangelog() async {
    // Never show changelog during or before onboarding.
    if (!PrefUtils().getOnboardingCompleted()) return;
    // Never show changelog on the very first open.
    if (PrefUtils().isFirstEverOpen()) return;

    final version = (await PackageInfo.fromPlatform()).version;
    final key = 'changelog_seen_${version.replaceAll('.', '_')}';
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(key) ?? false;
    if (!seen) {
      await prefs.setBool(key, true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final context = NavigatorService.navigatorKey.currentContext;
          if (context != null) {
            NavigatorService.pushNamed(AppRoutes.changelogScreen);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => MyApp();
}

class _SplashScaffold extends StatelessWidget {
  const _SplashScaffold();
  @override
  Widget build(BuildContext context) {
    // Use the current theme mode to determine splash background
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        backgroundColor: isDark
            ? darkTheme.colorScheme.surface
            : lightTheme.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'بسم الله الرحمن الرحيم',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 22,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                            alpha: isDark ? 0.87 : 0.87,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    color: isDark
                        ? const Color(0xFF87D1A4)
                        : const Color(0xFF006754),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(
                            alpha: isDark ? 0.7 : 0.54,
                          ),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
