import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfAuthService {
  final Dio _dio; // a lightweight Dio for token calls

  String? _accessToken;
  DateTime? _expiresAt;
  bool _refreshing = false;
  Completer<void>? _refreshCompleter;

  QfAuthService([Dio? dio]) : _dio = dio ?? Dio();

  bool get hasValidToken {
    if (_accessToken == null) return false;
    final now = DateTime.now().toUtc();
    // Refresh a bit before expiry to avoid race
    return _expiresAt != null &&
        now.isBefore(_expiresAt!.subtract(const Duration(seconds: 30)));
  }

  String? get accessToken => _accessToken;

  Future<void> ensureToken() async {
    if (hasValidToken) return;
    await _refreshToken();
  }

  Future<void> _refreshToken() async {
    if (_refreshing) {
      // Coalesce concurrent refreshes
      await (_refreshCompleter?.future);
      return;
    }
    _refreshing = true;
    _refreshCompleter = Completer<void>();
    try {
      final tokenUrl = '${ApiConfig.oauthBase}/oauth2/token';
      final authHeader =
          'Basic ${base64Encode(utf8.encode('${ApiConfig.clientId}:${ApiConfig.clientSecret}'))}';
      final resp = await _dio.post(
        tokenUrl,
        data: 'grant_type=client_credentials&scope=content',
        options: Options(
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode == 200) {
        final data = resp.data is Map
            ? Map<String, dynamic>.from(resp.data)
            : json.decode(resp.data as String);
        _accessToken = data['access_token'] as String?;
        final int expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
        _expiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
      } else {
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          type: DioExceptionType.badResponse,
          error: 'OAuth token request failed: ${resp.statusCode}',
        );
      }
    } finally {
      _refreshing = false;
      _refreshCompleter?.complete();
    }
  }
}

class QfAuthInterceptor extends Interceptor {
  final QfAuthService auth;

  QfAuthInterceptor(this.auth);

  /// Only match machine-to-machine OAuth token endpoint and content API paths.
  bool _shouldInjectToken(RequestOptions options) {
    final host = options.uri.host.toLowerCase();
    final path = options.uri.path.toLowerCase();

    // Machine-to-machine OAuth token endpoint (production + prelive)
    if ((host.contains('oauth2.quran.foundation') ||
            host.contains('prelive-oauth2.quran.foundation')) &&
        path.contains('/token')) {
      return true;
    }

    // Content API paths (production, prelive, or api.quran.com)
    if ((host.contains('apis.quran.foundation') ||
            host.contains('api.quran.foundation') ||
            host.contains('apis-prelive.quran.foundation') ||
            host.contains('api.quran.com')) &&
        path.contains('/content/')) {
      return true;
    }

    return false;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldInjectToken(options)) {
      try {
        await auth.ensureToken();
        final token = auth.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['x-auth-token'] = token;
        }
        if (ApiConfig.clientId.isNotEmpty) {
          options.headers['x-client-id'] = ApiConfig.clientId;
        }
      } catch (e) {
        Logger.warning('QF auth token injection failed: $e', feature: 'Auth');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        _shouldInjectToken(err.requestOptions)) {
      try {
        await auth.ensureToken();
        final token = auth.accessToken;
        if (token != null && token.isNotEmpty) {
          final clone = await _retryWithToken(err.requestOptions, token);
          return handler.resolve(clone);
        }
      } catch (e) {
        Logger.warning('QF auth 401 retry failed: $e', feature: 'Auth');
      }
    }
    super.onError(err, handler);
  }

  Future<Response<dynamic>> _retryWithToken(
    RequestOptions requestOptions,
    String token,
  ) async {
    final dio = Dio();
    // Copy base options
    dio.options = BaseOptions(
      baseUrl: requestOptions.baseUrl,
      connectTimeout: requestOptions.connectTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      validateStatus: (_) => true,
    );
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['x-auth-token'] = token;
    if (ApiConfig.clientId.isNotEmpty) {
      headers['x-client-id'] = ApiConfig.clientId;
    }
    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        listFormat: requestOptions.listFormat,
      ),
    );
  }
}
