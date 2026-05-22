import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

class StartTrackingSheet extends StatelessWidget {
  final ScrollController scrollController;
  final ValueChanged<int> onSurahSelected;

  const StartTrackingSheet({
    super.key,
    required this.scrollController,
    required this.onSurahSelected,
  });

  @override
  Widget build(BuildContext context) {
    final surahs = QuranIndex.quranSurahs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'lbl_select_surahs_to_track'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${surah.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Localizations.localeOf(context).languageCode != 'ar'
                    ? Text(
                        surah.nameEnglish,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.of(context).textSecondary,
                        ),
                      )
                    : null,
                onTap: () => onSurahSelected(surah.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
