import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

/// Quran navigation bar that always follows RTL semantics:
/// Next surah is on the left, previous surah is on the right.
///
/// The Quran is an RTL book — users turn left pages to advance
/// and right pages to go back, regardless of the app's UI language.
class SurahNavigationBar extends StatelessWidget {
  final Surah surah;
  final void Function(int surahId) onNavigate;

  const SurahNavigationBar({
    super.key,
    required this.surah,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasPrev = surah.id > 1;
    final hasNext = surah.id < 114;
    final prevSurah = hasPrev ? QuranIndex.quranSurahs[surah.id - 2] : null;
    final nextSurah = hasNext ? QuranIndex.quranSurahs[surah.id] : null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        // Force RTL layout for Quran navigation regardless of UI locale.
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (rtlContext) {
              return Row(
                children: [
                  // Previous Surah (spatially right in a physical Quran)
                  if (hasPrev)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label:
                            '${'lbl_previous_surah'.tr}: ${isArabic ? prevSurah!.nameArabic : prevSurah!.nameEnglish}',
                        child: TextButton(
                          onPressed: () => onNavigate(surah.id - 1),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chevron_left, size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  isArabic
                                      ? prevSurah.nameArabic
                                      : prevSurah.nameEnglish,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                  const SizedBox(width: 8),
                  // Next Surah (spatially left in a physical Quran)
                  if (hasNext)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label:
                            '${'lbl_next_surah'.tr}: ${isArabic ? nextSurah!.nameArabic : nextSurah!.nameEnglish}',
                        child: TextButton(
                          onPressed: () => onNavigate(surah.id + 1),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isArabic
                                      ? nextSurah.nameArabic
                                      : nextSurah.nameEnglish,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
