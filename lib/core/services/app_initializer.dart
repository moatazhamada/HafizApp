import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../notifications/notification_service.dart';
import '../services/home_widget_service.dart';
import '../services/deep_link_handler.dart';
import '../utils/logger.dart';
import '../utils/pref_utils.dart';
import '../quran_index/mushaf_page_index.dart';
import '../../firebase_options.dart';
import '../../injection_container.dart' as di;
import '../../injection_container.dart';
import 'remote_config_service.dart';

class AppInitializer {
  bool forceUpdate = false;
  String? error;

  Future<bool> init() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    try {
      await PrefUtils().init();
    } catch (e) {
      Logger.warning('PrefUtils init failed: $e', feature: 'Init');
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      PrefUtils().setCachedAppVersion(packageInfo.version);
    } catch (e) {
      Logger.warning('PackageInfo init failed: $e', feature: 'Init');
    }

    try {
      final storage = await HydratedStorage.build(
        storageDirectory: kIsWeb
            ? HydratedStorageDirectory.web
            : HydratedStorageDirectory(
                (await getTemporaryDirectory()).path,
              ),
      );
      HydratedBloc.storage = storage;
    } catch (e) {
      Logger.warning('HydratedStorage init failed: $e', feature: 'Init');
    }

    try {
      await Hive.initFlutter();
    } catch (e) {
      Logger.warning('Hive init failed: $e', feature: 'Init');
    }

    const boxes = [
      'surah_cache',
      'bookmarks',
      'recitation_errors',
      'recitation_sessions',
      'memorization_progress',
      'reading_logs',
      'reading_goal',
      'quran_word_cache',
      'offline_reading_sessions',
    ];
    await Future.wait(
      boxes.map((box) async {
        try {
          await Hive.openBox(box);
        } catch (e) {
          Logger.warning('Failed to open box $box: $e', feature: 'Init');
        }
      }),
    );

    try {
      await sl.reset();
      await di.init();
    } catch (e) {
      Logger.warning('Critical init failed: $e', feature: 'Init');
      error = e.toString();
      return false;
    }

    try {
      await MushafPageIndex.loadFromAsset();
    } catch (e) {
      Logger.warning('MushafPageIndex load failed: $e', feature: 'Init');
    }

    try {
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
    } catch (e) {
      Logger.warning('Orientation setup failed: $e', feature: 'Init');
    }

    return true;
  }

  Future<void> postInitHeavyTasks() async {
    // 1. Firebase Core – required, works on all platforms
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Firebase Core init failed: $e',
        feature: 'Firebase',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // 2. Crashlytics – iOS / Android / macOS only
    FirebaseCrashlytics? crashlytics;
    try {
      crashlytics = FirebaseCrashlytics.instance;
    } catch (e) {
      Logger.warning('Crashlytics not available on this platform: $e', feature: 'Init');
    }
    Logger.init(
      kDebugMode ? LogMode.debug : LogMode.live,
      crashlytics: crashlytics,
    );

    // Open Hive cache boxes
    try {
      await Hive.openBox('qiraat_cache');
      await Hive.openBox('audio_cache');
    } catch (e) {
      Logger.warning('Hive cache open failed: $e', feature: 'Init');
    }

    // 3. Global error handlers
    FlutterError.onError = (errorDetails) {
      Logger.error(
        'Flutter error: ${errorDetails.exception}',
        feature: 'Flutter',
        error: errorDetails.exception,
        stackTrace: errorDetails.stack,
        fatal: true,
      );
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      } catch (e) {
        // Crashlytics not available on this platform
        Logger.info('Crashlytics not available on this platform: $e', feature: 'Init');
      }
    };

    ui.PlatformDispatcher.instance.onError = (error, stack) {
      Logger.error(
        'Platform error: $error',
        feature: 'Platform',
        error: error,
        stackTrace: stack,
        fatal: true,
      );
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (e) {
        // Crashlytics not available on this platform
        Logger.info('Crashlytics not available on this platform: $e', feature: 'Init');
      }
      return true;
    };

    // 4. Analytics – web, iOS, Android, macOS only
    try {
      unawaited(FirebaseAnalytics.instance.logAppOpen());
    } catch (e) {
      Logger.warning('Analytics not available on this platform: $e', feature: 'Init');
    }

    // 5. Local notifications – not available on web
    // Only schedule automatically if onboarding is already completed.
    // During first onboarding, the user explicitly chooses on the
    // NotificationPermissionPage.
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      if (PrefUtils().getOnboardingCompleted()) {
        await notificationService.scheduleDailyVerse();
        await notificationService.scheduleReadingReminder();
        await notificationService.scheduleFridayKahf();
      }
    } catch (e) {
      Logger.warning(
        'Notifications not available on this platform: $e',
        feature: 'Notifications',
      );
    }

    // 6. Home Widget – iOS / Android / macOS only
    try {
      final homeWidgetService = sl<HomeWidgetService>();
      unawaited(homeWidgetService.initialize());
    } catch (e) {
      Logger.warning(
        'HomeWidget not available on this platform: $e',
        feature: 'HomeWidget',
      );
    }

    // 7. Deep Link – iOS / Android / macOS only
    try {
      final deepLinkHandler = sl<DeepLinkHandler>();
      unawaited(deepLinkHandler.initialize());
    } catch (e) {
      Logger.warning(
        'DeepLink not available on this platform: $e',
        feature: 'DeepLink',
      );
    }

    // 8. Remote Config – web, iOS, Android, macOS only
    try {
      final remoteConfigService = RemoteConfigService();
      await remoteConfigService.init();
      if (!sl.isRegistered<RemoteConfigService>()) {
        sl.registerLazySingleton(() => remoteConfigService);
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      final minCode = remoteConfigService.minVersionCode;
      if (currentCode < minCode && minCode > 0) {
        forceUpdate = true;
        Logger.info(
          'Force update required: $currentCode < $minCode',
          feature: 'RemoteConfig',
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Remote Config initialization failed: $e',
        feature: 'RemoteConfig',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
