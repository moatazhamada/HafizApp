import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/navigator_service.dart';
import 'ar_eg/ar_eg_translations.dart';
import 'en_us/en_us_translations.dart';

class AppLocalization {
  AppLocalization(this.locale);

  Locale locale;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': enUs,
    'ar': arEg,
  };

  static bool _validatedKeys = false;

  static void _validateKeys() {
    if (_validatedKeys) return;
    _validatedKeys = true;
    final enKeys = _localizedValues['en']?.keys.toSet() ?? {};
    final arKeys = _localizedValues['ar']?.keys.toSet() ?? {};
    final missingInAr = enKeys.difference(arKeys).toList()..sort();
    final missingInEn = arKeys.difference(enKeys).toList()..sort();

    if (missingInAr.isNotEmpty || missingInEn.isNotEmpty) {
      debugPrint(
        'Localization mismatch - missing in ar: ${missingInAr.join(', ')}, missing in en: ${missingInEn.join(', ')}',
      );
    }
  }

  static AppLocalization of() {
    return Localizations.of<AppLocalization>(
      NavigatorService.navigatorKey.currentContext!,
      AppLocalization,
    )!;
  }

  static List<String> languages() => _localizedValues.keys.toList();

  String getString(String text) =>
      _localizedValues[locale.languageCode]![text] ?? text;

  void setLocale(Locale newLocale) {
    locale = newLocale;
  }

  Locale getCurrentLocale() {
    return locale;
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalization.languages().contains(locale.languageCode);

  //Returning a SynchronousFuture here because an async "load" operation
  //cause an async "load" operation
  @override
  Future<AppLocalization> load(Locale locale) {
    AppLocalization._validateKeys();
    return SynchronousFuture<AppLocalization>(AppLocalization(locale));
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

extension LocalizationExtension on String {
  String get tr => AppLocalization.of().getString(this);
}
