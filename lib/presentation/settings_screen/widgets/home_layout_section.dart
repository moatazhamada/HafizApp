import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/models/surface_type.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/settings_utils.dart';

class HomeLayoutSection extends StatefulWidget {
  const HomeLayoutSection({super.key});

  @override
  State<HomeLayoutSection> createState() => _HomeLayoutSectionState();
}

class _HomeLayoutSectionState extends State<HomeLayoutSection> {
  late String _surfaceType;

  @override
  void initState() {
    super.initState();
    _surfaceType = PrefUtils().getSurfaceType() ?? 'reader';
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard_outlined),
          title: Text('lbl_home_layout'.tr),
          subtitle: Text(_surfaceTypeLabel(_surfaceType)),
          trailing: Icon(rtlChevron(context)),
          onTap: _selectHomeLayout,
        ),
      ],
    );
  }

  String _surfaceTypeLabel(String type) {
    return SurfaceType.fromString(type).labelKey.tr;
  }

  Future<void> _selectHomeLayout() async {
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
        unawaited(NavigatorService.pushNamedAndRemoveUntil(AppRoutes.homeScreen));
      }
    }
  }
}
