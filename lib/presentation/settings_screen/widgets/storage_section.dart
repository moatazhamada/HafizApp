import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/mushaf/mushaf_cache_manager.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/settings_utils.dart';

class StorageSection extends StatelessWidget {
  const StorageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: [
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text('lbl_clear_mushaf_cache'.tr),
          subtitle: Text('msg_clear_mushaf_cache_desc'.tr),
          onTap: () => _clearMushafCache(context),
        ),
      ],
    );
  }

  Future<void> _clearMushafCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('lbl_clear_mushaf_cache'.tr),
        content: Text('msg_clear_mushaf_cache_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('lbl_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('lbl_confirm'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await MushafCacheManager.clearCache();
      if (context.mounted) {
        SnackBarHelper.show(
          context,
          message: 'msg_mushaf_cache_cleared'.tr,
          type: SnackBarType.success,
        );
      }
    }
  }
}
