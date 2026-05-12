import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/juz_index.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/tracking/behavior_tracker.dart';
import '../widgets/surah_index_widget.dart';

class SeekerSurface extends StatefulWidget {
  const SeekerSurface({super.key});

  @override
  State<SeekerSurface> createState() => _SeekerSurfaceState();
}

class _SeekerSurfaceState extends State<SeekerSurface> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTap() {
    BehaviorTracker.recordSession('search');
    NavigatorService.pushNamed(AppRoutes.searchPage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      children: [
        // Prominent Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GestureDetector(
            onTap: _onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'lbl_search_quran'.tr,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'msg_search_desc'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Discovery Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.wb_sunny_outlined,
                  title: 'lbl_verse_of_day'.tr,
                  subtitle: 'msg_verse_of_day_desc'.tr,
                  color: Colors.orange,
                  onTap: () => _showVerseOfDay(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.auto_stories_outlined,
                  title: 'lbl_todays_juz'.tr,
                  subtitle: _todayJuzLabel(isArabic),
                  color: Colors.teal,
                  onTap: () => _navigateToTodayJuz(context),
                ),
              ),
            ],
          ),
        ),

        // Recent Searches (placeholder)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'lbl_recent'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('lbl_clear'.tr),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _SearchChip(label: 'الرحمة'),
              const _SearchChip(label: 'mercy'),
              const _SearchChip(label: 'الصيام'),
              const _SearchChip(label: 'patience'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Surah Index Section
        Padding(
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

        Expanded(
          child: SurahIndexWidget(
            searchQuery: _searchQuery,
          ),
        ),
      ],
    );
  }

  String _todayJuzLabel(bool isArabic) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
    final juz = ((dayOfYear - 1) % 30) + 1;
    return isArabic ? 'الجزء $juz' : 'Juz $juz';
  }

  void _showVerseOfDay(BuildContext context) {
    // Placeholder: will show a daily verse dialog or navigate to verse study
    final random = DateTime.now().day;
    final surahId = (random % 114) + 1;
    final surah = QuranIndex.quranSurahs.firstWhere((s) => s.id == surahId);
    NavigatorService.pushNamed(
      AppRoutes.surahPage,
      arguments: surah,
    );
  }

  void _navigateToTodayJuz(BuildContext context) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
    final juzNumber = ((dayOfYear - 1) % 30) + 1;
    // Navigate to the starting surah of today's juz
    final juzInfo = JuzIndex.getJuz(juzNumber);
    if (juzInfo != null) {
      final surah = QuranIndex.quranSurahs.firstWhere(
        (s) => s.id == juzInfo.startSurahId,
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
    return Material(
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
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;

  const _SearchChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.history, size: 16),
      label: Text(label),
      onPressed: () => NavigatorService.pushNamed(AppRoutes.searchPage),
    );
  }
}
