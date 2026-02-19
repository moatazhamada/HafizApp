import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_export.dart';
import '../core/analytics/analytics_helper.dart';
import '../core/deep_link/deep_link_service.dart';
import '../core/quran_index/quran_surah.dart';
import '../injection_container.dart';
import '../../domain/entities/verse.dart';

/// Bottom sheet for sharing verses with multiple options
class VerseShareSheet extends StatelessWidget {
  final Surah surah;
  final Verse verse;
  final String? translation;

  const VerseShareSheet({
    super.key,
    required this.surah,
    required this.verse,
    this.translation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deepLinkService = DeepLinkService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'lbl_share_verse'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${surah.nameEnglish} (${verse.verseNumber})',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Share options
            _buildShareOption(
              context,
              icon: Icons.link,
              title: 'lbl_copy_link'.tr,
              subtitle: 'msg_copy_link_desc'.tr,
              onTap: () async {
                await deepLinkService.copyVerseWithAttribution(
                  surahId: surah.id,
                  verseNumber: verse.verseNumber,
                  verseText: verse.text,
                  surahName: surah.nameEnglish,
                );

                // Track verse sharing
                unawaited(
                  sl<AnalyticsHelper>().logVerseShared(
                    surah.id,
                    verse.verseNumber,
                    'copy_link',
                  ),
                );

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('msg_link_copied'.tr)),
                );
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.share,
              title: 'lbl_share_text'.tr,
              subtitle: 'msg_share_text_desc'.tr,
              onTap: () async {
                await deepLinkService.shareVerseLink(
                  surahId: surah.id,
                  verseNumber: verse.verseNumber,
                  verseText: verse.text,
                  surahName: surah.nameEnglish,
                );

                // Track verse sharing
                unawaited(
                  sl<AnalyticsHelper>().logVerseShared(
                    surah.id,
                    verse.verseNumber,
                    'share_text',
                  ),
                );

                navigator.pop();
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.image,
              title: 'lbl_share_as_image'.tr,
              subtitle: 'msg_share_image_desc'.tr,
              onTap: () => _showImageStylePicker(context),
            ),

            _buildShareOption(
              context,
              icon: Icons.content_copy,
              title: 'lbl_copy_text'.tr,
              subtitle: 'msg_copy_text_desc'.tr,
              onTap: () async {
                final text = verse.text;
                await deepLinkService.copyPlainText(text);

                // Track verse sharing
                unawaited(
                  sl<AnalyticsHelper>().logVerseShared(
                    surah.id,
                    verse.verseNumber,
                    'copy_text',
                  ),
                );

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('msg_text_copied'.tr)),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.teal),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showImageStylePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'lbl_select_style'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Style options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStyleOption(
                  context,
                  style: VerseImageStyle.classic,
                  name: 'Classic',
                  color: const Color(0xFFF5F0E6),
                ),
                _buildStyleOption(
                  context,
                  style: VerseImageStyle.modern,
                  name: 'Modern',
                  color: const Color(0xFF006754),
                ),
                _buildStyleOption(
                  context,
                  style: VerseImageStyle.minimal,
                  name: 'Minimal',
                  color: Colors.white,
                ),
                _buildStyleOption(
                  context,
                  style: VerseImageStyle.gradient,
                  name: 'Night',
                  color: const Color(0xFF1A1A2E),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption(
    BuildContext context, {
    required VerseImageStyle style,
    required String name,
    required Color color,
  }) {
    final isDark = color.computeLuminance() < 0.5;
    final deepLinkService = DeepLinkService();

    return GestureDetector(
      onTap: () async {
        // Show loading
        unawaited(
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          ),
        );

        try {
          await deepLinkService.shareVerseImage(
            verseText: verse.text,
            surahName: surah.nameEnglish,
            verseNumber: verse.verseNumber,
            context: context,
            translation: translation,
            style: style,
          );

          // Track verse sharing as image
          unawaited(
            sl<AnalyticsHelper>().logVerseShared(
              surah.id,
              verse.verseNumber,
              'share_image_${style.name}',
            ),
          );
        } finally {
          // Pop loading
          if (context.mounted) Navigator.pop(context);
          // Pop style picker
          if (context.mounted) Navigator.pop(context);
          // Pop share sheet
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: isDark ? Colors.white : Colors.black54),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to show the share sheet
extension VerseShareSheetExtension on BuildContext {
  void showVerseShareSheet({
    required Surah surah,
    required Verse verse,
    String? translation,
  }) {
    showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          VerseShareSheet(surah: surah, verse: verse, translation: translation),
    );
  }
}
