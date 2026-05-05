class QfApiConfig {
  static const String preliveAuthBaseUrl =
      'https://prelive-oauth2.quran.foundation';
  static const String preliveApiBaseUrl =
      'https://apis-prelive.quran.foundation';

  static const String productionAuthBaseUrl = 'https://oauth2.quran.foundation';
  static const String productionApiBaseUrl = 'https://apis.quran.foundation';

  static const String clientId = String.fromEnvironment(
    'QF_CLIENT_ID',
    defaultValue: '',
  );
  static const String clientSecret = String.fromEnvironment(
    'QF_CLIENT_SECRET',
    defaultValue: '',
  );

  static const String redirectUri = 'hafizapp://oauth/callback';

  static const List<String> scopes = [
    'openid',
    'offline_access',
    'user',
    'collection',
  ];

  static const bool defaultIsProduction = bool.fromEnvironment(
    'QF_PRODUCTION',
    defaultValue: true,
  );

  final bool isProduction;

  const QfApiConfig({bool? isProduction})
      : isProduction = isProduction ?? defaultIsProduction;

  String get authBaseUrl =>
      isProduction ? productionAuthBaseUrl : preliveAuthBaseUrl;
  String get apiBaseUrl =>
      isProduction ? productionApiBaseUrl : preliveApiBaseUrl;

  String get authorizationEndpoint => '$authBaseUrl/oauth2/auth';
  String get tokenEndpoint => '$authBaseUrl/oauth2/token';
}

class QfApiConfigResolver {
  static const QfApiConfig _default = QfApiConfig();
  static const QfApiConfig _prelive = QfApiConfig(isProduction: false);

  static QfApiConfig resolve() =>
      QfApiConfig.defaultIsProduction ? _default : _prelive;
}
