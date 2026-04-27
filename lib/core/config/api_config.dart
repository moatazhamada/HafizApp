class ApiConfig {
  // Whether to prefer Quran.Foundation content endpoints. Keep false to use existing Quran.com v4.
  static const bool useQfContent = bool.fromEnvironment('QF_USE_CONTENT', defaultValue: false);

  // OAuth2 issuer base (no trailing slash). Defaults to production.
  static const String oauthBase = String.fromEnvironment(
    'QF_OAUTH_BASE',
    defaultValue: 'https://oauth2.quran.foundation',
  );

  // Client credentials (DO NOT hardcode in source; pass via --dart-define)
  static const String clientId = String.fromEnvironment('QF_CLIENT_ID', defaultValue: '');
  static const String clientSecret = String.fromEnvironment('QF_CLIENT_SECRET', defaultValue: '');

  // Optional audience/scope if required in the future
  static const String scope = String.fromEnvironment('QF_SCOPE', defaultValue: '');

  // Content API base (if using Quran.Foundation content APIs)
  static const String qfContentBase = String.fromEnvironment(
    'QF_CONTENT_BASE',
    defaultValue: 'https://api.quran.foundation',
  );

  // Quran.com public API base (v4)
  static const String quranComBase = String.fromEnvironment(
    'QURAN_COM_BASE',
    defaultValue: 'https://api.quran.com/api/v4',
  );

  // QuranHub API base for qiraat/editions data
  static const String quranHubBase = String.fromEnvironment(
    'QURANHUB_BASE',
    defaultValue: 'https://api.quranhub.com/v1',
  );

  // Qurani.ai QRC WebSocket base + API key
  static const String qrcWsBase = String.fromEnvironment(
    'QRC_WS_BASE',
    defaultValue: 'wss://api.qurani.ai',
  );
  static const String qrcApiKey =
      String.fromEnvironment('QRC_API_KEY', defaultValue: '');
}
