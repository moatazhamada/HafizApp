import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/juz_index.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/utils/rtl_utils.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/surah_index_widget.dart';
import '../../../widgets/random_verse_card.dart';
import '../../../core/utils/bottom_sheet_utils.dart';

class DevoteeSurface extends StatefulWidget {
  const DevoteeSurface({super.key});

  @override
  State<DevoteeSurface> createState() => _DevoteeSurfaceState();
}

class _DevoteeSurfaceState extends State<DevoteeSurface> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final headerChildren = <Widget>[
      // Daily Devotion Banner
      StaggeredListItem(
        index: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _DailyDevotionCard(
            isArabic: isArabic,
            onTap: () => _navigateToTodayJuz(context),
          ),
        ),
      ),

      // Discovery Cards Row
      StaggeredListItem(
        index: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.wb_sunny_outlined,
                  title: 'lbl_verse_of_day'.tr,
                  subtitle: 'msg_verse_of_day_desc'.tr,
                  color: colorScheme.secondary,
                  onTap: () => _showVerseOfDay(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'lbl_streak'.tr,
                  subtitle: 'msg_streak_desc'.tr,
                  color: colorScheme.tertiary,
                  onTap: () => NavigatorService.pushNamed(AppRoutes.statisticsScreen),
                ),
              ),
            ],
          ),
        ),
      ),

      // Khatmah Progress
      StaggeredListItem(
        index: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _KhatmahCard(
            onTap: () => NavigatorService.pushNamed(AppRoutes.khatmahPage),
          ),
        ),
      ),

      const SizedBox(height: 8),

      // Surah Index Section
      StaggeredListItem(
        index: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'lbl_surah'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return SurahIndexWidget(
      pageStorageKey: 'devotee-scroll',
      headerSlivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: headerChildren,
          ),
        ),
      ],
    );
  }

  void _showVerseOfDay(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useDraggable: true,
      initialSize: 0.6,
      minSize: 0.4,
      maxSize: 0.85,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: const RandomVerseCard(),
        );
      },
    );
  }

  void _navigateToTodayJuz(BuildContext context) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
    final juzNumber = ((dayOfYear - 1) % 30) + 1;
    final juzInfo = JuzIndex.getJuz(juzNumber);
    if (juzInfo != null) {
      final surah = QuranIndex.quranSurahs.firstWhere(
        (s) => s.id == juzInfo.startSurahId,
          orElse: () {
            Logger.warning('Invalid surahId: ${juzInfo.startSurahId}', feature: 'Devotee');
            return Surah(juzInfo.startSurahId, 'Surah ${juzInfo.startSurahId}', 'سورة ${juzInfo.startSurahId}');
          },
      );
      NavigatorService.pushNamed(
        AppRoutes.surahPage,
        arguments: {
          'surah': surah,
          'verseIndex': juzInfo.startVerseNumber - 1,
        },
      );
    }
  }
}

class _DailyDevotionCard extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onTap;

  const _DailyDevotionCard({required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
    final juzNumber = ((dayOfYear - 1) % 30) + 1;
    final juzLabel = isArabic ? 'الجزء $juzNumber' : 'Juz $juzNumber';

    return Semantics(
      button: true,
      label: 'lbl_semantics_discovery_card'
          .tr
          .replaceAll('{title}', 'lbl_todays_reading'.tr)
          .replaceAll('{subtitle}', juzLabel),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.15),
              colorScheme.secondary.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        juzLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'lbl_todays_reading'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'msg_todays_reading_desc'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'lbl_continue_reading'.tr,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      rtlForwardArrowRounded(context),
                      color: colorScheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DiscoveryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'lbl_semantics_discovery_card'
          .tr
          .replaceAll('{title}', title)
          .replaceAll('{subtitle}', subtitle),
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KhatmahCard extends StatelessWidget {
  final VoidCallback onTap;

  const _KhatmahCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'lbl_semantics_discovery_card'
          .tr
          .replaceAll('{title}', 'lbl_khatmah'.tr)
          .replaceAll('{subtitle}', 'msg_khatmah_desc'.tr),
      child: Material(
        color: colorScheme.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flag_outlined,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lbl_khatmah'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'msg_khatmah_desc'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                rtlChevron(context),
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
