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
        arguments: {},
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
    return Column(
      children: [
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
            scrollController: _scrollController,
          ),
        ),
      ],
    );
  }
}
