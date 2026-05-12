enum QfClientType {
  confidential,
  public,
}

class QfApiConfig {
  static const String preliveAuthBaseUrl =
      'https://prelive-oauth2.quran.foundation';
  static const String preliveApiBaseUrl =
      'https://apis-prelive.quran.foundation';

  static const String productionAuthBaseUrl = 'https://oauth2.quran.foundation';
  static const String productionApiBaseUrl = 'https://apis.quran.foundation';

  static const String _flavor = String.fromEnvironment(
    'flavor',
    defaultValue: 'production',
  );
  static const bool defaultIsProduction = _flavor != 'prelive';

  static const String clientId = defaultIsProduction
      ? String.fromEnvironment('QF_CLIENT_ID', defaultValue: '')
      : '5cd47ccf-93e5-47d0-83b5-9bf538bb5759';
  static const String clientSecret = defaultIsProduction
      ? String.fromEnvironment('QF_CLIENT_SECRET', defaultValue: '')
      : String.fromEnvironment('QF_CLIENT_SECRET',
          defaultValue: 'pd9aPG1ieJL2.34Qi-LV6E8FBG');

  /// When a backend proxy is configured, the app sends the authorization code
  /// to this URL for server-side token exchange.  This keeps the client_secret
  /// off the device.
  static const String backendExchangeUrl = String.fromEnvironment(
    'QF_BACKEND_EXCHANGE_URL',
    defaultValue: '',
  );

  /// When true, the app uses direct in-app token exchange without a backend.
  /// Only set to true if Quran Foundation explicitly confirmed this is a
  /// public client.  Defaults to false (confidential client) for safety.
  static const bool forcePublicClient = bool.fromEnvironment(
    'QF_PUBLIC_CLIENT',
    defaultValue: false,
  );

  /// Detected client type: confidential unless explicitly overridden.
  /// Confidential clients must use a backend proxy for token exchange.
  static QfClientType get clientType {
    if (forcePublicClient) return QfClientType.public;
    if (clientSecret.isNotEmpty || backendExchangeUrl.isNotEmpty) {
      return QfClientType.confidential;
    }
    return QfClientType.public;
  }

  static const String redirectUri = defaultIsProduction
      ? 'hafizapp://oauth/callback'
      : 'hafizapp-prelive://oauth/callback';

  static const String storedFlavorKey = 'qf_stored_flavor';
  static const String currentFlavor = _flavor;

  static bool get isProductionBuild => defaultIsProduction;

  static const List<String> scopes = [
    'openid',
    'offline_access',
    'user',
    'bookmark',
    'collection',
    'reading_session',
    'goal',
    'streak',
    'activity_day',
    'post',
    'preference',
    'content',
    'search',
  ];

  static const List<String> coreScopes = [
    'openid',
    'offline_access',
    'user',
  ];

  final bool isProduction;

  const QfApiConfig({bool? isProduction})
    : isProduction = isProduction ?? defaultIsProduction;

  String get authBaseUrl =>
      isProduction ? productionAuthBaseUrl : preliveAuthBaseUrl;
  String get apiBaseUrl =>
      isProduction ? productionApiBaseUrl : preliveApiBaseUrl;

  String get authorizationEndpoint => '$authBaseUrl/oauth2/auth';
  String get tokenEndpoint => '$authBaseUrl/oauth2/token';

  String get discoveryUrl =>
      '$authBaseUrl/.well-known/openid-configuration';

  String get revocationEndpoint => '$authBaseUrl/oauth2/revoke';

  String get logoutEndpoint =>
      '$authBaseUrl/oauth2/sessions/logout';
}

class QfApiConfigResolver {
  static const QfApiConfig _default = QfApiConfig();
  static const QfApiConfig _prelive = QfApiConfig(isProduction: false);

  static QfApiConfig resolve() =>
      QfApiConfig.defaultIsProduction ? _default : _prelive;
}
