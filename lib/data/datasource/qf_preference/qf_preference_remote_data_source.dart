import 'package:dio/dio.dart';
import '../../../core/config/qf_api_config.dart';
import '../../../core/utils/logger.dart';

/// Remote data source for Quran.Foundation Preference API.
///
/// Endpoints:
/// - GET  /auth/v1/preferences          → list all user preferences
/// - POST /auth/v1/preferences          → add/update a single preference
///
/// Query param `mushafId` is required for POST.
class QfPreferenceRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfPreferenceRemoteDataSource({
    required Dio dio,
    QfApiConfig? config,
  })  : _dio = dio,
        _config = config ?? const QfApiConfig();

  String get _baseUrl => '${_config.apiBaseUrl}/auth/v1';

  /// Fetch all user preferences from QF.
  ///
  /// Returns nested groups: { theme: { type: 'auto' }, language: { language: 'en' }, ... }
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _dio.get('$_baseUrl/preferences');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) return data;
      }
      return {};
    } catch (e) {
      Logger.warning('Failed to get QF preferences: $e',
          feature: 'QfPreference');
      return {};
    }
  }

  /// Set a single preference on QF.
  ///
  /// [group] — preference group (e.g. 'theme', 'language', 'quranReaderStyles')
  /// [key]   — preference key within the group (e.g. 'type', 'language', 'quranFont')
  /// [value] — the value to set
  /// [mushafId] — required query param, defaults to 1 (QCFV2)
  Future<bool> setPreference({
    required String group,
    required String key,
    required dynamic value,
    int mushafId = 1,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/preferences',
        queryParameters: {'mushafId': mushafId},
        data: {
          'group': group,
          'key': key,
          'value': value,
        },
      );
      Logger.info('Set QF preference: $group.$key = $value',
          feature: 'QfPreference');
      return true;
    } catch (e) {
      Logger.warning('Failed to set QF preference $group.$key: $e',
          feature: 'QfPreference');
      return false;
    }
  }
}
