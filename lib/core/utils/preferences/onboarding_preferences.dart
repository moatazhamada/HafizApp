import 'package:hafiz_app/core/utils/pref_utils.dart';

class OnboardingPreferences {
  String? getLastRunVersion() {
    try {
      return PrefUtils.prefs.getString('lastRunVersion');
    } catch (e) {
      return null;
    }
  }

  void setLastRunVersion(String version) {
    try {
      PrefUtils.prefs.setString('lastRunVersion', version);
    } catch (e) {
      // Silently ignore
    }
  }

  /// Returns true if onboarding has been completed for the current app version.
  bool getOnboardingCompleted() {
    try {
      final completedVersion = PrefUtils.prefs.getString(
        'onboardingCompletedVersion',
      );
      if (completedVersion == null) return false;
      final currentVersion = PrefUtils.cachedAppVersion;
      if (currentVersion == null) return completedVersion.isNotEmpty;
      return completedVersion == currentVersion;
    } catch (e) {
      return false;
    }
  }

  /// Marks onboarding as completed for the current app version.
  Future<void> setOnboardingCompleted(bool value) async {
    if (value) {
      final version = PrefUtils.cachedAppVersion ?? '';
      await PrefUtils.prefs.setString('onboardingCompletedVersion', version);
      await PrefUtils.prefs.setBool('app_first_open', false);
    } else {
      await PrefUtils.prefs.remove('onboardingCompletedVersion');
    }
  }

  bool getHifzMigrationCompleted() {
    try {
      return PrefUtils.prefs.getBool('hifz_migration_completed') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setHifzMigrationCompleted(bool value) async {
    await PrefUtils.prefs.setBool('hifz_migration_completed', value);
  }

  int getOnboardingStep() {
    try {
      return PrefUtils.prefs.getInt('onboarding_step') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> setOnboardingStep(int step) async {
    await PrefUtils.prefs.setInt('onboarding_step', step);
  }

  /// Returns true if this is the first time the app has ever been opened.
  bool isFirstEverOpen() {
    try {
      return PrefUtils.prefs.getBool('app_first_open') ?? true;
    } catch (e) {
      return true;
    }
  }
}
