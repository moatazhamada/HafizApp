import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

import '../../core/i18n/locale_controller.dart';
import '../../core/qiraat/qiraat_models.dart';
import '../../core/qiraat/qiraat_service.dart';
import '../../core/audio/recitation_models.dart';
import '../../core/audio/recitation_service.dart';
import '../../injection_container.dart' as di;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _themeMode;
  late bool _isSingleLine;
  late String _currentLang;
  late String _recitationProvider;
  late String _qiraatEdition;
  late int _reciterId;
  late int _qrcHafzLevel;
  late int _qrcTajweedLevel;
  List<QiraatEdition> _editions = [];
  List<Reciter> _reciters = [];
  bool _loadingEditions = true;
  bool _loadingReciters = true;
  final QiraatService _qiraatService = QiraatService();
  final RecitationService _recitationService = RecitationService();

  @override
  void initState() {
    super.initState();
    _themeMode = PrefUtils().getThemeMode();
    _isSingleLine = PrefUtils().getVerseViewMode();
    _currentLang = PrefUtils().getLocaleCode();
    _recitationProvider = PrefUtils().getRecitationProvider();
    _qiraatEdition = PrefUtils().getQiraatEdition();
    _reciterId = PrefUtils().getReciterId();
    _qrcHafzLevel = PrefUtils().getQrcHafzLevel();
    _qrcTajweedLevel = PrefUtils().getQrcTajweedLevel();
    _loadRecitationResources();
  }

  Future<void> _loadRecitationResources() async {
    final editions = await _qiraatService.fetchEditions();
    final reciters = await _recitationService.fetchReciters();
    if (!mounted) return;
    setState(() {
      _editions = editions;
      _reciters = reciters;
      _loadingEditions = false;
      _loadingReciters = false;
      if (!_editions.any((e) => e.identifier == _qiraatEdition) &&
          _editions.isNotEmpty) {
        _qiraatEdition = _editions.first.identifier;
      }
      if (!_reciters.any((r) => r.id == _reciterId) &&
          _reciters.isNotEmpty) {
        _reciterId = _reciters.first.id;
      }
    });
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
            activeThumbColor: Colors.teal,
          ),
          const Divider(),
          _buildSectionHeader('lbl_theme'.tr),
          _buildThemeOption('lbl_system_default'.tr, 'system'),
          _buildThemeOption('lbl_theme_light'.tr, 'light'),
          _buildThemeOption('lbl_theme_dark'.tr, 'dark'),
          const Divider(),
          _buildSectionHeader('lbl_recitation_coach'.tr),
          ListTile(
            title: Text('lbl_recitation_provider'.tr),
            subtitle: Text(_recitationProviderLabel(_recitationProvider)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectRecitationProvider,
          ),
          ListTile(
            title: Text('lbl_qiraat'.tr),
            subtitle: Text(
              _loadingEditions
                  ? 'lbl_loading'.tr
                  : _editionLabel(_qiraatEdition),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _loadingEditions ? null : _selectQiraatEdition,
          ),
          ListTile(
            title: Text('lbl_reciter'.tr),
            subtitle: Text(
              _loadingReciters
                  ? 'lbl_loading'.tr
                  : _reciterLabel(_reciterId),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _loadingReciters ? null : _selectReciter,
          ),
          if (_recitationProvider == 'custom') ...[
            ListTile(
              title: Text('lbl_custom_asr'.tr),
              subtitle: Text(
                PrefUtils().getCustomAsrEndpoint().isEmpty
                    ? 'msg_custom_asr_empty'.tr
                    : PrefUtils().getCustomAsrEndpoint(),
              ),
              trailing: const Icon(Icons.edit),
              onTap: _editCustomEndpoint,
            ),
          ],
          if (_recitationProvider == 'qrc') ...[
            ListTile(
              title: Text('lbl_hafz_level'.tr),
              subtitle: Text(_qrcHafzLevel.toString()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectHafzLevel,
            ),
            ListTile(
              title: Text('lbl_tajweed_level'.tr),
              subtitle: Text(_qrcTajweedLevel.toString()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTajweedLevel,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
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

  String _recitationProviderLabel(String provider) {
    switch (provider) {
      case 'qrc':
        return 'lbl_provider_qrc'.tr;
      case 'custom':
        return 'lbl_provider_custom'.tr;
      default:
        return 'lbl_provider_local'.tr;
    }
  }

  String _editionLabel(String id) {
    final edition =
        _editions.firstWhere((e) => e.identifier == id, orElse: () {
      return const QiraatEdition(
        identifier: 'quran-uthmani',
        name: 'Uthmani (Hafs)',
        language: 'ar',
        format: 'text',
        type: 'quran',
      );
    });
    return edition.name;
  }

  String _reciterLabel(int id) {
    final reciter = _reciters.firstWhere(
      (r) => r.id == id,
      orElse: () => const Reciter(id: 7, name: 'Mishary Alafasy'),
    );
    return reciter.name;
  }

  Future<void> _selectRecitationProvider() async {
    final value = await _showSelectionSheet<String>(
      title: 'lbl_recitation_provider'.tr,
      options: const [
        _Option('local', 'lbl_provider_local'),
        _Option('qrc', 'lbl_provider_qrc'),
        _Option('custom', 'lbl_provider_custom'),
      ],
      selected: _recitationProvider,
    );
    if (value != null && value != _recitationProvider) {
      await PrefUtils().setRecitationProvider(value);
      setState(() => _recitationProvider = value);
    }
  }

  Future<void> _selectQiraatEdition() async {
    final options = _editions
        .map((e) => _Option(e.identifier, e.name, isKey: false))
        .toList();
    final value = await _showSelectionSheet<String>(
      title: 'lbl_qiraat'.tr,
      options: options,
      selected: _qiraatEdition,
    );
    if (value != null && value != _qiraatEdition) {
      await PrefUtils().setQiraatEdition(value);
      setState(() => _qiraatEdition = value);
    }
  }

  Future<void> _selectReciter() async {
    final options = _reciters
        .map((r) => _Option(r.id.toString(), r.name, isKey: false))
        .toList();
    final value = await _showSelectionSheet<String>(
      title: 'lbl_reciter'.tr,
      options: options,
      selected: _reciterId.toString(),
    );
    if (value != null) {
      final id = int.tryParse(value) ?? _reciterId;
      await PrefUtils().setReciterId(id);
      setState(() => _reciterId = id);
    }
  }

  Future<void> _selectHafzLevel() async {
    final value = await _showSelectionSheet<String>(
      title: 'lbl_hafz_level'.tr,
      options: const [
        _Option('1', '1', isKey: false),
        _Option('2', '2', isKey: false),
        _Option('3', '3', isKey: false),
      ],
      selected: _qrcHafzLevel.toString(),
    );
    if (value != null) {
      final level = int.tryParse(value) ?? _qrcHafzLevel;
      await PrefUtils().setQrcHafzLevel(level);
      setState(() => _qrcHafzLevel = level);
    }
  }

  Future<void> _selectTajweedLevel() async {
    final value = await _showSelectionSheet<String>(
      title: 'lbl_tajweed_level'.tr,
      options: const [
        _Option('1', '1', isKey: false),
        _Option('2', '2', isKey: false),
        _Option('3', '3', isKey: false),
      ],
      selected: _qrcTajweedLevel.toString(),
    );
    if (value != null) {
      final level = int.tryParse(value) ?? _qrcTajweedLevel;
      await PrefUtils().setQrcTajweedLevel(level);
      setState(() => _qrcTajweedLevel = level);
    }
  }

  Future<void> _editCustomEndpoint() async {
    final controller =
        TextEditingController(text: PrefUtils().getCustomAsrEndpoint());
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lbl_custom_asr'.tr),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'msg_custom_asr_hint'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lbl_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('lbl_save'.tr),
          ),
        ],
      ),
    );
    if (value != null) {
      await PrefUtils().setCustomAsrEndpoint(value);
      setState(() {});
    }
  }

  Future<T?> _showSelectionSheet<T>({
    required String title,
    required List<_Option> options,
    required String selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          for (final option in options)
            ListTile(
              title: Text(option.isKey ? option.label.tr : option.label),
              trailing:
                  selected == option.value ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, option.value as T),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Option {
  final String value;
  final String label;
  final bool isKey;
  const _Option(this.value, this.label, {this.isKey = true});
}
