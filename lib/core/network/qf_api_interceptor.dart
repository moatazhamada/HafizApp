import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfInsufficientScopeException extends DioException {
  final String path;

  // ignore: use_super_parameters
  QfInsufficientScopeException({
    required RequestOptions requestOptions,
    required this.path,
    DioException? cause,
  }) : super(
          requestOptions: requestOptions,
          response: cause?.response,
          type: cause?.type ?? DioExceptionType.badResponse,
          message: cause?.message,
          error: cause?.error,
        );

  @override
  String toString() => 'QfInsufficientScopeException: '
      'Token lacks required scopes for $path. Re-login required.';
}

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
        (path.contains('/auth/') ||
            path.contains('/api/') ||
            path.contains('/content/'))) {
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
    final statusCode = err.response?.statusCode;

    if (statusCode == 401 && _isUserApiRequest(err.requestOptions)) {
      // Expired/invalid token — refresh and retry once.
      await _handleAuthError(err, handler);
      return;
    }

    if (statusCode == 403 && _isUserApiRequest(err.requestOptions)) {
      // 403 could be expired token OR insufficient_scope.
      // insufficient_scope means the token is valid but missing permissions
      // — refreshing won't help, user must re-login to grant new scopes.
      if (_isInsufficientScope(err)) {
        Logger.warning(
          'Token lacks required scopes for ${err.requestOptions.uri.path}. '
          'User must re-login to grant updated permissions.',
          feature: 'QfApiInterceptor',
        );
        final wrapped = QfInsufficientScopeException(
          requestOptions: err.requestOptions,
          path: err.requestOptions.uri.path,
          cause: err,
        );
        return super.onError(wrapped, handler);
      }

      // Otherwise treat as stale token — refresh and retry once.
      await _handleAuthError(err, handler);
      return;
    }

    return super.onError(err, handler);
  }

  Future<void> _handleAuthError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Prevent recursive retries: if this request is itself a retry from a
    // previous interceptor pass, don't attempt another refresh + retry cycle.
    if (err.requestOptions.extra['_retried'] == true) {
      return super.onError(err, handler);
    }

    try {
      final newToken = await _refreshOrQueue();

      if (newToken != null && newToken.isNotEmpty) {
        final options = err.requestOptions;
        options.headers['x-auth-token'] = newToken;
        options.extra['_retried'] = true;

        final response = await _dio.fetch(options);
        return handler.resolve(response);
      } else {
        Logger.warning(
          'Token refresh returned null; user may need to re-login',
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

  /// Check if the 403 is due to insufficient OAuth2 scopes.
  bool _isInsufficientScope(DioException err) {
    try {
      var data = err.response?.data;

      // Dio may leave the body as a raw String instead of parsing JSON.
      if (data is String) {
        data = jsonDecode(data);
      }

      if (data is Map<String, dynamic>) {
        final type = data['type']?.toString().toLowerCase() ?? '';
        final message = data['message']?.toString().toLowerCase() ?? '';
        return type == 'insufficient_scope' ||
            message.contains('required scopes') ||
            message.contains('insufficient scope');
      }
    } catch (e) {
      Logger.warning('Insufficient scope check failed: \$e', feature: 'Auth');
    }
    return false;
  }

  /// Refreshes the token or waits for an in-flight refresh to complete.
  Future<String?> _refreshOrQueue() async {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      Logger.info(
        'Auth error from QF API, attempting to refresh token',
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
      _refreshCompleter = null;
      rethrow;
    }
  }
}
