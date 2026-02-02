import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static LogMode _logMode = LogMode.debug;
  static FirebaseCrashlytics? _crashlytics;

  static void init(LogMode mode, {FirebaseCrashlytics? crashlytics}) {
    Logger._logMode = mode;
    Logger._crashlytics = crashlytics;
  }

  /// Debug level - only logged in debug mode
  static void debug(dynamic message, {String? feature}) {
    _log(LogLevel.debug, message, feature: feature);
  }

  /// Info level - general information
  static void info(dynamic message, {String? feature}) {
    _log(LogLevel.info, message, feature: feature);
  }

  /// Warning level - potential issues
  static void warning(
    dynamic message, {
    String? feature,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message, feature: feature, stackTrace: stackTrace);
  }

  /// Error level - actual errors, reported to Crashlytics in production
  static void error(
    dynamic message, {
    String? feature,
    StackTrace? stackTrace,
    Object? error,
    bool fatal = false,
  }) {
    _log(
      LogLevel.error,
      message,
      feature: feature,
      stackTrace: stackTrace,
      error: error,
    );

    // Report to Crashlytics in production mode
    if (_logMode == LogMode.live && _crashlytics != null) {
      _crashlytics!.recordError(
        error ?? message,
        stackTrace,
        reason: feature != null ? '[$feature] $message' : message.toString(),
        fatal: fatal,
      );
    }
  }

  /// Legacy log method for backward compatibility
  static void log(dynamic data, {StackTrace? stackTrace}) {
    error(data, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    dynamic message, {
    String? feature,
    StackTrace? stackTrace,
    Object? error,
  }) {
    if (_logMode == LogMode.debug || level == LogLevel.error) {
      final prefix = _levelPrefix(level);
      final featureTag = feature != null ? '[$feature] ' : '';
      final stackInfo = stackTrace != null ? '\n$stackTrace' : '';
      debugPrint('$prefix$featureTag$message$stackInfo');
    }

    // Log custom keys to Crashlytics for context
    if (_logMode == LogMode.live &&
        _crashlytics != null &&
        level == LogLevel.error) {
      if (feature != null) {
        _crashlytics!.setCustomKey('last_feature', feature);
      }
      _crashlytics!.setCustomKey('last_error', message.toString());
    }
  }

  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG] ';
      case LogLevel.info:
        return '[INFO] ';
      case LogLevel.warning:
        return '[WARN] ';
      case LogLevel.error:
        return '[ERROR] ';
    }
  }

  /// Log a non-fatal error to Crashlytics
  static void recordNonFatal(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
  }) {
    if (_logMode == LogMode.live && _crashlytics != null) {
      _crashlytics!.recordError(error, stackTrace, reason: reason, fatal: false);
    }
    if (_logMode == LogMode.debug) {
      debugPrint('[NON-FATAL] ${reason ?? ''}: $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }

  /// Set user identifier for Crashlytics
  static void setUserId(String userId) {
    _crashlytics?.setUserIdentifier(userId);
  }

  /// Log a custom key-value pair
  static void setCustomKey(String key, dynamic value) {
    _crashlytics?.setCustomKey(key, value.toString());
  }
}

enum LogMode { debug, live }