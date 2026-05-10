import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _rc.setDefaults({
        'min_version_code': 0,
        'force_update_message': '',
      });
      await _rc.fetchAndActivate();
      Logger.info('Remote Config initialized', feature: 'RemoteConfig');
    } catch (e) {
      Logger.error('Remote Config init failed: $e', feature: 'RemoteConfig');
    }
  }

  int get minVersionCode => _rc.getInt('min_version_code');
  String get forceUpdateMessage => _rc.getString('force_update_message');
}
