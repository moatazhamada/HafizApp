class QfApiConfig {
  static const String preliveAuthBaseUrl =
      'https://prelive-oauth2.quran.foundation';
  static const String preliveApiBaseUrl =
      'https://apis-prelive.quran.foundation';

  static const String productionAuthBaseUrl = 'https://oauth2.quran.foundation';
  static const String productionApiBaseUrl = 'https://apis.quran.foundation';

  static const String clientId = String.fromEnvironment(
    'QF_CLIENT_ID',
    defaultValue: '5cd47ccf-93e5-47d0-83b5-9bf538bb5759',
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

  final bool isProduction;

  const QfApiConfig({this.isProduction = false});

  String get authBaseUrl =>
      isProduction ? productionAuthBaseUrl : preliveAuthBaseUrl;
  String get apiBaseUrl =>
      isProduction ? productionApiBaseUrl : preliveApiBaseUrl;

  String get authorizationEndpoint => '$authBaseUrl/oauth2/auth';
  String get tokenEndpoint => '$authBaseUrl/oauth2/token';
}
