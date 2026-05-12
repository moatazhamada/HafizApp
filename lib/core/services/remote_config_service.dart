import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class RemoteConfigService {
  FirebaseRemoteConfig? _rc;

  FirebaseRemoteConfig get _remoteConfig {
    _rc ??= FirebaseRemoteConfig.instance;
    return _rc!;
  }

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults({
        'min_version_code': 0,
        'force_update_message': '',
      });
      await _remoteConfig.fetchAndActivate();
      Logger.info('Remote Config initialized', feature: 'RemoteConfig');
    } catch (e) {
      Logger.error('Remote Config init failed: $e', feature: 'RemoteConfig');
    }
  }

  int get minVersionCode {
    try {
      return _remoteConfig.getInt('min_version_code');
    } catch (_) {
      return 0;
    }
  }

  String get forceUpdateMessage {
    try {
      return _remoteConfig.getString('force_update_message');
    } catch (_) {
      return '';
    }
  }
}
