import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfApiInterceptor extends Interceptor {
  final QfAuthRemoteDataSource _authDataSource;
  final Dio _dio;
  bool _isRefreshing = false;

  QfApiInterceptor(this._authDataSource, this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Only inject headers if this request is going to the QF APIs
    final isQfApiRequest = options.uri.toString().contains('quran.foundation');

    if (isQfApiRequest) {
      final accessToken = await _authDataSource.getAccessToken();

      options.headers['x-client-id'] = QfApiConfig.clientId;

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['x-auth-token'] = accessToken;
      }
    }

    return super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.uri.toString().contains('quran.foundation')) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        Logger.info('Received 401 from QF API, attempting to refresh token',
            feature: 'QfApiInterceptor');

        try {
          final isRefreshed = await _authDataSource.refreshToken();

          if (isRefreshed) {
            final newAccessToken = await _authDataSource.getAccessToken();

            // Update the original request with the new token
            final options = err.requestOptions;
            options.headers['x-auth-token'] = newAccessToken;

            // Retry the request
            final response = await _dio.fetch(options);
            _isRefreshing = false;
            return handler.resolve(response);
          } else {
            // Refresh failed, token might be revoked or expired
            Logger.warning('Token refresh failed during interceptor retry',
                feature: 'QfApiInterceptor');
            _isRefreshing = false;
            return super.onError(err, handler);
          }
        } catch (e) {
          Logger.error('Error during token refresh in interceptor: $e',
              feature: 'QfApiInterceptor');
          _isRefreshing = false;
          return super.onError(err, handler);
        }
      } else {
        // If already refreshing, you might want to enqueue requests,
        // but for simplicity we'll just fail this one or wait.
        // A more complex implementation uses a queue or Completer.
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }
}
