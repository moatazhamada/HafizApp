import 'package:flutter/widgets.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

class ThemePreferences {
  static const String _themeModeKey = 'themeMode';

  Future<void> setThemeMode(String mode) async {
    await PrefUtils.prefs.setString(_themeModeKey, mode);
  }

  String getThemeMode() {
    try {
      return PrefUtils.prefs.getString(_themeModeKey) ?? 'system';
    } catch (e) {
      Logger.warning('Failed to get theme mode: $e', feature: 'Preferences');
      return 'system';
    }
  }

  /// Deprecated: compatibility shim.
  bool getIsDarkMode() {
    final mode = getThemeMode();
    if (mode == 'dark') return true;
    if (mode == 'light') return false;
    if (mode == 'system') {
      try {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
      } catch (e) {
        Logger.warning(
          'Failed to get platform brightness: $e',
          feature: 'Preferences',
        );
        return false;
      }
    }
    return false;
  }

  /// Deprecated: compatibility shim.
  Future<void> setIsDarkMode(bool value) {
    return setThemeMode(value ? 'dark' : 'light');
  }
}
