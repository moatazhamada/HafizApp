import 'package:flutter/foundation.dart';

/// Firebase Environment Configuration
/// Differentiates between testing and production environments
class FirebaseConfig {
  /// Whether the app is running in debug/test mode
  static bool get isDebugMode {
    return kDebugMode;
  }

  /// Whether the app is running in release/production mode
  static bool get isProduction => !isDebugMode;

  /// Environment name for analytics and crash reporting
  static String get environmentName =>
      isDebugMode ? 'development' : 'production';

  /// Crashlytics collection enabled state
  /// In debug mode, we can disable automatic collection to avoid test crashes
  static bool get crashlyticsCollectionEnabled => isProduction;

  /// Analytics collection enabled state
  /// Can be enabled in debug for testing analytics
  static bool get analyticsCollectionEnabled => true;

  /// Performance monitoring enabled state
  static bool get performanceMonitoringEnabled => isProduction;

  /// Remote Config minimum fetch interval
  /// Shorter in debug for testing, longer in production for efficiency
  static Duration get remoteConfigMinFetchInterval {
    return isDebugMode ? const Duration(minutes: 1) : const Duration(hours: 12);
  }

  /// App Store URL for the app
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.hafiz.app.hafiz_app';

  static const String appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';

  /// Get the appropriate store URL for the current platform
  static String get storeUrl {
    // This will be determined at runtime based on platform
    return playStoreUrl; // Default to Play Store
  }
}

/// Environment-specific logging
class EnvironmentLogger {
  /// Log info message (only in debug mode)
  static void info(String message, {String? feature}) {
    if (FirebaseConfig.isDebugMode) {
      debugPrint('[INFO${feature != null ? '::$feature' : ''}] $message');
    }
  }

  /// Log warning message
  static void warning(String message, {String? feature}) {
    if (FirebaseConfig.isDebugMode) {
      debugPrint('[WARN${feature != null ? '::$feature' : ''}] $message');
    }
  }

  /// Log error message (always logs)
  static void error(
    String message, {
    String? feature,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[ERROR${feature != null ? '::$feature' : ''}] $message');
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null && FirebaseConfig.isDebugMode) {
      debugPrint('  Stack: $stackTrace');
    }
  }
}
