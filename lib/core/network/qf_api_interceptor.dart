import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfApiInterceptor extends Interceptor {
  final QfAuthRemoteDataSource _authDataSource;
  final Dio _dio;

  /// Completer used to coalesce concurrent 401-triggered refreshes.
  Completer<String?>? _refreshCompleter;

  QfApiInterceptor(this._authDataSource, this._dio);

  /// Match user-facing API requests that need x-auth-token headers.
  /// Content paths (/content/) are included as a fallback so that logged-in
  /// users can still fetch translations/tafsir when machine credentials
  /// (QfAuthInterceptor) are not available.
  bool _isUserApiRequest(RequestOptions options) {
    final host = options.uri.host.toLowerCase();
    final path = options.uri.path.toLowerCase();

    if (host.contains('quran.foundation') &&
        (path.contains('/auth/') || path.contains('/api/') || path.contains('/content/'))) {
      return true;
    }

    return false;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isUserApiRequest(options)) {
      final accessToken = await _authDataSource.getAccessToken();

      if (QfApiConfig.clientId.isNotEmpty) {
        options.headers['x-client-id'] = QfApiConfig.clientId;
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['x-auth-token'] = accessToken;
      }
    }

    return super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        _isUserApiRequest(err.requestOptions)) {
      try {
        final newToken = await _refreshOrQueue();

        if (newToken != null && newToken.isNotEmpty) {
          // Update the original request with the new token
          final options = err.requestOptions;
          options.headers['x-auth-token'] = newToken;

          // Retry the request
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } else {
          // Refresh failed, token might be revoked or expired
          Logger.warning(
            'Token refresh returned null during interceptor retry',
            feature: 'QfApiInterceptor',
          );
          return super.onError(err, handler);
        }
      } catch (e) {
        Logger.error(
          'Error during token refresh in interceptor: $e',
          feature: 'QfApiInterceptor',
        );
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  /// Refreshes the token or waits for an in-flight refresh to complete.
  ///
  /// If a refresh is already underway ([_refreshCompleter] is active), this
  /// just awaits its result. Otherwise it kicks off a new refresh and
  /// populates the completer so subsequent callers can piggyback.
  Future<String?> _refreshOrQueue() async {
    // If a refresh is already in progress, wait for it.
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    // Start a new refresh.
    _refreshCompleter = Completer<String?>();

    try {
      Logger.info(
        'Received 401 from QF API, attempting to refresh token',
        feature: 'QfApiInterceptor',
      );

      final isRefreshed = await _authDataSource.refreshToken();
      String? newToken;
      if (isRefreshed) {
        newToken = await _authDataSource.getAccessToken();
      }

      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      // Reset so the next attempt can retry
      _refreshCompleter = null;
      rethrow;
    }
  }
}
