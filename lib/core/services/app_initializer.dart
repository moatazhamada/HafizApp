import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/qf_api_config.dart';
import '../notifications/notification_service.dart';
import '../services/home_widget_service.dart';
import '../services/deep_link_handler.dart';
import '../utils/logger.dart';
import '../utils/pref_utils.dart';
import '../quran_index/mushaf_page_index.dart';
import '../../firebase_options.dart';
import '../../injection_container.dart' as di;
import '../../injection_container.dart';
import '../../data/migrations/migration_runner.dart';
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

    // Fail fast if production QF credentials are missing.
    // This prevents shipping a build that cannot authenticate.
    if (QfApiConfig.defaultIsProduction) {
      if (QfApiConfig.clientId.isEmpty) {
        throw StateError(
          'QF_CLIENT_ID is empty. Build with --dart-define=QF_CLIENT_ID=...',
        );
      }
      if (QfApiConfig.clientSecret.isEmpty) {
        throw StateError(
          'QF_CLIENT_SECRET is empty. Build with --dart-define=QF_CLIENT_SECRET=...',
        );
      }
    }

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

    // HydratedStorage is now initialized in main() before runApp()
    // to guarantee it is available before any HydratedBloc is instantiated.

    try {
      await Hive.initFlutter();
    } catch (e) {
      Logger.warning('Hive init failed: $e', feature: 'Init');
    }

    final cipher = await _encryptionCipher();

    const sensitiveBoxes = [
      'bookmarks',
      'recitation_errors',
      'recitation_sessions',
      'memorization_progress',
      'reading_logs',
      'reading_goal',
    ];
    const openBoxes = [
      'surah_cache',
      'quran_word_cache',
      'offline_reading_sessions',
    ];
    await Future.wait(
      sensitiveBoxes.map((box) => _openBoxWithEncryption(box, cipher)),
    );
    await Future.wait(
      openBoxes.map((box) async {
        try {
          await Hive.openBox(box);
        } catch (e) {
          Logger.error(
            'Failed to open box $box, attempting recovery: $e',
            feature: 'Init',
            error: e,
          );
          // Try once more before destroying data
          try {
            await Hive.openBox(box);
            Logger.info('Box $box opened on retry', feature: 'Init');
          } catch (_) {
            try {
              await Hive.deleteBoxFromDisk(box);
              await Hive.openBox(box);
              Logger.error(
                'Box $box was corrupted and had to be recreated. User data in this box was lost.',
                feature: 'Init',
              );
            } catch (e2) {
              Logger.error(
                'Box $box unrecoverable after delete: $e2',
                feature: 'Init',
                error: e2,
              );
            }
          }
        }
      }),
    );

    // Run version-based data migrations
    try {
      await MigrationRunner([
        EnsureReadingLogSyncStatusMigration(),
      ]).run();
    } catch (e) {
      Logger.warning('Migration run failed: $e', feature: 'Init');
    }

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

    // Compact Hive boxes to reclaim disk space from deleted entries
    unawaited(_compactHiveBoxes());

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

  static Future<void> _compactHiveBoxes() async {
    const boxes = [
      'recitation_errors',
      'bookmarks',
      'offline_reading_sessions',
      'reading_logs',
      'recitation_sessions',
      'memorization_progress',
    ];
    for (final name in boxes) {
      if (Hive.isBoxOpen(name)) {
        try { await Hive.box(name).compact(); } catch (_) {}
      }
    }
  }

  /// Open a box with encryption. If the box already exists unencrypted on
  /// disk (e.g. upgraded from an earlier version), leave it unencrypted to
  /// avoid data loss. New boxes are created with AES-256 encryption.
  static Future<void> _openBoxWithEncryption(String name, HiveAesCipher? cipher) async {
    try {
      if (cipher != null) {
        await Hive.openBox(name, encryptionCipher: cipher);
      } else {
        await Hive.openBox(name);
      }
    } catch (e) {
      if (cipher != null && e.toString().contains('invalid')) {
        // Cipher mismatch — box exists without encryption. Fall back.
        Logger.warning('Box $name exists without encryption, opening as plaintext', feature: 'Init');
        try { await Hive.openBox(name); } catch (_) {
          await _recoverBox(name);
        }
      } else {
        Logger.error('Failed to open box $name: $e', feature: 'Init', error: e);
        await _recoverBox(name);
      }
    }
  }

  static Future<void> _recoverBox(String name) async {
    try { await Hive.openBox(name); } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(name);
        await Hive.openBox(name);
        Logger.error('Box $name was corrupted and had to be recreated.', feature: 'Init');
      } catch (e) {
        Logger.error('Box $name unrecoverable: $e', feature: 'Init', error: e);
      }
    }
  }

  /// Return a HiveAesCipher using a persistent key stored in secure storage.
  /// Returns null on platforms where secure storage is not available (web).
  static Future<HiveAesCipher?> _encryptionCipher() async {
    const key = 'hive_encryption_key';
    try {
      final storage = const FlutterSecureStorage();
      var rawKey = await storage.read(key: key);
      if (rawKey == null || rawKey.isEmpty) {
        rawKey = base64Encode(Hive.generateSecureKey());
        await storage.write(key: key, value: rawKey);
      }
      return HiveAesCipher(base64Decode(rawKey));
    } catch (e) {
      Logger.warning('Hive encryption key unavailable: $e', feature: 'Init');
      return null;
    }
  }
}
