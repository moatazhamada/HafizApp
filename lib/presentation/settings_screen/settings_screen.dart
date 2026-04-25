import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_app/core/app_export.dart';

import '../../core/i18n/locale_controller.dart';
import '../../core/qiraat/qiraat_models.dart';
import '../../core/qiraat/qiraat_service.dart';
import '../../core/audio/recitation_models.dart';
import '../../core/audio/recitation_service.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
import '../../injection_container.dart' as di;
import '../auth/bloc/qf_auth_bloc.dart';

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
  late String _whisperModel;
  late double _quranFontSize;
  late String _orientationMode;
  late String _defaultQuranView;
  bool _whisperDownloading = false;
  List<QiraatEdition> _editions = [];
  List<Reciter> _reciters = [];
  bool _loadingEditions = true;
  bool _loadingReciters = true;
  final QiraatService _qiraatService = QiraatService();
  final RecitationService _recitationService = RecitationService();
  final WhisperController _whisperController = WhisperController();

  @override
  void initState() {
    super.initState();
    _themeMode = PrefUtils().getThemeMode();
    _isSingleLine = PrefUtils().getVerseViewMode();
    _currentLang = PrefUtils().getLocaleCode();
    _recitationProvider = PrefUtils().getRecitationProvider();
    _qiraatEdition = PrefUtils().getQiraatEdition();
    _reciterId = PrefUtils().getReciterId();
    _whisperModel = PrefUtils().getWhisperModel();
    _quranFontSize = PrefUtils().getQuranFontSize();
    _orientationMode = PrefUtils().getOrientationMode();
    _defaultQuranView = PrefUtils().getDefaultQuranView();
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
      if (!_reciters.any((r) => r.id == _reciterId) && _reciters.isNotEmpty) {
        _reciterId = _reciters.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('lbl_settings'.tr)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildProfileCard(theme),
          const SizedBox(height: 20),
          _buildSectionLabel('lbl_appearance'.tr),
          _buildCard([
            _buildLanguageTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildThemeTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildFontSizeTile(),
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('lbl_reading'.tr),
          _buildCard([
            _buildViewModeTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildOrientationTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildDefaultViewTile(),
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('lbl_recitation_coach'.tr),
          _buildCard([
            ListTile(
              title: Text('lbl_recitation_provider'.tr),
              subtitle: Text(_recitationProviderLabel(_recitationProvider)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectRecitationProvider,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: Text('lbl_qiraat'.tr),
              subtitle: Text(
                _loadingEditions ? 'lbl_loading'.tr : _editionLabel(_qiraatEdition),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _loadingEditions ? null : _selectQiraatEdition,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: Text('lbl_reciter'.tr),
              subtitle: Text(
                _loadingReciters ? 'lbl_loading'.tr : _reciterLabel(_reciterId),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _loadingReciters ? null : _selectReciter,
            ),
            if (_recitationProvider == 'local_whisper') ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                title: Text('msg_local_whisper_tip'.tr),
                subtitle: Text('msg_local_whisper_desc'.tr),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                title: Text('lbl_whisper_model'.tr),
                subtitle: Text(_whisperModelLabel(_whisperModel)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _whisperDownloading ? null : _selectWhisperModel,
              ),
            ],
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('lbl_about'.tr),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.new_releases, color: Colors.teal),
              title: Text('lbl_whats_new'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.changelogScreen),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return BlocBuilder<QfAuthBloc, QfAuthState>(
      builder: (context, state) {
        final Widget avatar;
        final String title;
        final String subtitle;

        if (state is QfAuthAuthenticated) {
          final initial = state.userId?.isNotEmpty == true
              ? state.userId![0].toUpperCase()
              : null;
          avatar = CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary,
            child: initial != null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : const Icon(Icons.account_circle, color: Colors.white, size: 28),
          );
          title = 'Quran.com account';
          subtitle = state.userId ?? '';
        } else if (state is QfAuthLoading || state is QfAuthInitial) {
          avatar = CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          );
          title = 'lbl_not_signed_in'.tr;
          subtitle = 'lbl_tap_to_sign_in'.tr;
        } else {
          // QfAuthUnauthenticated, QfAuthError
          avatar = CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.account_circle_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
          );
          title = 'lbl_not_signed_in'.tr;
          subtitle = 'lbl_tap_to_sign_in'.tr;
        }

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.cloudSyncPage),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  avatar,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
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
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final value = await _showSelectionSheet<String>(
          title: 'about_language_title'.tr,
          options: const [
            _Option('system', 'lbl_system_default'),
            _Option('en', 'English', isKey: false),
            _Option('ar', 'العربية', isKey: false),
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
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final value = await _showSelectionSheet<String>(
          title: 'lbl_theme'.tr,
          options: const [
            _Option('system', 'lbl_system_default'),
            _Option('light', 'lbl_theme_light'),
            _Option('dark', 'lbl_theme_dark'),
          ],
          selected: _themeMode,
        );
        if (value != null && value != _themeMode) {
          di.sl<ThemeBloc>().add(ChangeThemeModeEvent(value));
          setState(() => _themeMode = value);
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
                Text('lbl_quran_font'.tr, style: Theme.of(context).textTheme.bodyLarge),
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

  Widget _buildOrientationTile() {
    final label = _orientationMode == 'portrait'
        ? 'lbl_portrait'.tr
        : _orientationMode == 'landscape'
            ? 'lbl_landscape'.tr
            : 'lbl_system_default'.tr;
    return ListTile(
      title: Text('lbl_orientation'.tr),
      subtitle: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final value = await _showSelectionSheet<String>(
          title: 'lbl_orientation'.tr,
          options: const [
            _Option('system', 'lbl_system_default'),
            _Option('portrait', 'lbl_portrait'),
            _Option('landscape', 'lbl_landscape'),
          ],
          selected: _orientationMode,
        );
        if (value != null && value != _orientationMode) {
          unawaited(PrefUtils().setOrientationMode(value));
          unawaited(SystemChrome.setPreferredOrientations(_getOrientations(value)));
          setState(() => _orientationMode = value);
        }
      },
    );
  }

  Widget _buildViewModeTile() {
    return SwitchListTile(
      title: Text('lbl_view_mode'.tr),
      subtitle: Text(
        _isSingleLine ? 'lbl_view_single_line'.tr : 'lbl_view_continuous'.tr,
      ),
      value: _isSingleLine,
      onChanged: (val) {
        setState(() {
          _isSingleLine = val;
          PrefUtils().setVerseViewMode(val);
        });
      },
      activeThumbColor: Colors.teal,
    );
  }

  Widget _buildDefaultViewTile() {
    final label = _defaultQuranView == 'mushaf'
        ? 'lbl_mushaf_view'.tr
        : 'lbl_surah_view'.tr;
    return ListTile(
      title: Text('lbl_default_quran_view'.tr),
      subtitle: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final value = await _showSelectionSheet<String>(
          title: 'lbl_default_quran_view'.tr,
          options: const [
            _Option('surah', 'lbl_surah_view'),
            _Option('mushaf', 'lbl_mushaf_view'),
          ],
          selected: _defaultQuranView,
        );
        if (value != null && value != _defaultQuranView) {
          unawaited(PrefUtils().setDefaultQuranView(value));
          setState(() => _defaultQuranView = value);
        }
      },
    );
  }

  List<DeviceOrientation> _getOrientations(String mode) {
    switch (mode) {
      case 'portrait':
        return [DeviceOrientation.portraitUp];
      case 'landscape':
        return [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];
      default:
        return DeviceOrientation.values;
    }
  }

  String _recitationProviderLabel(String provider) {
    switch (provider) {
      case 'local_whisper':
        return 'lbl_provider_whisper'.tr;
      default:
        return 'lbl_provider_local'.tr;
    }
  }

  String _editionLabel(String id) {
    final edition = _editions.firstWhere(
      (e) => e.identifier == id,
      orElse: () => const QiraatEdition(
        identifier: 'quran-uthmani',
        name: 'Uthmani (Hafs)',
        language: 'ar',
        format: 'text',
        type: 'quran',
      ),
    );
    return edition.name;
  }

  String _reciterLabel(int id) {
    final reciter = _reciters.firstWhere(
      (r) => r.id == id,
      orElse: () => const Reciter(id: 7, name: 'Mishary Alafasy'),
    );
    return reciter.name;
  }

  String _whisperModelLabel(String model) {
    switch (model) {
      case 'tiny':
        return '${'lbl_model_tiny'.tr} (${'lbl_model_tiny_size'.tr})';
      case 'small':
        return '${'lbl_model_small'.tr} (${'lbl_model_small_size'.tr})';
      case 'base':
      default:
        return '${'lbl_model_base'.tr} (${'lbl_model_base_size'.tr})';
    }
  }

  Future<void> _selectRecitationProvider() async {
    final value = await _showSelectionSheet<String>(
      title: 'lbl_recitation_provider'.tr,
      options: const [
        _Option('local', 'lbl_provider_local'),
        _Option('local_whisper', 'lbl_provider_whisper'),
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

  Future<void> _selectWhisperModel() async {
    final value = await _showSelectionSheet<String>(
      title: 'lbl_whisper_model'.tr,
      options: const [
        _Option('tiny', 'lbl_model_tiny'),
        _Option('base', 'lbl_model_base'),
        _Option('small', 'lbl_model_small'),
      ],
      selected: _whisperModel,
    );
    if (value != null && value != _whisperModel) {
      setState(() => _whisperDownloading = true);
      await _downloadWhisperModel(value);
      await PrefUtils().setWhisperModel(value);
      setState(() {
        _whisperModel = value;
        _whisperDownloading = false;
      });
    }
  }

  Future<void> _downloadWhisperModel(String value) async {
    final model = _mapWhisperModel(value);
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('lbl_downloading_model'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 12),
              Text('msg_model_download_wait'.tr),
            ],
          ),
        ),
      ),
    );
    try {
      await _whisperController.downloadModel(model);
    } finally {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  WhisperModel _mapWhisperModel(String value) {
    switch (value) {
      case 'tiny':
        return WhisperModel.tiny;
      case 'small':
        return WhisperModel.small;
      case 'base':
      default:
        return WhisperModel.base;
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          for (final option in options)
            ListTile(
              title: Text(option.isKey ? option.label.tr : option.label),
              trailing: selected == option.value ? const Icon(Icons.check) : null,
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
