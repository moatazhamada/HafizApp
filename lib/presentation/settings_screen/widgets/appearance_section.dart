import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/analytics/analytics_properties.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/i18n/locale_controller.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/injection_container.dart' as di;
import 'package:hafiz_app/presentation/settings_screen/widgets/settings_utils.dart';

class AppearanceSection extends StatefulWidget {
  const AppearanceSection({super.key});

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  late String _currentLang;
  late String _themeMode;
  late double _quranFontSize;

  @override
  void initState() {
    super.initState();
    _currentLang = PrefUtils().getLocaleCode();
    _themeMode = PrefUtils().getThemeMode();
    _quranFontSize = PrefUtils().getQuranFontSize();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: [
        _buildLanguageTile(),
        const Divider(height: 1),
        _buildThemeTile(),
        const Divider(height: 1),
        _buildFontSizeTile(),
      ],
    );
  }

  Widget _buildLanguageTile() {
    final label = _currentLang == 'system'
        ? 'lbl_system_default'.tr
        : _currentLang == 'ar'
            ? 'العربية'
            : 'English';
    return ListTile(
      title: Text('about_language_title'.tr),
      subtitle: Text(label),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        final value = await showSelectionSheet<String>(
          context: context,
          title: 'about_language_title'.tr,
          options: const [
            Option('system', 'lbl_system_default'),
            Option('en', 'English', isKey: false),
            Option('ar', 'العربية', isKey: false),
          ],
          selected: _currentLang,
        );
        if (value != null && value != _currentLang) {
          Locale newLocale;
          if (value == 'system') {
            final systemLoc = WidgetsBinding.instance.platformDispatcher.locale;
            newLocale = (systemLoc.languageCode == 'en')
                ? const Locale('en', 'US')
                : const Locale('ar', 'EG');
          } else {
            newLocale = Locale(value, value == 'en' ? 'US' : 'EG');
          }
          LocaleController.setLocale(newLocale);
          await PrefUtils().setLocaleCode(value);
          setState(() => _currentLang = value);
          unawaited(
            di.sl<AnalyticsService>().logLanguageChange(
              value == 'system'
                  ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
                  : value,
            ),
          );
          unawaited(
            di.sl<AnalyticsService>().setUserProperty(
              name: AnalyticsProperties.locale,
              value: value,
            ),
          );
        }
      },
    );
  }

  Widget _buildThemeTile() {
    final label = _themeMode == 'system'
        ? 'lbl_system_default'.tr
        : _themeMode == 'dark'
            ? 'lbl_theme_dark'.tr
            : 'lbl_theme_light'.tr;
    return ListTile(
      title: Text('lbl_theme'.tr),
      subtitle: Text(label),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        final value = await showSelectionSheet<String>(
          context: context,
          title: 'lbl_theme'.tr,
          options: const [
            Option('system', 'lbl_system_default'),
            Option('light', 'lbl_theme_light'),
            Option('dark', 'lbl_theme_dark'),
          ],
          selected: _themeMode,
        );
        if (value != null && value != _themeMode) {
          di.sl<ThemeBloc>().add(ChangeThemeModeEvent(value));
          setState(() => _themeMode = value);
          unawaited(
            di.sl<AnalyticsService>().logThemeChange(value == 'dark'),
          );
          unawaited(
            di.sl<AnalyticsService>().setUserProperty(
              name: AnalyticsProperties.themeMode,
              value: value,
            ),
          );
        }
      },
    );
  }

  Widget _buildFontSizeTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'lbl_quran_font'.tr,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'بِسْمِ اللَّهِ',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: _quranFontSize,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Slider(
              value: _quranFontSize,
              min: 16,
              max: 40,
              divisions: 24,
              label: _quranFontSize.round().toString(),
              onChanged: (val) {
                setState(() {
                  _quranFontSize = val;
                  PrefUtils().setQuranFontSize(val);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
