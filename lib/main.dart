import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hafiz_app/injection_container.dart' as di;

import 'core/app_export.dart';
import 'core/utils/app_icon_service.dart';
import 'injection_container.dart';
import 'widgets/offline_indicator.dart';

import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
// Just in case, though safe
// Just in case
// Just in case

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'core/i18n/locale_controller.dart';
import 'core/analytics/analytics_route_observer.dart';
import 'core/deep_link/deep_link_service.dart';
import 'package:flutter/foundation.dart';
import 'core/quran_index/quran_surah.dart';
import 'core/quran_index/mushaf_page_index.dart';
import 'core/ramadan/ramadan_theme.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF006754), // deep green accent
    brightness: Brightness.light,
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Color(0xFF006754),
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF87D1A4), // soft green tint for dark
    brightness: Brightness.dark,
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Color(0xFF1E3320),
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
);

/// Get appropriate light theme (regular or Ramadan)
ThemeData get currentLightTheme =>
    RamadanTheme.isRamadan ? RamadanTheme.ramadanTheme : lightTheme;

/// Get appropriate dark theme (regular or Ramadan)
ThemeData get currentDarkTheme =>
    RamadanTheme.isRamadan ? RamadanTheme.ramadanDarkTheme : darkTheme;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI configuration
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BootstrapApp());
}

void setOrientationFromPrefs() {
  final mode = PrefUtils().getOrientationMode();
  switch (mode) {
    case 'portrait':
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      break;
    case 'landscape':
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      break;
    case 'auto':
    default:
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      break;
  }
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Critical initialization (fast)
      await PrefUtils().init().timeout(const Duration(seconds: 2));

      // Set orientation from preferences
      setOrientationFromPrefs();

      // Update app icon based on season (Ramadan)
      unawaited(AppIconService.updateIconBasedOnSeason());

      // Load page data in background to avoid blocking startup
      unawaited(MushafPageIndex.loadPageDataFromAsset());

      // Initialize Hive with all boxes
      await Hive.initFlutter();
      await Future.wait([
        Hive.openBox('surah_cache'),
        Hive.openBox('bookmarks'),
        Hive.openBox('recitation_errors'),
        Hive.openBox('qiraat_cache'),
        Hive.openBox('audio_cache'),
      ]).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Hive initialization timed out');
          return [];
        },
      );

      // Dependency injection
      await di.init();

      // HydratedStorage for BLoC persistence
      final storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(
          (await getApplicationDocumentsDirectory()).path,
        ),
      );
      HydratedBloc.storage = storage;

      // Firebase initialization (with timeout to prevent hanging)
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 3));

        final crashlytics = FirebaseCrashlytics.instance;
        Logger.init(
          kDebugMode ? LogMode.debug : LogMode.live,
          crashlytics: crashlytics,
        );

        // Set up error handlers
        FlutterError.onError = (errorDetails) {
          Logger.error(
            'Flutter error: ${errorDetails.exception}',
            feature: 'Flutter',
            error: errorDetails.exception,
            stackTrace: errorDetails.stack,
            fatal: true,
          );
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };

        ui.PlatformDispatcher.instance.onError = (error, stack) {
          Logger.error(
            'Platform error: $error',
            feature: 'Platform',
            error: error,
            stackTrace: stack,
            fatal: true,
          );
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        unawaited(FirebaseAnalytics.instance.logAppOpen());
      } catch (e, stackTrace) {
        // Log Firebase init failure but continue - app can work without it
        debugPrint('Firebase initialization failed: $e');
        Logger.error(
          'Firebase initialization failed',
          feature: 'Firebase',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } catch (e, stack) {
      debugPrint('Initialization failed: $e');
      Logger.error(
        'Bootstrap initialization failed',
        feature: 'Bootstrap',
        error: e,
        stackTrace: stack,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return const MyApp();
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BrandedSplashScreen(),
    );
  }
}

class _BrandedSplashScreen extends StatelessWidget {
  const _BrandedSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006754),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF006754), Color(0xFF005544), Color(0xFF004433)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 100,
                  height: 100,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hafiz',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'حافظ',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 32,
                color: Colors.white70,
              ),
            ),
            const Spacer(flex: 2),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DeepLinkService _deepLinkService = sl<DeepLinkService>();

  final themeBloc = sl<ThemeBloc>();
  final bookmarkBloc = sl<BookmarkBloc>();
  final recitationErrorBloc = sl<RecitationErrorBloc>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    await _deepLinkService.initialize(onDeepLink: _handleDeepLink);
  }

  void _handleDeepLink(DeepLinkData data) {
    final navigator = NavigatorService.navigatorKey.currentState;
    if (navigator == null) return;

    switch (data.type) {
      case DeepLinkType.verse:
        if (data.surahId != null) {
          final surahIndex = QuranIndex.quranSurahs.indexWhere(
            (s) => s.id == data.surahId,
          );
          if (surahIndex == -1) {
            debugPrint('Ignoring invalid deep link surahId ${data.surahId}');
            return;
          }
          final surah = QuranIndex.quranSurahs[surahIndex];
          final verseNumber = data.verseNumber ?? 1;
          if (verseNumber < 1 || verseNumber > surah.verseCount) {
            debugPrint(
              'Ignoring invalid deep link verse $verseNumber for surah ${surah.id}',
            );
            return;
          }
          navigator.pushNamed(
            AppRoutes.surahPage,
            arguments: {
              'surah': surah,
              'verseIndex': verseNumber - 1,
              'resume': true,
            },
          );
        }
        break;
      case DeepLinkType.mushafPage:
        if (data.pageNumber != null) {
          AppRoutes.goToMushaf(navigator.context, page: data.pageNumber);
        }
        break;
      case DeepLinkType.juz:
        // Handle Juz deep link
        break;
    }
  }

  ThemeMode _getThemeMode() {
    final mode = PrefUtils().getThemeMode();
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    themeBloc.close();
    bookmarkBloc.close();
    recitationErrorBloc.close();
    super.dispose();
  }

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
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return ValueListenableBuilder<Locale>(
            valueListenable: LocaleController.notifier,
            builder: (_, locale, _) => MaterialApp(
              themeMode: _getThemeMode(),
              theme: currentLightTheme,
              darkTheme: currentDarkTheme,
              locale: locale,
              title: 'Hafiz',
              navigatorKey: NavigatorService.navigatorKey,
              scaffoldMessengerKey: globalMessengerKey,
              navigatorObservers: [sl<AnalyticsRouteObserver>()],
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizationDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en', 'US'), Locale('ar', 'EG')],
              initialRoute: AppRoutes.onboardingScreen,
              routes: AppRoutes.routes,
              builder: (context, child) {
                return OfflineIndicator(
                  child: child ?? const SizedBox.shrink(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
