import 'package:dio/dio.dart';

import '../utils/logger.dart';

/// Interceptor that retries failed requests with exponential backoff.
///
/// Retries up to 3 times with delays of 1s, 2s, and 4s for retryable errors:
/// - [DioExceptionType.connectionTimeout]
/// - [DioExceptionType.receiveTimeout]
/// - [DioExceptionType.connectionError]
/// - HTTP 429 (Too Many Requests)
/// - HTTP 502, 503, 504 (Gateway/Service errors)
class RetryInterceptor extends Interceptor {
  final Dio _dio;

  RetryInterceptor(this._dio);

  static const int _maxRetries = 3;
  static const List<int> _backoffDelaysMs = [1000, 2000, 4000];

  bool _isRetryable(DioException err) {
    // Never retry cancelled requests.
    if (err.type == DioExceptionType.cancel) {
      return false;
    }

    // Retry on network-level timeouts and connection errors.
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on specific HTTP status codes.
    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      return statusCode == 429 ||
          statusCode == 502 ||
          statusCode == 503 ||
          statusCode == 504;
    }

    return false;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final attempt = (extra['_retryAttempt'] as int?) ?? 0;

    if (!_isRetryable(err) || attempt >= _maxRetries) {
      return super.onError(err, handler);
    }

    final nextAttempt = attempt + 1;
    final delayMs = _backoffDelaysMs[attempt];

    Logger.warning(
      'Retrying request to ${err.requestOptions.uri.path} '
      '(attempt $nextAttempt/$_maxRetries) after ${delayMs}ms',
      feature: 'RetryInterceptor',
    );

    await Future.delayed(Duration(milliseconds: delayMs));

    final options = err.requestOptions;
    options.extra['_retryAttempt'] = nextAttempt;

    try {
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return super.onError(retryErr, handler);
    } catch (e) {
      return super.onError(err, handler);
    }
  }
}
