import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/notifications/notification_service.dart';

import '../../core/i18n/locale_controller.dart';
import '../../core/qiraat/qiraat_models.dart';
import '../../core/qiraat/qiraat_service.dart';
import '../../core/audio/recitation_models.dart';
import '../../core/audio/recitation_service.dart';
import 'package:hafiz_app/core/audio/whisper_platform.dart'
    if (dart.library.html) 'package:hafiz_app/core/audio/whisper_platform_web.dart';
import 'package:hafiz_app/core/utils/platform_file_utils.dart'
    if (dart.library.html) 'package:hafiz_app/core/utils/platform_file_utils_web.dart';
import '../../injection_container.dart' as di;
import '../auth/bloc/qf_auth_bloc.dart';
import '../../core/models/surface_type.dart';
import '../../core/utils/rtl_utils.dart';

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
  late bool _adaptiveQrc;
  late String _defaultQuranView;
  late String _mushafType;
  late bool _dailyVerseEnabled;
  late TimeOfDay _dailyVerseTime;
  late bool _readingReminderEnabled;
  late TimeOfDay _readingReminderTime;
  late bool _keepScreenOn;
  late String _surfaceType;
  double? _downloadProgress; // null = not downloading, 0.0–1.0 = progress
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
    _whisperModel = PrefUtils().getWhisperModel();
    _quranFontSize = PrefUtils().getQuranFontSize();
    _orientationMode = PrefUtils().getOrientationMode();
    _adaptiveQrc = PrefUtils().isAdaptiveQrc();
    _defaultQuranView = PrefUtils().getDefaultQuranView();
    _mushafType = PrefUtils().getMushafType() ?? 'madani';
    _dailyVerseEnabled = PrefUtils().isDailyVerseEnabled();
    _dailyVerseTime = _parseTime(PrefUtils().getDailyVerseTime());
    _readingReminderEnabled = PrefUtils().isReadingReminderEnabled();
    _readingReminderTime = _parseTime(PrefUtils().getReadingReminderTime());
    _keepScreenOn = PrefUtils().isKeepScreenOn();
    _surfaceType = PrefUtils().getSurfaceType() ?? 'reader';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 900;
          final horizontalPadding = isLarge ? 32.0 : 16.0;

          Widget content = ListView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
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
          _buildSectionLabel('lbl_home_layout'.tr),
          _buildCard([
            _buildHomeLayoutTile(),
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('lbl_reading'.tr),
          _buildCard([
            _buildViewModeTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildOrientationTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildDefaultViewTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildMushafTypeTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),

            _buildDailyVerseTile(),
            if (_dailyVerseEnabled) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildDailyVerseTimeTile(),
            ],
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildReadingReminderTile(),
            if (_readingReminderEnabled) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildReadingReminderTimeTile(),
            ],
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildKeepScreenOnTile(),
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('lbl_recitation_coach'.tr),
          _buildCard([
            ListTile(
              title: Text('lbl_recitation_provider'.tr),
              subtitle: Text(_recitationProviderLabel(_recitationProvider)),
              trailing: Icon(rtlChevron(context)),
              onTap: _selectRecitationProvider,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: Text('lbl_qiraat'.tr),
              subtitle: Text(
                _loadingEditions
                    ? 'lbl_loading'.tr
                    : _editionLabel(_qiraatEdition),
              ),
              trailing: Icon(rtlChevron(context)),
              onTap: _loadingEditions ? null : _selectQiraatEdition,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: Text('lbl_reciter'.tr),
              subtitle: Text(
                _loadingReciters ? 'lbl_loading'.tr : _reciterLabel(_reciterId),
              ),
              trailing: Icon(rtlChevron(context)),
              onTap: _loadingReciters ? null : _selectReciter,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: Text('lbl_adaptive_qrc'.tr),
              subtitle: Text('msg_adaptive_qrc_desc'.tr),
              value: _adaptiveQrc,
              onChanged: (val) async {
                await PrefUtils().setAdaptiveQrc(val);
                setState(() => _adaptiveQrc = val);
              },
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
                subtitle: _downloadProgress != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'msg_model_downloading'.tr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _downloadProgress,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      )
                    : Text(_whisperModelLabel(_whisperModel)),
                trailing: _downloadProgress != null
                    ? SizedBox(
                        width: 48,
                        child: Text(
                          '${(_downloadProgress! * 100).round()}%',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      )
                    : Icon(rtlChevron(context)),
                onTap: _downloadProgress != null ? null : _selectWhisperModel,
              ),
            ],
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('lbl_about'.tr),
          _buildCard([
            ListTile(
              leading: Icon(
                Icons.new_releases,
                color: theme.colorScheme.primary,
              ),
              title: Text('lbl_whats_new'.tr),
              trailing: Icon(rtlChevron(context)),
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.changelogScreen),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      );

      if (isLarge) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: content,
          ),
        );
      }

      return content;
    },
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
          final profile = state.profile;
          final initials = profile?.initials ??
              (state.userId?.isNotEmpty == true
                  ? state.userId![0].toUpperCase()
                  : '?');
          avatar = CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
          title = profile?.displayName ?? 'msg_qf_account'.tr;
          subtitle = profile?.email ?? 'msg_qf_logged_in'.tr;
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

        return Semantics(
          button: true,
          label: 'lbl_semantics_profile_card'.tr.replaceAll('{status}', title),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                      rtlChevron(context),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayLabel = isArabic ? label : label.toUpperCase();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        displayLabel,
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
      trailing: Icon(rtlChevron(context)),
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
      trailing: Icon(rtlChevron(context)),
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

  Widget _buildOrientationTile() {
    final label = _orientationMode == 'portrait'
        ? 'lbl_portrait'.tr
        : _orientationMode == 'landscape'
        ? 'lbl_landscape'.tr
        : 'lbl_system_default'.tr;
    return ListTile(
      title: Text('lbl_orientation'.tr),
      subtitle: Text(label),
      trailing: Icon(rtlChevron(context)),
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
          unawaited(
            SystemChrome.setPreferredOrientations(_getOrientations(value)),
          );
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
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDefaultViewTile() {
    final label = _defaultQuranView == 'mushaf'
        ? 'lbl_mushaf_view'.tr
        : 'lbl_surah_view'.tr;
    return ListTile(
      title: Text('lbl_default_quran_view'.tr),
      subtitle: Text(label),
      trailing: Icon(rtlChevron(context)),
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

  Widget _buildMushafTypeTile() {
    return ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text('lbl_mushaf_type'.tr),
      subtitle: Text(_mushafTypeLabel(_mushafType)),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.mushafTypeOnboarding,
          arguments: {'fromSettings': true},
        );
        final newType = PrefUtils().getMushafType() ?? 'madani';
        if (newType != _mushafType) {
          setState(() => _mushafType = newType);
        }
      },
    );
  }

  Widget _buildHomeLayoutTile() {
    return ListTile(
      leading: const Icon(Icons.dashboard_outlined),
      title: Text('lbl_home_layout'.tr),
      subtitle: Text(_surfaceTypeLabel(_surfaceType)),
      trailing: Icon(rtlChevron(context)),
      onTap: _selectHomeLayout,
    );
  }

  void _selectHomeLayout() async {
    final result = await showDialog<SurfaceType>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('lbl_home_layout'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SurfaceType.values.map((surface) {
            final isSelected = _surfaceType == surface.name;
            return ListTile(
              leading: Icon(
                surface.icon,
                color: isSelected ? surface.color : null,
              ),
              title: Text(surface.labelKey.tr),
              trailing: isSelected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, surface),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null && result.name != _surfaceType) {
      setState(() => _surfaceType = result.name);
      await PrefUtils().setSurfaceType(result.name);
      if (mounted) {
        // Redirect to home so the new surface is rendered immediately
        unawaited(NavigatorService.pushNamedAndRemoveUntil(AppRoutes.homeScreen));
      }
    }
  }

  String _surfaceTypeLabel(String type) {
    return SurfaceType.fromString(type).labelKey.tr;
  }

  Widget _buildDailyVerseTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_outlined),
      title: Text('lbl_daily_verse_notification'.tr),
      subtitle: Text('msg_daily_verse_desc'.tr),
      value: _dailyVerseEnabled,
      onChanged: (val) {
        setState(() => _dailyVerseEnabled = val);
        PrefUtils().setDailyVerseEnabled(val);
        final notificationService = NotificationService();
        if (val) {
          notificationService.scheduleDailyVerse();
        } else {
          notificationService.cancelRecurring();
        }
      },
    );
  }

  Widget _buildDailyVerseTimeTile() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text('lbl_daily_verse_time'.tr),
      subtitle: Text(_dailyVerseTime.format(context)),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _dailyVerseTime,
        );
        if (picked != null && picked != _dailyVerseTime) {
          setState(() => _dailyVerseTime = picked);
          final timeStr =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          await PrefUtils().setDailyVerseTime(timeStr);
          await NotificationService().scheduleDailyVerse();
        }
      },
    );
  }

  Widget _buildReadingReminderTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.access_time),
      title: Text('lbl_reading_reminder'.tr),
      subtitle: Text('msg_reading_reminder_desc'.tr),
      value: _readingReminderEnabled,
      onChanged: (val) {
        setState(() => _readingReminderEnabled = val);
        PrefUtils().setReadingReminderEnabled(val);
        final notificationService = NotificationService();
        if (val) {
          notificationService.scheduleReadingReminder();
        } else {
          notificationService.cancelRecurring();
        }
      },
    );
  }

  Widget _buildReadingReminderTimeTile() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text('lbl_reading_reminder_time'.tr),
      subtitle: Text(_readingReminderTime.format(context)),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _readingReminderTime,
        );
        if (picked != null && picked != _readingReminderTime) {
          setState(() => _readingReminderTime = picked);
          final timeStr =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          await PrefUtils().setReadingReminderTime(timeStr);
          await NotificationService().scheduleReadingReminder();
        }
      },
    );
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _buildKeepScreenOnTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.lightbulb_outline),
      title: Text('lbl_keep_screen_on'.tr),
      subtitle: Text('msg_keep_screen_on_desc'.tr),
      value: _keepScreenOn,
      onChanged: (val) {
        setState(() => _keepScreenOn = val);
        PrefUtils().setKeepScreenOn(val);
      },
    );
  }

  String _mushafTypeLabel(String type) {
    switch (type) {
      case 'madani':
        return 'lbl_mushaf_madani'.tr;
      case 'shemerly':
        return 'lbl_mushaf_shemerly'.tr;
      case 'naskh':
        return 'lbl_mushaf_naskh'.tr;
      case 'warsh':
        return 'lbl_mushaf_warsh'.tr;
      default:
        return type;
    }
  }

  List<DeviceOrientation> _getOrientations(String mode) {
    switch (mode) {
      case 'portrait':
        return [DeviceOrientation.portraitUp];
      case 'landscape':
        return [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ];
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
        return '${'lbl_model_tiny'.tr} · ${'lbl_model_tiny_size'.tr}';
      case 'small':
        return '${'lbl_model_small'.tr} · ${'lbl_model_small_size'.tr}';
      case 'base':
      default:
        return '${'lbl_model_base'.tr} · ${'lbl_model_base_size'.tr} · ${'lbl_model_recommended'.tr}';
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
      if (!mounted) return;
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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() => _reciterId = id);
    }
  }

  Future<void> _selectWhisperModel() async {
    const models = [
      _WhisperModelOption(
        key: 'tiny',
        titleKey: 'lbl_model_tiny',
        descKey: 'lbl_model_tiny_desc',
        sizeKey: 'lbl_model_tiny_size',
      ),
      _WhisperModelOption(
        key: 'base',
        titleKey: 'lbl_model_base',
        descKey: 'lbl_model_base_desc',
        sizeKey: 'lbl_model_base_size',
        recommended: true,
      ),
      _WhisperModelOption(
        key: 'small',
        titleKey: 'lbl_model_small',
        descKey: 'lbl_model_small_desc',
        sizeKey: 'lbl_model_small_size',
      ),
    ];

    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'lbl_whisper_model'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          for (final model in models)
            ListTile(
              selected: _whisperModel == model.key,
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              title: Row(
                children: [
                  Text(model.titleKey.tr),
                  const SizedBox(width: 8),
                  Text(
                    model.sizeKey.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  if (model.recommended) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'lbl_model_recommended'.tr,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                model.descKey.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: _whisperModel == model.key
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.pop(context, model.key),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (value != null && value != _whisperModel) {
      await _downloadWhisperModel(value);
      if (mounted && _downloadProgress == null) {
        await PrefUtils().setWhisperModel(value);
        setState(() => _whisperModel = value);
      }
    }
  }

  Future<void> _downloadWhisperModel(String value) async {
    if (kIsWeb) return;

    final model = _mapWhisperModel(value);
    final modelDir = await getWhisperModelDir();
    final localPath = '$modelDir/ggml-${getWhisperModelName(model)}.bin';

    // Skip download if model already exists
    if (platformFileExists(localPath)) return;

    setState(() => _downloadProgress = 0.0);

    try {
      final dio = Dio();
      await dio.download(
        getWhisperModelUri(model).toString(),
        localPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
    } catch (e) {
      // Clean up partial download on failure
      platformDeleteFile(localPath);
      if (mounted) {
        SnackBarHelper.show(
          context,
          message: 'msg_model_download_failed'.tr,
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _downloadProgress = null);
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
              trailing: selected == option.value
                  ? const Icon(Icons.check)
                  : null,
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

class _WhisperModelOption {
  final String key;
  final String titleKey;
  final String descKey;
  final String sizeKey;
  final bool recommended;
  const _WhisperModelOption({
    required this.key,
    required this.titleKey,
    required this.descKey,
    required this.sizeKey,
    this.recommended = false,
  });
}
