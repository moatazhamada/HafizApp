import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

enum QfOAuthClientType {
  confidential,
  public,
}

class QfOidcEndpoints {
  final String authBaseUrl;
  final String apiBaseUrl;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String revocationEndpoint;
  final String logoutEndpoint;
  final String discoveryUrl;
  final String userInfoEndpoint;

  const QfOidcEndpoints({
    required this.authBaseUrl,
    required this.apiBaseUrl,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.revocationEndpoint,
    required this.logoutEndpoint,
    required this.discoveryUrl,
    required this.userInfoEndpoint,
  });

  factory QfOidcEndpoints.fromConfig(QfApiConfig config) {
    return QfOidcEndpoints(
      authBaseUrl: config.authBaseUrl,
      apiBaseUrl: config.apiBaseUrl,
      authorizationEndpoint: config.authorizationEndpoint,
      tokenEndpoint: config.tokenEndpoint,
      revocationEndpoint: '${config.authBaseUrl}/oauth2/revoke',
      logoutEndpoint: '${config.authBaseUrl}/oauth2/sessions/logout',
      discoveryUrl:
          '${config.authBaseUrl}/.well-known/openid-configuration',
      userInfoEndpoint: '${config.authBaseUrl}/userinfo',
    );
  }
}

class QfOidcConfig {
  final QfOAuthClientType clientType;
  final QfOidcEndpoints endpoints;
  final String clientId;
  final String? clientSecret;
  final String redirectUri;
  final bool isProduction;
  final List<String> scopes;

  const QfOidcConfig({
    required this.clientType,
    required this.endpoints,
    required this.clientId,
    this.clientSecret,
    required this.redirectUri,
    required this.isProduction,
    required this.scopes,
  });

  factory QfOidcConfig.fromQfApiConfig(QfApiConfig config) {
    final endpoints = QfOidcEndpoints.fromConfig(config);

    if (QfApiConfig.clientId.isEmpty) {
      throw StateError(
        'Missing Quran Foundation API credentials. '
        'Request access: https://api-docs.quran.foundation/request-access',
      );
    }

    final clientType = _detectClientType(
      hasSecret: QfApiConfig.clientSecret.isNotEmpty,
      isProduction: config.isProduction,
      hasBackendExchangeUrl: QfApiConfig.backendExchangeUrl.isNotEmpty,
    );

    return QfOidcConfig(
      clientType: clientType,
      endpoints: endpoints,
      clientId: QfApiConfig.clientId,
      clientSecret: QfApiConfig.clientSecret.isNotEmpty
          ? QfApiConfig.clientSecret
          : null,
      redirectUri: QfApiConfig.redirectUri,
      isProduction: config.isProduction,
      scopes: List.unmodifiable(QfApiConfig.scopes),
    );
  }

  static QfOAuthClientType _detectClientType({
    required bool hasSecret,
    required bool isProduction,
    required bool hasBackendExchangeUrl,
  }) {
    if (hasSecret || hasBackendExchangeUrl) {
      if (!isProduction && hasSecret) {
        Logger.warning(
          'Quran Foundation OAuth client has a client_secret — this is a '
          'confidential client. The client_secret should be kept on a backend '
          'server and NEVER embedded in a mobile app or browser app.',
          feature: 'QfOidcConfig',
        );
      }
      return QfOAuthClientType.confidential;
    } else {
      Logger.info(
        'Quran Foundation OAuth client has no client_secret — assuming '
        'public client. Only use direct in-app token exchange if QF has '
        'explicitly confirmed that this client is public.',
        feature: 'QfOidcConfig',
      );
      return QfOAuthClientType.public;
    }
  }

  bool get isConfidential => clientType == QfOAuthClientType.confidential;

  bool get isPublic => clientType == QfOAuthClientType.public;

  String get envLabel => isProduction ? 'production' : 'prelive';
}
