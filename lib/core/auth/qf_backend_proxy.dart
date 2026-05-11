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

  QfDioBackendTokenProxy({
    required Dio dio,
    required QfOidcConfig config,
  }) : _dio = dio,
       _config = config;

  String get _backendExchangeUrl {
    return '${_config.endpoints.apiBaseUrl}/auth/v1/token/exchange';
  }

  @override
  Future<QfBackendTokenExchangeResult> exchangeCodeForTokens({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    try {
      Logger.info(
        'Exchanging authorization code via backend proxy',
        feature: 'QfBackendProxy',
      );

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
    } on DioException catch (e) {
      Logger.error(
        'Backend token exchange network error: ${e.message}',
        feature: 'QfBackendProxy',
      );
      throw QfBackendTokenExchangeException(
        statusCode: e.response?.statusCode ?? 0,
        body: e.response?.data?.toString() ?? e.message ?? 'Network error',
      );
    }
  }

  @override
  Future<QfBackendTokenExchangeResult> refreshAccessToken({
    required String refreshToken,
  }) async {
    try {
      Logger.info(
        'Refreshing access token via backend proxy',
        feature: 'QfBackendProxy',
      );

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
    } on DioException catch (e) {
      throw QfBackendTokenExchangeException(
        statusCode: e.response?.statusCode ?? 0,
        body: e.response?.data?.toString() ?? e.message ?? 'Network error',
      );
    }
  }
}
