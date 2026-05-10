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

  // Derive environment from the flavor dart-define (set automatically by
  // Flutter's --flavor flag).  This is the single source of truth — no
  // separate QF_PRODUCTION flag needed.
  static const String _flavor = String.fromEnvironment(
    'flavor',
    defaultValue: 'production',
  );
  static const bool defaultIsProduction = _flavor != 'prelive';

  // Redirect URI must match the app-auth scheme registered in
  // AndroidManifest / Info.plist.  The prelive flavor uses a separate scheme
  // so both builds can coexist on the same device.
  static const String redirectUri = defaultIsProduction
      ? 'hafizapp://oauth/callback'
      : 'hafizapp-prelive://oauth/callback';

  static const List<String> scopes = [
    'openid',
    'offline_access',
    'user',
    'collection',
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
}

class QfApiConfigResolver {
  static const QfApiConfig _default = QfApiConfig();
  static const QfApiConfig _prelive = QfApiConfig(isProduction: false);

  static QfApiConfig resolve() =>
      QfApiConfig.defaultIsProduction ? _default : _prelive;
}
