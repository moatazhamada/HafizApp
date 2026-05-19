import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/timezone_helper.dart';

/// Remote data source for QF Streaks & Activity Days APIs.
///
/// Endpoints:
/// - GET  /v1/streaks                        → list streaks
/// - GET  /v1/streaks/current-streak-days    → current streak count
/// - POST /v1/activity-days                  → add/update activity day
/// - GET  /v1/activity-days                  → get activity days
/// - GET  /v1/activity-days/estimate-reading-time → estimate time
abstract class QfActivityRemoteDataSource {
  Future<int> getCurrentStreakDays({String type = 'QURAN'});
  Future<List<Map<String, dynamic>>> getStreaks({
    String? from,
    String? to,
    int? first,
  });
  Future<void> postActivityDay({
    required String type,
    String? date,
    int? seconds,
    List<String>? ranges,
    int? mushafId,
  });
  Future<List<Map<String, dynamic>>> getActivityDays({
    String? from,
    String? to,
    int? first,
  });
}

class QfActivityRemoteDataSourceImpl implements QfActivityRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfActivityRemoteDataSourceImpl({
    required Dio dio,
    QfApiConfig? config,
  })  : _dio = dio,
        _config = config ?? const QfApiConfig();

  String get _baseUrl => '${_config.apiBaseUrl}/auth/v1';

  @override
  Future<int> getCurrentStreakDays({String type = 'QURAN'}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/streaks/current-streak-days',
        queryParameters: {'type': type},
        options: await buildTzOptions(),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data']?['days'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      Logger.warning('Failed to get QF streak days: $e', feature: 'QfActivity');
      return 0;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStreaks({
    String? from,
    String? to,
    int? first,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (from != null) query['from'] = from;
      if (to != null) query['to'] = to;
      if (first != null) query['first'] = first;

      final response = await _dio.get(
        '$_baseUrl/streaks',
        queryParameters: query,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Logger.warning('Failed to get QF streaks: $e', feature: 'QfActivity');
      return [];
    }
  }

  @override
  Future<void> postActivityDay({
    required String type,
    String? date,
    int? seconds,
    List<String>? ranges,
    int? mushafId,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
      };
      if (date != null) body['date'] = date;
      if (seconds != null) body['seconds'] = seconds;
      if (ranges != null) body['ranges'] = ranges;
      if (mushafId != null) body['mushafId'] = mushafId;

      await _dio.post(
        '$_baseUrl/activity-days',
        data: body,
        options: await buildTzOptions(),
      );
      Logger.info('Posted activity day to QF', feature: 'QfActivity');
    } catch (e) {
      Logger.warning('Failed to post QF activity day: $e', feature: 'QfActivity');
      // Non-blocking: local functionality continues
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getActivityDays({
    String? from,
    String? to,
    int? first,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (from != null) query['from'] = from;
      if (to != null) query['to'] = to;
      if (first != null) query['first'] = first;

      final response = await _dio.get(
        '$_baseUrl/activity-days',
        queryParameters: query,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Logger.warning('Failed to get QF activity days: $e', feature: 'QfActivity');
      return [];
    }
  }
}
