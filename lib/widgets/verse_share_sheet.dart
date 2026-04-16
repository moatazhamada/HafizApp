import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../core/app_export.dart';

class VerseShareSheet extends StatelessWidget {
  final String verseText;
  final int surahId;
  final int verseNumber;
  final String surahName;

  const VerseShareSheet({
    super.key,
    required this.verseText,
    required this.surahId,
    required this.verseNumber,
    required this.surahName,
  });

  void _shareAsText(BuildContext context) {
    final text =
        '$verseText\n\n— $surahName, ${'lbl_ayah'.tr} $verseNumber\n${'msg_via_app'.tr.replaceAll('{app}', 'app_name'.tr)}';
    Share.share(text);
    Navigator.pop(context);
  }

  void _copyText(BuildContext context) {
    final text = '$verseText\n— $surahName, ${'lbl_ayah'.tr} $verseNumber';
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('msg_text_copied'.tr),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'lbl_share_verse'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text('lbl_share_text'.tr),
              subtitle: Text(
                'msg_share_text_desc'.tr,
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => _shareAsText(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text('lbl_copy_text'.tr),
              subtitle: Text(
                'msg_copy_text_desc'.tr,
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => _copyText(context),
            ),
          ],
        ),
      ),
    );
  }

  static void show({
    required BuildContext context,
    required String verseText,
    required int surahId,
    required int verseNumber,
    required String surahName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VerseShareSheet(
        verseText: verseText,
        surahId: surahId,
        verseNumber: verseNumber,
        surahName: surahName,
      ),
    );
  }
}
