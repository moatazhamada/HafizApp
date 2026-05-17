import 'package:flutter/material.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/juz_index.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/utils/logger.dart';
import '../../../core/tracking/behavior_tracker.dart';
import '../../../injection_container.dart';
import '../../../core/utils/rtl_utils.dart';
import '../widgets/surah_index_widget.dart';
import '../widgets/staggered_list_item.dart';
import '../../../widgets/random_verse_card.dart';

class SeekerSurface extends StatefulWidget {
  const SeekerSurface({super.key});

  @override
  State<SeekerSurface> createState() => _SeekerSurfaceState();
}

class _SeekerSurfaceState extends State<SeekerSurface> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    setState(() => _recentSearches = PrefUtils().getRecentSearches());
  }

  void _onSearchTap() {
    BehaviorTracker.recordSession('search');
    sl<AnalyticsService>().logSearch('tap');
    NavigatorService.pushNamed(AppRoutes.searchPage);
  }

  void _onSearchChipTap(String query) {
    PrefUtils().addRecentSearch(query);
    sl<AnalyticsService>().logSearch(query);
    _loadRecentSearches();
    NavigatorService.pushNamed(
      AppRoutes.searchPage,
      arguments: {'query': query},
    );
  }

  void _clearRecentSearches() {
    PrefUtils().clearRecentSearches();
    _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final headerChildren = <Widget>[
      // Prominent Search
      StaggeredListItem(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Semantics(
            button: true,
            label: 'lbl_semantics_discovery_card'
                .tr
                .replaceAll('{title}', 'lbl_search_quran'.tr)
                .replaceAll('{subtitle}', 'msg_search_desc'.tr),
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
                    ExcludeSemantics(
                      child: Icon(
                        Icons.search_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
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
                    ExcludeSemantics(
                      child: Icon(
                        rtlForwardArrowRounded(context),
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Discovery Cards
      StaggeredListItem(
        index: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.wb_sunny_outlined,
                  title: 'lbl_verse_of_day'.tr,
                  subtitle: 'msg_verse_of_day_desc'.tr,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => _showVerseOfDay(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.auto_stories_outlined,
                  title: 'lbl_todays_juz'.tr,
                  subtitle: _todayJuzLabel(isArabic),
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _navigateToTodayJuz(context),
                ),
              ),
            ],
          ),
        ),
      ),

      // Widget Promo
      if (!PrefUtils().hasDismissedWidgetPromo())
        StaggeredListItem(
          index: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _WidgetPromoCard(
              onDismiss: () => setState(() {}),
            ),
          ),
        ),

      // Recent Searches
      if (_recentSearches.isNotEmpty)
        StaggeredListItem(
          index: 2,
          child: Padding(
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
                  onPressed: _clearRecentSearches,
                  child: Text('lbl_clear'.tr),
                ),
              ],
            ),
          ),
        ),
      if (_recentSearches.isNotEmpty)
        StaggeredListItem(
          index: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((q) => _SearchChip(
                        label: q,
                        onTap: () => _onSearchChipTap(q),
                      ))
                  .toList(),
            ),
          ),
        ),
      if (_recentSearches.isEmpty)
        StaggeredListItem(
          index: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SearchChip(
                  label: 'الرحمة',
                  onTap: () => _onSearchChipTap('الرحمة'),
                ),
                _SearchChip(
                  label: 'mercy',
                  onTap: () => _onSearchChipTap('mercy'),
                ),
                _SearchChip(
                  label: 'الصيام',
                  onTap: () => _onSearchChipTap('الصيام'),
                ),
                _SearchChip(
                  label: 'patience',
                  onTap: () => _onSearchChipTap('patience'),
                ),
              ],
            ),
          ),
        ),

      // Quran Reflect Community
      StaggeredListItem(
        index: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _DiscoveryCard(
            icon: Icons.forum_outlined,
            title: 'lbl_quran_reflect'.tr,
            subtitle: 'msg_quran_reflect_desc'.tr,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => NavigatorService.pushNamed(
              AppRoutes.quranReflectFeed,
            ),
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
      searchQuery: _searchQuery,
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

  String _todayJuzLabel(bool isArabic) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
    final juz = ((dayOfYear - 1) % 30) + 1;
    return isArabic ? 'الجزء $juz' : 'Juz $juz';
  }

  void _showVerseOfDay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: const RandomVerseCard(),
          );
        },
      ),
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
          orElse: () {
            Logger.warning('Invalid surahId: ${juzInfo.startSurahId}', feature: 'Seeker');
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

class _WidgetPromoCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const _WidgetPromoCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.widgets_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'lbl_close'.tr,
                  child: InkWell(
                    onTap: () {
                      PrefUtils().dismissWidgetPromo();
                      onDismiss();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'lbl_home_widget'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'msg_home_widget_desc'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  _showWidgetAddDialog(context);
                  PrefUtils().dismissWidgetPromo();
                  onDismiss();
                },
                child: Text('lbl_add_widget'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWidgetAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lbl_add_widget'.tr),
        content: Text('msg_widget_added'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('lbl_got_it'.tr),
          ),
        ],
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SearchChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.history, size: 16),
      label: Text(label),
      onPressed: onTap ?? () => NavigatorService.pushNamed(AppRoutes.searchPage),
    );
  }
}
