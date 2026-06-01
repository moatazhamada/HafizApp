import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

class TranslationPreferences {
  bool getShowTranslation() {
    try {
      return PrefUtils.prefs.getBool('show_translation') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setShowTranslation(bool value) async {
    try {
      await PrefUtils.prefs.setBool('show_translation', value);
    } catch (e) {
      // Silently ignore
    }
  }

  String getPreferredTafsirId() {
    try {
      return PrefUtils.prefs.getString('preferred_tafsir_id') ??
          ApiConfig.tafsirId;
    } catch (e) {
      return ApiConfig.tafsirId;
    }
  }

  Future<void> setPreferredTafsirId(String id) async {
    await PrefUtils.prefs.setString('preferred_tafsir_id', id);
  }

  String getPreferredTranslationId() {
    try {
      return PrefUtils.prefs.getString('preferred_translation_id') ??
          ApiConfig.translationId.toString();
    } catch (e) {
      return ApiConfig.translationId.toString();
    }
  }

  Future<void> setPreferredTranslationId(String id) async {
    await PrefUtils.prefs.setString('preferred_translation_id', id);
  }
}
