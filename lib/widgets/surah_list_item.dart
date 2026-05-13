import 'package:flutter/material.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';

class SurahListItem extends StatelessWidget {
  final int surahId;
  final String nameEnglish;
  final String nameArabic;

  const SurahListItem({
    super.key,
    required this.surahId,
    required this.nameEnglish,
    required this.nameArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '$nameEnglish, $nameArabic',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainer
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                // Number Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    surahId.toLocalizedNumber(context),
                    // Also localize Surah ID here!
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // English Name (Hide if Arabic)
                if (Localizations.localeOf(context).languageCode != 'ar') ...[
                  Expanded(
                    child: Text(
                      nameEnglish,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(width: 16),
                ] else
                  const Spacer(), // Push Arabic to right if English is hidden
                // Arabic Name
                Hero(
                  tag: 'surah-title-$surahId',
                  child: Text(
                    nameArabic,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'NotoNaskhArabic',
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
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
