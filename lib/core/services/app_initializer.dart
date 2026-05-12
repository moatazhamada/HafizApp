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
      debugPrint('PrefUtils init failed: $e');
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      PrefUtils().setCachedAppVersion(packageInfo.version);
    } catch (e) {
      debugPrint('PackageInfo init failed: $e');
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
      debugPrint('HydratedStorage init failed: $e');
    }

    try {
      await Hive.initFlutter();
    } catch (e) {
      debugPrint('Hive init failed: $e');
    }

    const boxes = [
      'surah_cache',
      'bookmarks',
      'recitation_errors',
      'recitation_sessions',
      'memorization_progress',
      'reading_logs',
      'reading_goal',
    ];
    await Future.wait(
      boxes.map((box) async {
        try {
          await Hive.openBox(box);
        } catch (e) {
          debugPrint('Failed to open box $box: $e');
        }
      }),
    );

    try {
      await sl.reset();
      await di.init();
    } catch (e) {
      debugPrint('Critical init failed: $e');
      error = e.toString();
      return false;
    }

    try {
      await MushafPageIndex.loadFromAsset();
    } catch (e) {
      debugPrint('MushafPageIndex load failed: $e');
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
      debugPrint('Orientation setup failed: $e');
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
      debugPrint('Crashlytics not available on this platform: $e');
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
      debugPrint('Hive cache open failed: $e');
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
      } catch (_) {
        // Crashlytics not available on this platform
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
      } catch (_) {
        // Crashlytics not available on this platform
      }
      return true;
    };

    // 4. Analytics – web, iOS, Android, macOS only
    try {
      unawaited(FirebaseAnalytics.instance.logAppOpen());
    } catch (e) {
      debugPrint('Analytics not available on this platform: $e');
    }

    // 5. Local notifications – not available on web
    try {
      final notificationService = DailyVerseNotificationService();
      await notificationService.initialize();
      await notificationService.scheduleDailyVerse();
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
