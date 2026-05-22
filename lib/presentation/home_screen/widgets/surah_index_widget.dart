import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/juz_index.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/quran_index/mushaf_types.dart';
import '../../../core/tracking/behavior_tracker.dart';
import '../../../widgets/surah_list_item.dart';
import 'staggered_list_item.dart';

class SurahIndexWidget extends StatelessWidget {
  final String? searchQuery;
  final ScrollController? scrollController;
  final VoidCallback? onSurahTap;
  /// Optional sliver widgets to insert before the surah list.
  /// Useful when the entire screen (headers + list) should scroll together.
  final List<Widget>? headerSlivers;
  /// Optional page storage key for scroll position restoration.
  /// When null, no PageStorageKey is applied. Callers that manage
  /// their own scroll state (e.g. via ScrollController) should leave this null.
  final String? pageStorageKey;

  const SurahIndexWidget({
    super.key,
    this.searchQuery,
    this.scrollController,
    this.onSurahTap,
    this.headerSlivers,
    this.pageStorageKey,
  });

  List<_SurahListEntry> _buildEntries() {
    final entries = <_SurahListEntry>[];
    final surahs = QuranIndex.quranSurahs;
    final juzList = JuzIndex.allJuz;
    int juzIndex = 0;

    for (int i = 0; i < surahs.length; i++) {
      final surah = surahs[i];

      // Check if this surah starts a new Juz
      while (juzIndex < juzList.length && juzList[juzIndex].startSurahId == surah.id) {
        entries.add(_SurahListEntry.juz(juzList[juzIndex]));
        juzIndex++;
      }

      entries.add(_SurahListEntry.surah(surah));
    }

    return entries;
  }

  List<_SurahListEntry> _filterEntries(List<_SurahListEntry> entries) {
    if (searchQuery == null || searchQuery!.trim().isEmpty) return entries;
    final query = searchQuery!.trim().toLowerCase();

    // First, find which surahs match
    final matchingSurahIds = <int>{};
    for (final entry in entries) {
      if (entry.isSurah) {
        final s = entry.surah!;
        if (s.nameEnglish.toLowerCase().contains(query) ||
            s.nameArabic.contains(query) ||
            s.id.toString() == query) {
          matchingSurahIds.add(s.id);
        }
      }
    }

    // Rebuild entries: include Juz headers only if they have matching surahs after them
    final filtered = <_SurahListEntry>[];
    bool hasMatchAhead = false;

    for (int i = entries.length - 1; i >= 0; i--) {
      final entry = entries[i];
      if (entry.isSurah && matchingSurahIds.contains(entry.surah!.id)) {
        hasMatchAhead = true;
      }
      if (entry.isJuz) {
        if (hasMatchAhead) {
          filtered.insert(0, entry);
        }
        hasMatchAhead = false;
      } else if (matchingSurahIds.contains(entry.surah!.id)) {
        filtered.insert(0, entry);
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filterEntries(_buildEntries());
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return CustomScrollView(
      controller: scrollController,
      key: pageStorageKey != null ? PageStorageKey(pageStorageKey) : null,
      slivers: [
        if (headerSlivers != null) ...headerSlivers!,
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];

            final widget = entry.isJuz
                ? _JuzHeader(
                    juz: entry.juz!,
                    isArabic: isArabic,
                  )
                : _buildSurahItem(context, entry.surah!);

            return StaggeredSliverListItem(
              index: index,
              child: widget,
            );
          },
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildSurahItem(BuildContext context, Surah surah) {
    return Semantics(
      button: true,
      label:
          '${surah.nameEnglish}, ${surah.nameArabic}, ${'lbl_surah'.tr} ${surah.id}',
      child: InkWell(
        onTap: onSurahTap != null
            ? () => onSurahTap!()
            : () => _navigateToSurah(context, surah),
        child: SurahListItem(
          surahId: surah.id,
          nameEnglish: surah.nameEnglish,
          nameArabic: surah.nameArabic,
        ),
      ),
    );
  }

  void _navigateToSurah(BuildContext context, Surah surah) {
    BehaviorTracker.recordSession('read');
    PrefUtils().saveLastReadSurah(surah);
    // Notify home bloc about last read update if needed
    final defaultView = PrefUtils().getDefaultQuranView();
    if (defaultView == 'mushaf') {
      final type = MushafType.fromString(PrefUtils().getMushafType());
      final page = type.getSurahStartPage(surah.id);
      NavigatorService.pushNamed(
        AppRoutes.mushafScreen,
        arguments: {'initialPage': page},
      );
    } else {
      NavigatorService.pushNamed(
        AppRoutes.surahPage,
        arguments: surah,
      );
    }
  }
}

class _JuzHeader extends StatelessWidget {
  final JuzInfo juz;
  final bool isArabic;

  const _JuzHeader({required this.juz, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 20, end: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              JuzIndex.getJuzName(juz.juzNumber, isArabic: isArabic),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: TextAlign.start,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahListEntry {
  final JuzInfo? juz;
  final Surah? surah;

  bool get isJuz => juz != null;
  bool get isSurah => surah != null;

  _SurahListEntry.juz(this.juz) : surah = null;
  _SurahListEntry.surah(this.surah) : juz = null;
}
