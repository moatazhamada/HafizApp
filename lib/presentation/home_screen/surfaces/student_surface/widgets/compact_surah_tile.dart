import 'package:flutter/material.dart';
import '../../../../../../core/app_export.dart';
import '../../../../../../core/quran_index/quran_surah.dart';
import '../../../../../../core/quran_index/mushaf_types.dart';

class CompactSurahTile extends StatelessWidget {
  final Surah surah;

  const CompactSurahTile({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Semantics(
      button: true,
      label:
          '${surah.nameEnglish}, ${surah.nameArabic}, ${'lbl_surah'.tr} ${surah.id}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () {
            PrefUtils().saveLastReadSurah(surah);
            final defaultView = PrefUtils().getDefaultQuranView();
            if (defaultView == 'mushaf') {
              final type = MushafType.fromString(PrefUtils().getMushafType());
              final page = type.getSurahStartPage(surah.id);
              NavigatorService.pushNamed(
                AppRoutes.mushafScreen,
                arguments: {'initialPage': page},
              );
            } else {
              NavigatorService.pushNamed(AppRoutes.surahPage, arguments: surah);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: isArabic
                  ? [
                      Text(
                        surah.nameArabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'NotoNaskhArabic',
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${surah.id}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  : [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${surah.id}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          surah.nameEnglish,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        surah.nameArabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'NotoNaskhArabic',
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
