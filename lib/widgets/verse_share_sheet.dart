import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../core/app_export.dart';
import '../core/utils/share_as_image.dart';
import '../presentation/surah_screen/widgets/verse_image_card.dart';

class VerseShareSheet extends StatefulWidget {
  final String verseText;
  final int surahId;
  final int verseNumber;
  final String surahName;
  final String? translation;

  const VerseShareSheet({
    super.key,
    required this.verseText,
    required this.surahId,
    required this.verseNumber,
    required this.surahName,
    this.translation,
  });

  @override
  State<VerseShareSheet> createState() => _VerseShareSheetState();

  static void show({
    required BuildContext context,
    required String verseText,
    required int surahId,
    required int verseNumber,
    required String surahName,
    String? translation,
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
        translation: translation,
      ),
    );
  }
}

class _VerseShareSheetState extends State<VerseShareSheet> {
  bool _isLoading = false;

  void _shareAsText() {
    final text =
        '${widget.verseText}\n\n— ${widget.surahName}, ${'lbl_ayah'.tr} ${widget.verseNumber}\n${'msg_via_app'.tr.replaceAll('{app}', 'app_name'.tr)}';
    Share.share(text);
    Navigator.pop(context);
  }

  void _copyText() {
    final text =
        '${widget.verseText}\n— ${widget.surahName}, ${'lbl_ayah'.tr} ${widget.verseNumber}';
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    SnackBarHelper.show(
      context,
      message: 'msg_text_copied'.tr,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _shareAsImage() async {
    setState(() => _isLoading = true);

    final key = GlobalKey();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: -9999,
        child: RepaintBoundary(
          key: key,
          child: VerseImageCard(
            arabicText: widget.verseText,
            surahName: widget.surahName,
            verseNumber: widget.verseNumber,
            translation: widget.translation,
            width: 1080,
            height: 1350,
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Wait for the widget to render before capturing
    await Future.delayed(const Duration(milliseconds: 100));
    await WidgetsBinding.instance.endOfFrame;

    try {
      final path = await ShareAsImage.captureWidget(key);
      entry.remove();
      await Share.shareXFiles([XFile(path)], text: 'Shared from Hafiz');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      entry.remove();
      Logger.error('Failed to share image: $e', feature: 'Sharing');
      if (mounted) {
        SnackBarHelper.show(
          context,
          message: 'msg_operation_failed'.tr,
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text('lbl_share_text'.tr),
                subtitle: Text(
                  'msg_share_text_desc'.tr,
                  style: theme.textTheme.bodySmall,
                ),
                onTap: _shareAsText,
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text('lbl_share_as_image'.tr),
                onTap: _shareAsImage,
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text('lbl_copy_text'.tr),
                subtitle: Text(
                  'msg_copy_text_desc'.tr,
                  style: theme.textTheme.bodySmall,
                ),
                onTap: _copyText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
