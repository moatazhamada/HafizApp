import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/scroll/scroll_position_cubit.dart';
import '../../../injection_container.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/surah_index_widget.dart';
import '../widgets/staggered_list_item.dart';

class ReaderSurface extends StatefulWidget {
  final Surah? lastReadSurah;
  final int? lastVerseIndex;

  const ReaderSurface({
    super.key,
    this.lastReadSurah,
    this.lastVerseIndex,
  });

  @override
  State<ReaderSurface> createState() => _ReaderSurfaceState();
}

class _ReaderSurfaceState extends State<ReaderSurface> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saved = sl<ScrollPositionCubit>().getOffset('home');
      if (saved != null && _scrollController.hasClients) {
        try {
          _scrollController.jumpTo(saved);
        } catch (e) {
          Logger.warning('Scroll position restore failed: $e', feature: 'Home');
        }
      }
    });
    _scrollController.addListener(() {
      sl<ScrollPositionCubit>().saveOffset('home', _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onContinueReading() {
    if (widget.lastReadSurah == null) return;
    final surah = widget.lastReadSurah!;
    PrefUtils().saveLastReadSurah(surah);

    final offset = PrefUtils().getSurahOffset(surah.id) ??
        sl<ScrollPositionCubit>().getOffset('surah-${surah.id}');

    final defaultView = PrefUtils().getDefaultQuranView();
    if (defaultView == 'mushaf') {
      NavigatorService.pushNamed(
        AppRoutes.mushafScreen,
        arguments: {
          'initialPage': 0,
        },
      );
    } else {
      NavigatorService.pushNamed(
        AppRoutes.surahPage,
        arguments: {
          'surah': surah,
          'offset': offset,
          'verseIndex': widget.lastVerseIndex,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Search Bar
        StaggeredListItem(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: 'lbl_search_surah'.tr,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                ),
                suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),

        // Continue Reading Card
        if (widget.lastReadSurah != null)
          StaggeredListItem(
            index: 1,
            child: ContinueReadingCard(
              surah: widget.lastReadSurah,
              lastVerseIndex: widget.lastVerseIndex,
              onContinue: _onContinueReading,
            ),
          ),

        // Surah Index
        Expanded(
          child: SurahIndexWidget(
            searchQuery: _searchQuery,
            scrollController: _scrollController,
          ),
        ),
      ],
    );
  }
}
