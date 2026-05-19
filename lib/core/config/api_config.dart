import 'package:hafiz_app/core/i18n/locale_controller.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class ApiConfig {
  // Whether to prefer Quran.Foundation content endpoints.
  static const bool useQfContent = bool.fromEnvironment(
    'QF_USE_CONTENT',
    defaultValue: true,
  );

  /// Returns the active content API base URL based on [useQfContent].
  static String get contentBase =>
      useQfContent ? qfContentBase : quranComBase;

  // Detect whether this is a production build from the flavor name.
  // Flutter passes --dart-define=flavor=<name> automatically when --flavor is used.
  // Prelive flavor → not production; everything else → production.
  static const String _flavor = String.fromEnvironment(
    'flavor',
    defaultValue: 'production',
  );
  static const bool _isProduction = _flavor != 'prelive';
  static const String oauthBase = _isProduction
      ? 'https://oauth2.quran.foundation'
      : 'https://prelive-oauth2.quran.foundation';

  // Machine-to-machine client credentials for Content API (client_credentials flow).
  // Prefer explicit content credentials; fall back to PKCE credentials if not set.
  static const String clientId = String.fromEnvironment(
    'QF_CONTENT_CLIENT_ID',
    defaultValue: String.fromEnvironment('QF_CLIENT_ID', defaultValue: ''),
  );
  static const String clientSecret = String.fromEnvironment(
    'QF_CONTENT_CLIENT_SECRET',
    defaultValue: String.fromEnvironment('QF_CLIENT_SECRET', defaultValue: ''),
  );

  // Optional audience/scope if required in the future
  static const String scope = String.fromEnvironment(
    'QF_SCOPE',
    defaultValue: '',
  );

  // Content API base (if using Quran.Foundation content APIs)
  static const String qfContentBase = String.fromEnvironment(
    'QF_CONTENT_BASE',
    defaultValue: 'https://apis.quran.foundation',
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
  static const String qrcApiKey = String.fromEnvironment(
    'QRC_API_KEY',
    defaultValue: '',
  );

  // --- Runtime locale-aware resource IDs ---

  static bool get _isArabic {
    try {
      return LocaleController.notifier.value.languageCode == 'ar';
    } catch (e) {
      Logger.warning('Failed to detect Arabic locale: $e', feature: 'ApiConfig');
      return false;
    }
  }

  /// Tafsir resource ID based on current locale.
  /// Arabic → 91 (Al-Sa'di), English → 169 (Ibn Kathir English).
  static String get tafsirId => _isArabic ? '91' : '169';

  /// Translation resource ID (English only — skipped when locale is Arabic).
  /// 85 = The Clear Quran by Dr. Mustafa Khattab.
  static const int translationId = 85;

  /// Quran.Foundation Search API base URL.
  static const String qfSearchBase = String.fromEnvironment(
    'QF_SEARCH_BASE',
    defaultValue: 'https://apis.quran.foundation',
  );
}
