import 'dart:math';

import 'package:dio/dio.dart';

import 'package:hafiz_app/core/auth/qf_oidc_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfBackendTokenExchangeResult {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final int expiresIn;
  final String scope;
  final String tokenType;

  const QfBackendTokenExchangeResult({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    required this.expiresIn,
    required this.scope,
    required this.tokenType,
  });

  factory QfBackendTokenExchangeResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return QfBackendTokenExchangeResult(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      scope: json['scope'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }
}

class QfBackendTokenExchangeException implements Exception {
  final int statusCode;
  final String body;

  const QfBackendTokenExchangeException({
    required this.statusCode,
    required this.body,
  });

  @override
  String toString() =>
      'QfBackendTokenExchangeException($statusCode): $body';
}

abstract class QfBackendTokenProxy {
  Future<QfBackendTokenExchangeResult> exchangeCodeForTokens({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  });

  Future<QfBackendTokenExchangeResult> refreshAccessToken({
    required String refreshToken,
  });
}

class QfNoopBackendTokenProxy implements QfBackendTokenProxy {
  @override
  Future<QfBackendTokenExchangeResult> exchangeCodeForTokens({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    throw UnimplementedError(
      'Backend token exchange is not configured. '
      'For confidential clients, the token exchange must happen on a backend '
      'server. Configure a QfBackendTokenProxy implementation and register it '
      'in the dependency injection container.',
    );
  }

  @override
  Future<QfBackendTokenExchangeResult> refreshAccessToken({
    required String refreshToken,
  }) async {
    throw UnimplementedError(
      'Backend token refresh is not configured. '
      'For confidential clients, token refresh must happen on a backend server.',
    );
  }
}

class QfDioBackendTokenProxy implements QfBackendTokenProxy {
  final Dio _dio;
  final QfOidcConfig _config;
  final Random _random = Random();

  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);
  static const int _jitterMs = 500;

  QfDioBackendTokenProxy({
    required Dio dio,
    required QfOidcConfig config,
  }) : _dio = dio,
       _config = config;

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    Exception? lastException;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          final jitter = _random.nextInt(_jitterMs);
          final delayMs = min(
            (_baseDelay.inMilliseconds * pow(2, attempt - 1)).toInt(),
            _maxDelay.inMilliseconds,
          );
          await Future.delayed(Duration(milliseconds: delayMs + jitter));
          Logger.info(
            'Backend proxy retry attempt $attempt',
            feature: 'QfBackendProxy',
          );
        }
        return await operation();
      } on QfBackendTokenExchangeException catch (e) {
        lastException = e;
        if (attempt >= _maxRetries) rethrow;
      } on DioException catch (e) {
        lastException = e;
        if (attempt >= _maxRetries) rethrow;
      }
    }
    throw lastException ?? const QfBackendTokenExchangeException(
      statusCode: 0,
      body: 'Unexpected retry exhaustion',
    );
  }

  String get _backendExchangeUrl {
    return '${_config.endpoints.apiBaseUrl}/auth/v1/token/exchange';
  }

  @override
  Future<QfBackendTokenExchangeResult> exchangeCodeForTokens({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    Logger.info(
      'Exchanging authorization code via backend proxy',
      feature: 'QfBackendProxy',
    );

    return _withRetry(() async {
      final response = await _dio.post(
        _backendExchangeUrl,
        data: {
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
        options: Options(
          headers: {'x-client-id': _config.clientId},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200) {
        return QfBackendTokenExchangeResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      Logger.error(
        'Backend token exchange failed: ${response.statusCode} '
        '${response.data}',
        feature: 'QfBackendProxy',
      );
      throw QfBackendTokenExchangeException(
        statusCode: response.statusCode ?? 0,
        body: response.data.toString(),
      );
    });
  }

  @override
  Future<QfBackendTokenExchangeResult> refreshAccessToken({
    required String refreshToken,
  }) async {
    Logger.info(
      'Refreshing access token via backend proxy',
      feature: 'QfBackendProxy',
    );

    return _withRetry(() async {
      final response = await _dio.post(
        _backendExchangeUrl,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {'x-client-id': _config.clientId},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200) {
        return QfBackendTokenExchangeResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw QfBackendTokenExchangeException(
        statusCode: response.statusCode ?? 0,
        body: response.data.toString(),
      );
    });
  }
}
