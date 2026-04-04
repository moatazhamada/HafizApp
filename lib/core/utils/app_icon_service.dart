import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class AppIconService {
  static const String defaultIcon = 'DefaultIcon';
  static const String ramadanIcon = 'RamadanIcon';

  static const _channel = MethodChannel('com.hafiz.app/app_icon');

  // Icon switching disabled - using single default icon
  static Future<void> updateIconBasedOnSeason() async {
    // Disabled to prevent multiple launcher icons issue
    return;
  }

  static Future<String?> getCurrentIcon() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

    try {
      final result = await _channel.invokeMethod<String>('getIconName');
      return result;
    } catch (e) {
      return null;
    }
  }

  static Future<void> setRamadanIcon() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('setIconName', {'iconName': ramadanIcon});
      Logger.info('Switched to Ramadan icon', feature: 'AppIcon');
    } catch (e) {
      Logger.error('Failed to set Ramadan icon', feature: 'AppIcon', error: e);
    }
  }

  static Future<void> setDefaultIcon() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('setIconName', {'iconName': null});
      Logger.info('Switched to default icon', feature: 'AppIcon');
    } catch (e) {
      Logger.error('Failed to set default icon', feature: 'AppIcon', error: e);
    }
  }
}
