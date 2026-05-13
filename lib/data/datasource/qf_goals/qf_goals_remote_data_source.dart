import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/network/qf_api_interceptor.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Remote data source for QF Goals & Reading Sessions APIs.
///
/// Endpoints:
/// - POST /v1/goals                     → create a goal
/// - PUT  /v1/goals/{id}                → update a goal
/// - DELETE /v1/goals/{id}              → delete a goal
/// - GET  /v1/goals/get-todays-plan     → get today's plan
/// - GET  /v1/goals/estimate            → timeline estimation
/// - POST /v1/reading-sessions          → add/update reading session
/// - GET  /v1/reading-sessions          → get reading sessions
abstract class QfGoalsRemoteDataSource {
  // Goals
  Future<Map<String, dynamic>?> createGoal({
    required String type,
    required dynamic amount,
    required String category,
    int? duration,
    int? mushafId,
  });
  Future<void> updateGoal(
    String id, {
    String? type,
    dynamic amount,
    String? category,
    int? duration,
    int? mushafId,
  });
  Future<void> deleteGoal(String id, {String? category});
  Future<Map<String, dynamic>?> getTodaysPlan({String? type});
  Future<Map<String, dynamic>?> estimateGoal({
    required String type,
    required dynamic amount,
    int? duration,
    int? mushafId,
  });

  // Reading Sessions
  Future<void> postReadingSession({
    required int chapterNumber,
    required int verseNumber,
    int? startVerse,
    int? endVerse,
    int? duration,
    DateTime? readAt,
  });
  Future<List<Map<String, dynamic>>> getReadingSessions({int? first});
}

class QfGoalsRemoteDataSourceImpl implements QfGoalsRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfGoalsRemoteDataSourceImpl({required Dio dio, QfApiConfig? config})
    : _dio = dio,
      _config = config ?? const QfApiConfig();

  String get _baseUrl => '${_config.apiBaseUrl}/auth/v1';

  Options get _tzOptions =>
      Options(headers: {'x-timezone': DateTime.now().timeZoneName});

  @override
  Future<Map<String, dynamic>?> createGoal({
    required String type,
    required dynamic amount,
    required String category,
    int? duration,
    int? mushafId,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
        'amount': amount,
        'category': category,
      };
      if (duration != null) body['duration'] = duration;

      final query = <String, dynamic>{};
      if (mushafId != null) query['mushafId'] = mushafId;

      final response = await _dio.post(
        '$_baseUrl/goals',
        data: body,
        queryParameters: query,
        options: _tzOptions,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        Logger.info('Created QF goal', feature: 'QfGoals');
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      Logger.warning('Failed to create QF goal: $e', feature: 'QfGoals');
      return null;
    }
  }

  @override
  Future<void> updateGoal(
    String id, {
    String? type,
    dynamic amount,
    String? category,
    int? duration,
    int? mushafId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (type != null) body['type'] = type;
      if (amount != null) body['amount'] = amount;
      if (category != null) body['category'] = category;
      if (duration != null) body['duration'] = duration;

      final query = <String, dynamic>{};
      if (mushafId != null) query['mushafId'] = mushafId;

      await _dio.put(
        '$_baseUrl/goals/$id',
        data: body,
        queryParameters: query,
        options: _tzOptions,
      );
      Logger.info('Updated QF goal $id', feature: 'QfGoals');
    } catch (e) {
      Logger.warning('Failed to update QF goal: $e', feature: 'QfGoals');
    }
  }

  @override
  Future<void> deleteGoal(String id, {String? category}) async {
    try {
      final query = <String, dynamic>{};
      if (category != null) query['category'] = category;

      await _dio.delete(
        '$_baseUrl/goals/$id',
        queryParameters: query,
        options: _tzOptions,
      );
      Logger.info('Deleted QF goal $id', feature: 'QfGoals');
    } catch (e) {
      Logger.warning('Failed to delete QF goal: $e', feature: 'QfGoals');
    }
  }

  @override
  Future<Map<String, dynamic>?> getTodaysPlan({String? type}) async {
    try {
      final query = <String, dynamic>{};
      if (type != null) query['type'] = type;

      final response = await _dio.get(
        '$_baseUrl/goals/get-todays-plan',
        queryParameters: query,
        options: _tzOptions,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } on QfInsufficientScopeException {
      Logger.warning(
        'Insufficient scope for today\'s plan',
        feature: 'QfGoals',
      );
      throw InsufficientScopeFailure();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        Logger.warning(
          'Auth error fetching today\'s plan: $statusCode',
          feature: 'QfGoals',
        );
      } else {
        Logger.warning('Failed to get QF todays plan: $e', feature: 'QfGoals');
      }
      rethrow;
    } catch (e) {
      Logger.warning('Failed to get QF todays plan: $e', feature: 'QfGoals');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> estimateGoal({
    required String type,
    required dynamic amount,
    int? duration,
    int? mushafId,
  }) async {
    try {
      final query = <String, dynamic>{
        'type': type,
        'amount': amount.toString(),
      };
      if (duration != null) query['duration'] = duration;
      if (mushafId != null) query['mushafId'] = mushafId;

      final response = await _dio.get(
        '$_baseUrl/goals/estimate',
        queryParameters: query,
        options: _tzOptions,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      Logger.warning('Failed to estimate QF goal: $e', feature: 'QfGoals');
      return null;
    }
  }

  @override
  Future<void> postReadingSession({
    required int chapterNumber,
    required int verseNumber,
    int? startVerse,
    int? endVerse,
    int? duration,
    DateTime? readAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'chapterNumber': chapterNumber,
        'verseNumber': verseNumber,
      };
      if (startVerse != null) body['startVerse'] = startVerse;
      if (endVerse != null) body['endVerse'] = endVerse;
      if (duration != null) body['duration'] = duration;
      if (readAt != null) body['readAt'] = readAt.toIso8601String();

      await _dio.post(
        '$_baseUrl/reading-sessions',
        data: body,
      );
      Logger.info(
        'Posted reading session $chapterNumber:$verseNumber to QF',
        feature: 'QfGoals',
      );
    } catch (e) {
      Logger.warning(
        'Failed to post QF reading session: $e',
        feature: 'QfGoals',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getReadingSessions({int? first}) async {
    try {
      final query = <String, dynamic>{};
      if (first != null) query['first'] = first;

      final response = await _dio.get(
        '$_baseUrl/reading-sessions',
        queryParameters: query,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Logger.warning(
        'Failed to get QF reading sessions: $e',
        feature: 'QfGoals',
      );
      return [];
    }
  }
}
