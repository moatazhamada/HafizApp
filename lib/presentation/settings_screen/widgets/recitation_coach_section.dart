import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/audio/recitation_models.dart';
import 'package:hafiz_app/core/audio/recitation_service.dart';
import 'package:hafiz_app/core/audio/whisper_platform.dart'
    if (dart.library.html) 'package:hafiz_app/core/audio/whisper_platform_web.dart';
import 'package:hafiz_app/core/qiraat/qiraat_models.dart';
import 'package:hafiz_app/core/qiraat/qiraat_service.dart';
import 'package:hafiz_app/core/utils/platform_file_utils.dart'
    if (dart.library.html) 'package:hafiz_app/core/utils/platform_file_utils_web.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/settings_utils.dart';

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

class RecitationCoachSection extends StatefulWidget {
  const RecitationCoachSection({super.key});

  @override
  State<RecitationCoachSection> createState() => _RecitationCoachSectionState();
}

class _RecitationCoachSectionState extends State<RecitationCoachSection> {
  late String _recitationProvider;
  late String _qiraatEdition;
  late int _reciterId;
  late String _whisperModel;
  late bool _adaptiveQrc;
  double? _downloadProgress;
  List<QiraatEdition> _editions = [];
  List<Reciter> _reciters = [];
  bool _loadingEditions = true;
  bool _loadingReciters = true;
  final QiraatService _qiraatService = QiraatService();
  final RecitationService _recitationService = RecitationService();

  @override
  void initState() {
    super.initState();
    _recitationProvider = PrefUtils().getRecitationProvider();
    _qiraatEdition = PrefUtils().getQiraatEdition();
    _reciterId = PrefUtils().getReciterId();
    _whisperModel = PrefUtils().getWhisperModel();
    _adaptiveQrc = PrefUtils().isAdaptiveQrc();
    _loadRecitationResources();
  }

  Future<void> _loadRecitationResources() async {
    List<QiraatEdition> editions = [];
    List<Reciter> reciters = [];
    try {
      editions = await _qiraatService.fetchEditions();
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to load qiraat editions: $e',
        feature: 'Settings',
        error: e,
        stackTrace: stackTrace,
      );
    }
    try {
      reciters = await _recitationService.fetchReciters();
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to load reciters: $e',
        feature: 'Settings',
        error: e,
        stackTrace: stackTrace,
      );
    }
    if (mounted) {
      setState(() {
        _editions = editions;
        _reciters = reciters;
        _loadingEditions = false;
        _loadingReciters = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: [
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
            _loadingEditions ? 'lbl_loading'.tr : _editionLabel(_qiraatEdition),
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  )
                : Icon(rtlChevron(context)),
            onTap: _downloadProgress != null ? null : _selectWhisperModel,
          ),
        ],
      ],
    );
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
    final value = await showSelectionSheet<String>(
      context: context,
      title: 'lbl_recitation_provider'.tr,
      options: const [
        Option('local', 'lbl_provider_local'),
        Option('local_whisper', 'lbl_provider_whisper'),
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
        .map((e) => Option(e.identifier, e.name, isKey: false))
        .toList();
    final value = await showSelectionSheet<String>(
      context: context,
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
        .map((r) => Option(r.id.toString(), r.name, isKey: false))
        .toList();
    final value = await showSelectionSheet<String>(
      context: context,
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
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.1),
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
}
