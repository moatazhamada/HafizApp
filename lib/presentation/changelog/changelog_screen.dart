import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('lbl_whats_new'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _VersionCard(
            version: '3.1.0',
            isLatest: true,
            items: [
              'Complete migration to Uthmani Rasm script — matching the standard Mushaf writing.',
              'New Noto Naskh Arabic font for accurate rendering of superscript characters.',
              'Improved line height to prevent clipping of diacritical marks.',
              'Verse Study screen — explore Arabic text, translation, and tafsir together.',
              'Quran Foundation Content API integration for tafsir and verse data.',
              'Quran Foundation Bookmarks sync — sync your bookmarks with Quran.com.',
              'Force update mechanism for critical text accuracy fixes.',
            ],
          ),
          const SizedBox(height: 16),
          const _VersionCard(
            version: '3.0.0',
            isLatest: false,
            items: [
              'Complete app redesign with Material 3.',
              'Cloud sync with Firebase.',
              'Audio player with reciter support.',
              'Mushaf page view with verse rendering.',
              'Voice verification for recitation practice.',
              'Memorization and Khatmah tracking.',
              'Statistics dashboard.',
              'Auto-scroll with configurable speed.',
            ],
          ),
          const SizedBox(height: 24),
          _SpecialThanksCard(theme: theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String version;
  final bool isLatest;
  final List<String> items;

  const _VersionCard({
    required this.version,
    required this.isLatest,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isLatest ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLatest
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Version $version',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLatest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Latest',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8, left: 8),
                      child: Icon(
                        isLatest ? Icons.check_circle : Icons.circle,
                        size: isLatest ? 12 : 6,
                        color: isLatest
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: Text(item, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpecialThanksCard extends StatelessWidget {
  final ThemeData theme;

  const _SpecialThanksCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Special Thanks',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                children: [
                  const TextSpan(text: 'Special thanks to our user '),
                  TextSpan(
                    text: 'HASBUL HSB',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' for his precise feedback on Surah Yasin (36:26), '
                        'which led to this Uthmani Rasm script improvement. '
                        'May Allah reward him.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
