import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/localization/app_localization.dart';
import '../../core/i18n/locale_controller.dart';
import '../../injection_container.dart' as di;
import '../../theme/bloc/theme_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _themeMode;
  late bool _isSingleLine;
  late String _currentLang;

  @override
  void initState() {
    super.initState();
    _themeMode = PrefUtils().getThemeMode();
    _isSingleLine = PrefUtils().getVerseViewMode();
    _currentLang = PrefUtils().getLocaleCode();
  }

  @override
  Widget build(BuildContext context) {
    // We don't need manual Theme wrapping anymore because main.dart handles it via ThemeMode.
    // The SettingsScreen will rebuild when theme mode changes in Prefs is picked up by main.dart or if we just setState here.
    // However, main.dart only rebuilds if it listens to something.
    // Since we called setLocale, main.dart rebuilds. For Theme, main.dart might not listen to Prefs directly yet?
    // main.dart uses ValueListenableBuilder<Locale>, but seemingly not for themeMode updates (it uses PrefUtils().getThemeMode() inside build).
    // To ensure immediate update, we can rely on main.dart rebuilding on Locale change, or better, make SettingsScreen just reflect current context theme.
    // If the user selects a new theme, main.dart needs to rebuild.
    // Currently, main.dart uses `themeBloc`... wait, `themeBloc` was used for toggle.
    // The user's new system requires main.dart to rebuild on preference change.
    // Let's assume hitting setState here will just update the UI state, but the actual app theme switch happens because
    // we might need to notify the root.
    // BUT for now, let's fix the COLORS first.

    // Simply using Scaffold without manual colors will use the inherited Theme.
    // Since main.dart is passing light/dark theme based on system/prefs,
    // inherited theme IS NOT necessarily correct if main.dart hasn't rebuilt yet.
    // BUT, the crash/contrast issue is because we were FORCING colors manually.
    // Let's rely on standard widgets.

    return Scaffold(
      appBar: AppBar(title: Text('lbl_settings'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('about_language_title'.tr),
          _buildLanguageOption('lbl_system_default'.tr, 'system'),
          _buildLanguageOption('English', 'en'),
          _buildLanguageOption('العربية', 'ar'),
          const Divider(),
          _buildSectionHeader('lbl_view_mode'.tr),
          SwitchListTile(
            title: Text('lbl_view_single_line'.tr),
            subtitle: Text(
              _isSingleLine
                  ? 'lbl_view_single_line'.tr
                  : 'lbl_view_continuous'.tr,
            ),
            value: _isSingleLine,
            onChanged: (val) {
              setState(() {
                _isSingleLine = val;
                PrefUtils().setVerseViewMode(val);
              });
            },
            activeColor: Colors.teal,
          ),
          const Divider(),
          _buildSectionHeader('lbl_theme'.tr),
          _buildThemeOption('lbl_system_default'.tr, 'system'),
          _buildThemeOption('lbl_theme_light'.tr, 'light'),
          _buildThemeOption('lbl_theme_dark'.tr, 'dark'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code) {
    final bool isSelected = _currentLang == code;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
      onTap: () async {
        if (!isSelected) {
          Locale newLocale;
          if (code == 'system') {
            final systemLoc = WidgetsBinding.instance.platformDispatcher.locale;
            newLocale = (systemLoc.languageCode == 'en')
                ? const Locale('en', 'US')
                : const Locale('ar', 'EG');
          } else {
            newLocale = Locale(code, code == 'en' ? 'US' : 'EG');
          }

          LocaleController.setLocale(newLocale);
          await PrefUtils().setLocaleCode(code);
          setState(() {
            _currentLang = code;
          });
        }
      },
    );
  }

  Widget _buildThemeOption(String label, String mode) {
    final bool isSelected = _themeMode == mode;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
      onTap: () async {
        if (!isSelected) {
          di.sl<ThemeBloc>().add(ChangeThemeModeEvent(mode));
          
          setState(() {
            _themeMode = mode;
          });
        }
      },
    );
  }
}