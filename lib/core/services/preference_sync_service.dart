import 'dart:async';
import '../../data/datasource/qf_preference/qf_preference_remote_data_source.dart';
import '../../injection_container.dart';
import '../analytics/analytics_service.dart';
import '../utils/logger.dart';
import '../utils/pref_utils.dart';

/// Maps a local preference key to its QF API group/key and value transformers.
class _QfPrefMapping {
  final String group;
  final String key;
  final dynamic Function(PrefUtils) getter;
  final Future<void> Function(PrefUtils, dynamic) setter;
  final dynamic Function(dynamic localValue)? toQfValue;
  final dynamic Function(dynamic qfValue)? fromQfValue;

  const _QfPrefMapping({
    required this.group,
    required this.key,
    required this.getter,
    required this.setter,
    this.toQfValue,
    this.fromQfValue,
  });
}

/// Service that syncs local SharedPreferences with Quran.Foundation Preference API.
///
/// Maps local preference keys to QF preference groups/keys and handles
/// bidirectional sync.
class PreferenceSyncService {
  /// Mapping of local preference identifiers to QF API structure.
  static final List<_QfPrefMapping> _mappings = [
    _QfPrefMapping(
      group: 'theme',
      key: 'type',
      getter: (p) => p.getThemeMode(),
      setter: (p, v) => p.setThemeMode(v.toString()),
      toQfValue: (v) {
        final s = v.toString();
        // Map our 'system' to QF's 'auto'
        return s == 'system' ? 'auto' : s;
      },
      fromQfValue: (v) {
        final s = v.toString();
        // Map QF's 'auto' to our 'system'
        return s == 'auto' ? 'system' : s;
      },
    ),
    _QfPrefMapping(
      group: 'language',
      key: 'language',
      getter: (p) => p.getLocaleCode(),
      setter: (p, v) => p.setLocaleCode(v.toString()),
      toQfValue: (v) {
        final s = v.toString();
        // Map our 'system' to a sensible default for QF
        return s == 'system' ? 'en' : s;
      },
      fromQfValue: (v) => v.toString(),
    ),
    _QfPrefMapping(
      group: 'quranReaderStyles',
      key: 'quranFont',
      getter: (p) => p.getMushafType(),
      setter: (p, v) => p.setMushafType(v.toString()),
      toQfValue: (v) {
        final s = v?.toString() ?? '';
        // Map local mushaf types to QF quranFont values
        return _mapMushafTypeToQfFont(s);
      },
      fromQfValue: (v) {
        final s = v.toString();
        return _mapQfFontToMushafType(s);
      },
    ),
    _QfPrefMapping(
      group: 'audio',
      key: 'reciter',
      getter: (p) => p.getReciterId(),
      setter: (p, v) => p.setReciterId(
        v is num ? v.toInt() : int.tryParse(v.toString()) ?? 7,
      ),
    ),
  ];

  QfPreferenceRemoteDataSource? _remote;

  PreferenceSyncService({QfPreferenceRemoteDataSource? remote})
      : _remote = remote;

  QfPreferenceRemoteDataSource get _ds =>
      _remote ?? sl<QfPreferenceRemoteDataSource>();

  /// Push all local preferences to QF.
  Future<int> pushLocalToRemote() async {
    final prefs = PrefUtils();
    int pushed = 0;

    for (final mapping in _mappings) {
      final localValue = mapping.getter(prefs);
      if (localValue == null) continue;

      final qfValue = mapping.toQfValue?.call(localValue) ?? localValue;
      final success = await _ds.setPreference(
        group: mapping.group,
        key: mapping.key,
        value: qfValue,
      );
      if (success) pushed++;
    }

    Logger.info('Pushed $pushed preferences to QF', feature: 'PrefSync');
    unawaited(sl<AnalyticsService>().logPreferenceSync(
      direction: 'push',
      count: pushed,
    ));
    return pushed;
  }

  /// Pull preferences from QF and apply to local SharedPreferences.
  Future<int> pullRemoteToLocal() async {
    final remotePrefs = await _ds.getPreferences();
    if (remotePrefs.isEmpty) return 0;

    final prefs = PrefUtils();
    int applied = 0;

    for (final mapping in _mappings) {
      final groupData = remotePrefs[mapping.group];
      if (groupData is! Map<String, dynamic>) continue;

      final qfValue = groupData[mapping.key];
      if (qfValue == null) continue;

      final localValue = mapping.fromQfValue?.call(qfValue) ?? qfValue;
      await mapping.setter(prefs, localValue);
      applied++;
    }

    Logger.info('Pulled $applied preferences from QF', feature: 'PrefSync');
    unawaited(sl<AnalyticsService>().logPreferenceSync(
      direction: 'pull',
      count: applied,
    ));
    return applied;
  }

  /// Two-way sync: pull remote first, then push local.
  Future<(int pulled, int pushed)> twoWaySync() async {
    final pulled = await pullRemoteToLocal();
    final pushed = await pushLocalToRemote();
    return (pulled, pushed);
  }

  // ── Value mappers ──

  static String _mapMushafTypeToQfFont(String localType) {
    return switch (localType.toLowerCase()) {
      'uthmani' || 'quran-uthmani' => 'text_uthmani',
      'indopak' => 'text_indopak',
      'tajweed' => 'tajweed',
      'qcfv2' || 'code_v2' => 'code_v2',
      'qcfv1' || 'code_v1' => 'code_v1',
      'qpc_uthmani_hafs' => 'qpc_uthmani_hafs',
      'tajweed_v4' => 'tajweed_v4',
      _ => 'text_uthmani',
    };
  }

  static String _mapQfFontToMushafType(String qfFont) {
    return switch (qfFont.toLowerCase()) {
      'text_uthmani' => 'uthmani',
      'text_indopak' => 'indopak',
      'tajweed' => 'tajweed',
      'code_v2' => 'qcfv2',
      'code_v1' => 'qcfv1',
      'qpc_uthmani_hafs' => 'qpc_uthmani_hafs',
      'tajweed_v4' => 'tajweed_v4',
      _ => 'uthmani',
    };
  }
}
