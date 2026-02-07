import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/app_export.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../domain/entities/verse.dart';
import '../../injection_container.dart';
import '../surah_screen/bloc/surah_bloc.dart';
import '../../core/utils/number_converter.dart';

/// Full Mushaf View - Continuous scroll through all 604 pages
/// Mimics reading from a physical Madani Mushaf
class MushafScreen extends StatefulWidget {
  final int? initialPage;
  final int? highlightSurah;
  final int? highlightVerse;

  const MushafScreen({
    super.key,
    this.initialPage,
    this.highlightSurah,
    this.highlightVerse,
  });

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();
  final SurahBloc _surahBloc = sl<SurahBloc>();

  // Cache for loaded Surah verses
  final Map<int, List<Verse>> _surahCache = {};

  int _currentPage = 1;
  bool _showPageIndicator = true;
  Timer? _pageIndicatorTimer;
  bool _isLoading = true;

  // Track visible pages for efficient loading
  final Set<int> _loadedSurahs = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? 1;
    _loadInitialData();

    // Listen to scroll position
    _positionsListener.itemPositions.addListener(_onScrollPositionChanged);

    // Auto-hide page indicator
    _resetPageIndicatorTimer();
  }

  Future<void> _loadInitialData() async {
    // Pre-load some Surahs around the initial page
    final initialPage = MushafPageIndex.getPage(_currentPage);
    if (initialPage != null) {
      await _loadSurah(initialPage.surahId);
    }

    setState(() => _isLoading = false);

    // Scroll to initial page after build
    if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPage(widget.initialPage!);
      });
    }
  }

  Future<void> _loadSurah(int surahId) async {
    if (_loadedSurahs.contains(surahId)) return;

    _surahBloc.add(LoadSurahEvent(surahId: surahId.toString()));
    // Wait for the bloc to emit state
    await for (final state in _surahBloc.stream) {
      if (state is SuccessSurahState) {
        _surahCache[surahId] = state.chapters;
        _loadedSurahs.add(surahId);
        break;
      }
    }
  }

  void _onScrollPositionChanged() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Get the most visible page
    final mostVisible = positions
        .where((p) => p.itemLeadingEdge < 1 && p.itemTrailingEdge > 0)
        .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);

    final page = mostVisible.index + 1;
    if (page != _currentPage &&
        page >= 1 &&
        page <= MushafPageIndex.totalPages) {
      setState(() => _currentPage = page);
      _resetPageIndicatorTimer();

      // Load upcoming Surahs
      final currentPageData = MushafPageIndex.getPage(page);
      if (currentPageData != null) {
        _loadSurah(currentPageData.surahId);
        // Preload next Surah if we're near the end
        if (currentPageData.endVerse >= currentPageData.endVerse - 5) {
          _loadSurah(currentPageData.surahId + 1);
        }
      }
    }
  }

  void _resetPageIndicatorTimer() {
    setState(() => _showPageIndicator = true);
    _pageIndicatorTimer?.cancel();
    _pageIndicatorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showPageIndicator = false);
      }
    });
  }

  void _scrollToPage(int page) {
    if (page >= 1 && page <= MushafPageIndex.totalPages) {
      _scrollController.scrollTo(
        index: page - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lbl_jump_to_page'.tr),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1 - ${MushafPageIndex.totalPages}',
            border: OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lbl_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                _scrollToPage(page);
                Navigator.pop(context);
              }
            },
            child: Text('lbl_go'.tr),
          ),
        ],
      ),
    );
  }

  void _showBookmarkDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lbl_bookmark_page'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'msg_bookmark_current_page'.tr.replaceAll(
                '{page}',
                _currentPage.toString(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: 'lbl_optional_note'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lbl_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              _savePageBookmark(noteController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('msg_page_bookmarked'.tr)));
            },
            child: Text('lbl_save'.tr),
          ),
        ],
      ),
    );
  }

  void _savePageBookmark(String note) {
    final pageData = MushafPageIndex.getPage(_currentPage);
    if (pageData != null) {
      // Save to preferences
      PrefUtils().setString(
        'mushaf_bookmark_$_currentPage',
        '${DateTime.now().millisecondsSinceEpoch}|$note',
      );

      // Also save to bookmarks list
      final bookmarks = PrefUtils().getStringList('mushaf_bookmarks') ?? [];
      bookmarks.add(_currentPage.toString());
      PrefUtils().setStringList('mushaf_bookmarks', bookmarks);
    }
  }

  @override
  void dispose() {
    _pageIndicatorTimer?.cancel();
    _positionsListener.itemPositions.removeListener(_onScrollPositionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F0E6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('lbl_mushaf'.tr),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _showBookmarkDialog,
            tooltip: 'lbl_bookmark_page'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.pageview),
            onPressed: _showPageJumpDialog,
            tooltip: 'lbl_jump_to_page'.tr,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'bookmarks':
                  _showMushafBookmarks();
                  break;
                case 'settings':
                  _showMushafSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'bookmarks',
                child: Row(
                  children: [
                    const Icon(Icons.bookmarks_outlined),
                    const SizedBox(width: 8),
                    Text('lbl_mushaf_bookmarks'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined),
                    const SizedBox(width: 8),
                    Text('lbl_display_settings'.tr),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ScrollablePositionedList.builder(
              itemCount: MushafPageIndex.totalPages,
              itemScrollController: _scrollController,
              itemPositionsListener: _positionsListener,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                return _buildMushafPage(pageNumber, isDark);
              },
            ),

          // Page number indicator
          AnimatedOpacity(
            opacity: _showPageIndicator ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black87 : Colors.white70,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  _currentPage.toLocalizedNumber(context),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMushafPage(int pageNumber, bool isDark) {
    final pageData = MushafPageIndex.getPage(pageNumber);
    if (pageData == null) return const SizedBox.shrink();

    final verses = _surahCache[pageData.surahId];
    if (verses == null) {
      // Show loading placeholder
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    // Filter verses for this page
    final pageVerses = verses
        .where(
          (v) =>
              v.verseNumber >= pageData.startVerse &&
              v.verseNumber <= pageData.endVerse,
        )
        .toList();

    final isSurahStart = pageData.isSurahStart;
    final showBismillah = pageData.containsBismillah;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : const Color(0xFFFEFDF5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Surah header for first page of Surah
          if (isSurahStart) ...[
            _buildSurahHeader(pageData, isDark),
            const Divider(height: 1),
          ],

          // Page content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Bismillah
                  if (showBismillah) _buildBismillah(isDark),

                  // Verses
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: _buildPageVerses(
                        pageVerses,
                        pageData.surahId,
                        isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Page footer
          _buildPageFooter(pageNumber, isDark),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(MushafPageIndex pageData, bool isDark) {
    final surah = QuranIndex.quranSurahs.firstWhere(
      (s) => s.id == pageData.surahId,
      orElse: () => QuranIndex.quranSurahs[0],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A35), const Color(0xFF0B2D28)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        ),
      ),
      child: Column(
        children: [
          // Ornate header decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOrnament(isDark),
              const SizedBox(width: 16),
              Text(
                surah.nameArabic,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF006754),
                ),
              ),
              const SizedBox(width: 16),
              _buildOrnament(isDark, mirror: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.nameEnglish} • ${surah.verseCount} ${'lbl_verses'.tr}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrnament(bool isDark, {bool mirror = false}) {
    final color = isDark ? Colors.teal[400]! : const Color(0xFF006754);
    return Transform.scale(
      scaleX: mirror ? -1 : 1,
      child: Icon(Icons.mosque_outlined, color: color, size: 20),
    );
  }

  Widget _buildBismillah(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
        ),
      ),
    );
  }

  Widget _buildPageVerses(List<Verse> verses, int surahId, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF004B40);

    // Build continuous text with verse markers
    final spans = <InlineSpan>[];

    for (final verse in verses) {
      // Check if this verse should be highlighted
      final isHighlighted =
          widget.highlightSurah == surahId &&
          widget.highlightVerse == verse.verseNumber;

      spans.add(
        TextSpan(
          text: verse.text,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 2.2,
            color: isHighlighted ? Colors.teal : textColor,
            backgroundColor: isHighlighted
                ? (isDark
                      ? Colors.teal.withValues(alpha: 0.2)
                      : Colors.teal.withValues(alpha: 0.1))
                : null,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );

      // Verse end marker
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF87D1A4)
                    : const Color(0xFF006754),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              verse.verseNumber.toLocalizedNumber(context),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF87D1A4)
                    : const Color(0xFF006754),
              ),
            ),
          ),
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildPageFooter(int pageNumber, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Juz indicator (simplified - would need actual Juz data)
          Text(
            'Juz ${((pageNumber - 1) ~/ 20 + 1).toLocalizedNumber(context)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),

          // Page number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pageNumber.toLocalizedNumber(context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMushafBookmarks() {
    final bookmarks = PrefUtils().getStringList('mushaf_bookmarks') ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'lbl_mushaf_bookmarks'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (bookmarks.isEmpty)
              Center(
                child: Text(
                  'msg_no_bookmarks'.tr,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final page = int.parse(bookmarks[index]);
                    final pageData = MushafPageIndex.getPage(page);

                    return ListTile(
                      leading: CircleAvatar(child: Text(page.toString())),
                      title: Text(pageData?.surahNameAr ?? ''),
                      subtitle: Text('Page $page'),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollToPage(page);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          bookmarks.removeAt(index);
                          PrefUtils().setStringList(
                            'mushaf_bookmarks',
                            bookmarks,
                          );
                          Navigator.pop(context);
                          _showMushafBookmarks();
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMushafSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'lbl_display_settings'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text('lbl_font_size'.tr),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      // Decrease font size
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Increase font size
                    },
                  ),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.light_mode),
              title: Text('lbl_show_page_borders'.tr),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
}
