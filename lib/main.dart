import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hafiz_app/injection_container.dart' as di;

import 'core/app_export.dart';
import 'injection_container.dart';

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
import 'package:flutter/foundation.dart';

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
  appBarTheme: const AppBarTheme(centerTitle: true),
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
  appBarTheme: const AppBarTheme(centerTitle: true),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
              theme: lightTheme,
              darkTheme: darkTheme, // Important for automatic switching
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Critical functional initialization (fast)
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    try {
      await PrefUtils().init();

      // Hive boxes must be open before di.init() because DI reads Hive.box(...)
      await Hive.initFlutter();
      await Hive.openBox('surah_cache');
      await Hive.openBox('bookmarks');
      await Hive.openBox('recitation_errors');
      await Hive.openBox('recitation_sessions');
      await Hive.openBox('memorization_progress');
      await Hive.openBox('reading_logs');
      await Hive.openBox('reading_goal');

      await di.init();

      final orientationMode = PrefUtils().getOrientationMode();
      List<DeviceOrientation> orientations;
      switch (orientationMode) {
        case 'portrait':
          orientations = [DeviceOrientation.portraitUp];
          break;
        case 'landscape':
          orientations = [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ];
          break;
        default:
          orientations = [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ];
      }
      await SystemChrome.setPreferredOrientations(orientations);

      final storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(
          (await getTemporaryDirectory()).path,
        ),
      );
      HydratedBloc.storage = storage;
    } catch (e) {
      debugPrint('Critical init failed: $e');
      // If critical init fails, we might still want to try showing the app
      // or at least not stuck on splash forever, though likely it will crash later.
    }

    // 2. Heavy/External services (can be slow, prone to network issues)
    // We don't want to block the UI forever if Firebase/Hive hangs.
    try {
      await _postInitHeavyTasks().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Heavy init failed or timed out: $e');
      // Continue anyway so the user sees the app
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  Future<void> _postInitHeavyTasks() async {
    try {
      await initFirebase();

      final crashlytics = FirebaseCrashlytics.instance;
      Logger.init(
        kDebugMode ? LogMode.debug : LogMode.live,
        crashlytics: crashlytics,
      );

      await Hive.initFlutter();
      await Hive.openBox('surah_cache');
      await Hive.openBox('bookmarks');
      await Hive.openBox('recitation_errors');
      await Hive.openBox('recitation_sessions');
      await Hive.openBox('memorization_progress');
      await Hive.openBox('reading_logs');
      await Hive.openBox('reading_goal');
      await Hive.openBox('qiraat_cache');
      await Hive.openBox('audio_cache');

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
      Logger.error(
        'Firebase initialization failed: $e',
        feature: 'Firebase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow; // Re-throw to trigger the timeout catch in _init if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _ready ? const _ReadyApp() : const _SplashScaffold(),
    );
  }
}

class _ReadyApp extends StatelessWidget {
  const _ReadyApp();
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
      home: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark
                    ? const Color(0xFF87D1A4)
                    : const Color(0xFF006754),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Hafiz...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
