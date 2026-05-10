class QfApiConfig {
  static const String preliveAuthBaseUrl =
      'https://prelive-oauth2.quran.foundation';
  static const String preliveApiBaseUrl =
      'https://apis-prelive.quran.foundation';

  static const String productionAuthBaseUrl = 'https://oauth2.quran.foundation';
  static const String productionApiBaseUrl = 'https://apis.quran.foundation';

  // Derive environment from the flavor dart-define (set automatically by
  // Flutter's --flavor flag).  This is the single source of truth — no
  // separate QF_PRODUCTION flag needed.
  static const String _flavor = String.fromEnvironment(
    'flavor',
    defaultValue: 'production',
  );
  static const bool defaultIsProduction = _flavor != 'prelive';

  // Production credentials come from --dart-define at build time.
  // Prelive uses hardcoded test credentials provided by QF.
  static const String clientId = defaultIsProduction
      ? String.fromEnvironment('QF_CLIENT_ID', defaultValue: '')
      : '5cd47ccf-93e5-47d0-83b5-9bf538bb5759';
  static const String clientSecret = defaultIsProduction
      ? String.fromEnvironment('QF_CLIENT_SECRET', defaultValue: '')
      : String.fromEnvironment('QF_CLIENT_SECRET',
          defaultValue: 'pd9aPG1ieJL2.34Qi-LV6E8FBG');

  // Redirect URI must match the app-auth scheme registered in
  // AndroidManifest / Info.plist.  The prelive flavor uses a separate scheme
  // so both builds can coexist on the same device.
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
