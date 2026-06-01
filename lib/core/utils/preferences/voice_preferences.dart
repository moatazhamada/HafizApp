import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

class VoicePreferences {
  Future<void> setRecitationProvider(String provider) async {
    await PrefUtils.prefs.setString('recitation_provider', provider);
  }

  String getRecitationProvider() {
    try {
      return PrefUtils.prefs.getString('recitation_provider') ?? 'local_whisper';
    } catch (e) {
      Logger.warning(
        'Failed to get recitation provider: $e',
        feature: 'Preferences',
      );
      return 'local_whisper';
    }
  }

  Future<void> setQiraatEdition(String edition) async {
    await PrefUtils.prefs.setString('qiraat_edition', edition);
  }

  String getQiraatEdition() {
    try {
      return PrefUtils.prefs.getString('qiraat_edition') ?? 'quran-uthmani';
    } catch (e) {
      Logger.warning(
        'Failed to get qiraat edition: $e',
        feature: 'Preferences',
      );
      return 'quran-uthmani';
    }
  }

  Future<void> setReciterId(int id) async {
    await PrefUtils.prefs.setInt('reciter_id', id);
  }

  int getReciterId() {
    try {
      return PrefUtils.prefs.getInt('reciter_id') ?? 7;
    } catch (e) {
      Logger.warning('Failed to get reciter id: $e', feature: 'Preferences');
      return 7;
    }
  }

  Future<void> setCustomAsrEndpoint(String url) async {
    await PrefUtils.prefs.setString('custom_asr_endpoint', url);
  }

  String getCustomAsrEndpoint() {
    try {
      return PrefUtils.prefs.getString('custom_asr_endpoint') ?? '';
    } catch (e) {
      Logger.warning(
        'Failed to get custom ASR endpoint: $e',
        feature: 'Preferences',
      );
      return '';
    }
  }

  Future<void> setWhisperModel(String model) async {
    await PrefUtils.prefs.setString('whisper_model', model);
  }

  String getWhisperModel() {
    try {
      return PrefUtils.prefs.getString('whisper_model') ?? 'base';
    } catch (e) {
      Logger.warning('Failed to get whisper model: $e', feature: 'Preferences');
      return 'base';
    }
  }

  Future<void> setQrcHafzLevel(int level) async {
    await PrefUtils.prefs.setInt('qrc_hafz_level', level);
  }

  int getQrcHafzLevel() {
    try {
      return PrefUtils.prefs.getInt('qrc_hafz_level') ?? 1;
    } catch (e) {
      Logger.warning(
        'Failed to get qrc hafz level: $e',
        feature: 'Preferences',
      );
      return 1;
    }
  }

  Future<void> setQrcTajweedLevel(int level) async {
    await PrefUtils.prefs.setInt('qrc_tajweed_level', level);
  }

  int getQrcTajweedLevel() {
    try {
      return PrefUtils.prefs.getInt('qrc_tajweed_level') ?? 3;
    } catch (e) {
      Logger.warning(
        'Failed to get qrc tajweed level: $e',
        feature: 'Preferences',
      );
      return 3;
    }
  }

  bool isAdaptiveQrc() {
    try {
      return PrefUtils.prefs.getBool('adaptive_qrc') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setAdaptiveQrc(bool enabled) async {
    await PrefUtils.prefs.setBool('adaptive_qrc', enabled);
  }
}
