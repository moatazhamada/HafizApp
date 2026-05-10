import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('lbl_whats_new'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _VersionCard(
            version: '3.1.0',
            isLatest: true,
            itemKeys: [
              'changelog_3_1_0_1',
              'changelog_3_1_0_2',
              'changelog_3_1_0_3',
              'changelog_3_1_0_4',
              'changelog_3_1_0_5',
              'changelog_3_1_0_6',
              'changelog_3_1_0_7',
            ],
          ),
          SizedBox(height: 16),
          _VersionCard(
            version: '3.0.0',
            isLatest: false,
            itemKeys: [
              'changelog_3_0_0_1',
              'changelog_3_0_0_2',
              'changelog_3_0_0_3',
              'changelog_3_0_0_4',
              'changelog_3_0_0_5',
              'changelog_3_0_0_6',
              'changelog_3_0_0_7',
              'changelog_3_0_0_8',
            ],
          ),
          SizedBox(height: 24),
          _SpecialThanksCard(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String version;
  final bool isLatest;
  final List<String> itemKeys;

  const _VersionCard({
    required this.version,
    required this.isLatest,
    required this.itemKeys,
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
                  '${'lbl_version'.tr} $version',
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
                      'lbl_latest'.tr,
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
            for (final key in itemKeys)
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
                      child: Text(key.tr, style: theme.textTheme.bodyMedium),
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
  const _SpecialThanksCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  'lbl_special_thanks'.tr,
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
                  TextSpan(text: 'changelog_3_1_0_intro'.tr),
                  TextSpan(
                    text: 'changelog_3_1_0_user'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextSpan(text: 'changelog_3_1_0_outro'.tr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
