import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/settings_utils.dart';

class ReadingSection extends StatefulWidget {
  const ReadingSection({super.key});

  @override
  State<ReadingSection> createState() => _ReadingSectionState();
}

class _ReadingSectionState extends State<ReadingSection> {
  late bool _isSingleLine;
  late String _orientationMode;
  late String _defaultQuranView;
  late String _mushafType;
  late bool _keepScreenOn;

  @override
  void initState() {
    super.initState();
    _isSingleLine = PrefUtils().getVerseViewMode();
    _orientationMode = PrefUtils().getOrientationMode();
    _defaultQuranView = PrefUtils().getDefaultQuranView();
    _mushafType = PrefUtils().getMushafType() ?? 'madani';
    _keepScreenOn = PrefUtils().isKeepScreenOn();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: [
        _buildOrientationTile(),
        const Divider(height: 1),
        _buildViewModeTile(),
        const Divider(height: 1),
        _buildDefaultViewTile(),
        const Divider(height: 1),
        _buildMushafTypeTile(),
        const Divider(height: 1),
        _buildKeepScreenOnTile(),
      ],
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
        final value = await showSelectionSheet<String>(
          context: context,
          title: 'lbl_orientation'.tr,
          options: const [
            Option('system', 'lbl_system_default'),
            Option('portrait', 'lbl_portrait'),
            Option('landscape', 'lbl_landscape'),
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
        final value = await showSelectionSheet<String>(
          context: context,
          title: 'lbl_default_quran_view'.tr,
          options: const [
            Option('surah', 'lbl_surah_view'),
            Option('mushaf', 'lbl_mushaf_view'),
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
}
