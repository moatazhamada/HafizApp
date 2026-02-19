import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_export.dart';
import '../../core/analytics/analytics_helper.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/mushaf_types.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../domain/entities/verse.dart';
import '../../injection_container.dart';
import '../surah_screen/bloc/surah_bloc.dart';
import '../../core/utils/number_converter.dart';
import 'widgets/mushaf_page_skeleton.dart';
import '../../widgets/verse_share_sheet.dart';
import '../../core/audio/recitation_service.dart';
import '../../core/audio/recitation_models.dart';
import '../surah_screen/voice_verification_service.dart';
import '../surah_screen/widgets/voice_verification_dialog.dart';

/// Full Mushaf View - Horizontal page turning (RTL) like a real Quran
/// Supports multiple Mushaf types (Madani, Indo-Pak, Warsh)
class MushafScreen extends StatefulWidget {
  final int? initialPage;
  final int? highlightSurah;
  final int? highlightVerse;
  final MushafType mushafType;

  const MushafScreen({
    super.key,
    this.initialPage,
    this.highlightSurah,
    this.highlightVerse,
    this.mushafType = MushafType.madani,
  });

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  final SurahBloc _surahBloc = sl<SurahBloc>();
  final RecitationService _recitationService = RecitationService();
  final VoiceVerificationService _voiceService = VoiceVerificationService();

  // Cache for loaded Surah verses
  final Map<int, List<Verse>> _surahCache = {};

  int _currentPage = 1;
  bool _showPageIndicator = true;
  Timer? _pageIndicatorTimer;
  late MushafType _currentMushafType;

  // Track visible pages for efficient loading
  final Set<int> _loadedSurahs = {};

  // Track practice list (recitation errors) for current surahs on page
  Set<String> _practiceListKeys = {};

  @override
  void initState() {
    super.initState();
    _currentMushafType = widget.mushafType;

    // Determine initial page: use provided page, or find page from surah/verse
    int initialPageNumber = widget.initialPage ?? 1;
    if (widget.initialPage == null && widget.highlightSurah != null) {
      // Find page for the specified surah and verse
      final page = MushafPageIndex.findPageForVerse(
        widget.highlightSurah!,
        widget.highlightVerse ?? 1,
      );
      if (page != null) {
        initialPageNumber = page;
      }
    }
    _currentPage = initialPageNumber;

    // For RTL Mushaf, initialize PageController with the correct initial page
    final totalPages = _currentMushafType.totalPages;
    final initialPageIndex = (totalPages - initialPageNumber).clamp(
      0,
      totalPages - 1,
    );
    _pageController = PageController(initialPage: initialPageIndex);

    // Load data in background without blocking UI
    unawaited(_loadInitialData());

    // Auto-hide page indicator
    _resetPageIndicatorTimer();

    // Set system UI for immersive reading
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  Future<void> _loadInitialData() async {
    await MushafPageIndex.loadPageDataFromAsset();

    // Pre-load some Surahs around the initial page in background
    unawaited(_loadPageSurahs(_currentPage));

    // Load practice list
    _loadPracticeList();
  }

  void _loadPracticeList() {
    final keys = PrefUtils().getStringList('recitation_errors') ?? [];
    setState(() {
      _practiceListKeys = Set<String>.from(keys);
    });
  }

  bool _isInPracticeList(int surahId, int verseNumber) {
    return _practiceListKeys.contains('${surahId}_$verseNumber');
  }

  Future<void> _loadPageSurahs(int pageNumber) async {
    final pageData = MushafPageIndex.getPage(pageNumber);
    if (pageData == null) return;
    for (
      int surahId = pageData.surahId;
      surahId <= pageData.endSurahId;
      surahId++
    ) {
      await _loadSurah(surahId);
    }
  }

  Future<void> _loadSurah(int surahId) async {
    if (_loadedSurahs.contains(surahId) || _surahCache.containsKey(surahId)) {
      return;
    }

    _surahBloc.add(LoadSurahEvent(surahId: surahId.toString()));

    try {
      final state = await _surahBloc.stream
          .firstWhere(
            (s) =>
                (s is SuccessSurahState &&
                    s.chapters.isNotEmpty &&
                    s.chapters.first.chapterId == surahId) ||
                (s is FailureSurahState),
          )
          .timeout(const Duration(seconds: 10));

      if (state is SuccessSurahState && mounted) {
        _surahCache[surahId] = state.chapters;
        _loadedSurahs.add(surahId);
        setState(() {});
      } else if (state is FailureSurahState) {
        debugPrint('Failed to load surah $surahId: ${state.errorMessage}');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading surah $surahId: $e');
      }
    }
  }

  void _onPageChanged(int pageIndex) {
    final page = _currentMushafType.totalPages - pageIndex;
    if (page != _currentPage &&
        page >= 1 &&
        page <= _currentMushafType.totalPages) {
      setState(() => _currentPage = page);
      _resetPageIndicatorTimer();

      // Track page navigation
      unawaited(
        sl<AnalyticsHelper>().logPageNavigated(
          page,
          _currentMushafType.prefsKey,
        ),
      );

      // Load upcoming Surahs
      final currentPageData = MushafPageIndex.getPage(page);
      if (currentPageData != null) {
        _loadPageSurahs(page);
        // Preload next Surah if we're near the end
        final surahInfo = QuranIndex.quranSurahs.firstWhere(
          (s) => s.id == currentPageData.endSurahId,
          orElse: () => QuranIndex.quranSurahs.first,
        );
        if (currentPageData.endVerse >= surahInfo.verseCount - 5 &&
            currentPageData.endSurahId < 114) {
          _loadSurah(currentPageData.endSurahId + 1);
        }
      }
    }
  }

  void _resetPageIndicatorTimer() {
    setState(() => _showPageIndicator = true);
    _pageIndicatorTimer?.cancel();
    _pageIndicatorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showPageIndicator = false);
      }
    });
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _currentMushafType.totalPages) {
      _pageController.jumpToPage(pageIndex);
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
          decoration: InputDecoration(
            hintText: '1 - ${_currentMushafType.totalPages}',
            border: const OutlineInputBorder(),
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
                // Adjust jump for RTL (reversed)
                final totalPages = _currentMushafType.totalPages;
                final targetIndex = totalPages - page;
                _jumpToPage(targetIndex);
                Navigator.pop(context);
              }
            },
            child: Text('lbl_go'.tr),
          ),
        ],
      ),
    );
  }

  void _showMushafTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'lbl_select_mushaf_type'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'msg_mushaf_type_desc'.tr,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ...allMushafTypes.map((type) => _buildMushafTypeOption(type)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafTypeOption(MushafType type) {
    final isSelected = type == _currentMushafType;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected
          ? Colors.teal.withValues(alpha: 0.1)
          : (isDark ? Colors.grey[800] : Colors.grey[100]),
      child: ListTile(
        leading: Icon(type.icon, color: isSelected ? Colors.teal : null),
        title: Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? type.displayName
              : type.displayNameEn,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : null,
            color: isSelected ? Colors.teal : null,
          ),
        ),
        subtitle: Text(
          '${type.totalPages} ${'lbl_pages'.tr}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.teal)
            : null,
        onTap: () {
          Navigator.pop(context);
          if (type != _currentMushafType) {
            _changeMushafType(type);
          }
        },
      ),
    );
  }

  void _changeMushafType(MushafType type) {
    setState(() {
      _currentMushafType = type;
      _currentPage = 1;
      _surahCache.clear();
      _loadedSurahs.clear();

      // Reinitialize PageController with page 1 (which is index total-1 in reversed RTL)
      _pageController.dispose();
      _pageController = PageController(initialPage: type.totalPages - 1);
    });

    // Save preference
    PrefUtils().setString('mushaf_type', type.prefsKey);

    // Track mushaf type change
    sl<AnalyticsHelper>().logMushafTypeChanged(type.prefsKey);

    // Reload data
    _loadInitialData();
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
      final key =
          'mushaf_bookmark_${_currentMushafType.prefsKey}_$_currentPage';
      PrefUtils().setString(
        key,
        '${DateTime.now().millisecondsSinceEpoch}|$note',
      );

      final bookmarks =
          PrefUtils().getStringList(
            'mushaf_bookmarks_${_currentMushafType.prefsKey}',
          ) ??
          [];
      if (!bookmarks.contains(_currentPage.toString())) {
        bookmarks.add(_currentPage.toString());
        PrefUtils().setStringList(
          'mushaf_bookmarks_${_currentMushafType.prefsKey}',
          bookmarks,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageIndicatorTimer?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Beige/cream background like real Mushaf paper
    final backgroundColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F0E6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_currentMushafType.icon, size: 20),
            const SizedBox(width: 8),
            Text('lbl_mushaf'.tr),
          ],
        ),
        centerTitle: true,
        actions: [
          // Mushaf type selector
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: _showMushafTypeSelector,
            tooltip: 'lbl_change_mushaf_type'.tr,
          ),
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
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // RTL PageView for authentic Mushaf experience
            // Always RTL regardless of app language - this is Arabic Quran
            // reverse: true makes swiping work correctly:
            // - Swipe RIGHT to LEFT = go to NEXT page (forward in Quran)
            // - Swipe LEFT to RIGHT = go to PREVIOUS page (backward in Quran)
            Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                reverse: true, // RTL: swipe left to go forward
                physics: const PageScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: _currentMushafType.totalPages,
                itemBuilder: (context, index) {
                  final pageNumber = _currentMushafType.totalPages - index;
                  return _buildMushafPage(pageNumber, isDark);
                },
              ),
            ),

            // Page number indicator
            AnimatedOpacity(
              opacity: _showPageIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                    '${_currentPage.toLocalizedNumber(context)} / ${_currentMushafType.totalPages.toLocalizedNumber(context)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafPage(int pageNumber, bool isDark) {
    final pageData = MushafPageIndex.getPage(pageNumber);
    if (pageData == null) return const SizedBox.shrink();

    // Group verses by Surah
    final surahVerses = <int, List<_PageVerseEntry>>{};
    final surahIds = <int>[];

    for (
      int surahId = pageData.surahId;
      surahId <= pageData.endSurahId;
      surahId++
    ) {
      final verses = _surahCache[surahId];
      if (verses == null) {
        // Trigger load if not in cache
        _loadSurah(surahId);
        return const MushafPageSkeleton();
      }
      final surahInfo = QuranIndex.quranSurahs.firstWhere(
        (s) => s.id == surahId,
        orElse: () => QuranIndex.quranSurahs.first,
      );
      final fromVerse = surahId == pageData.surahId ? pageData.startVerse : 1;
      final toVerse = surahId == pageData.endSurahId
          ? pageData.endVerse
          : surahInfo.verseCount;

      final pageVerses = <_PageVerseEntry>[];
      for (final verse in verses) {
        if (verse.verseNumber >= fromVerse && verse.verseNumber <= toVerse) {
          pageVerses.add(_PageVerseEntry(surahId: surahId, verse: verse));
        }
      }

      if (pageVerses.isNotEmpty) {
        surahVerses[surahId] = pageVerses;
        surahIds.add(surahId);
      }
    }

    // Page styling based on Mushaf type
    final pageStyle = _getPageStyle(isDark);

    // Build page content with proper RTL
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: pageStyle.backgroundColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Build content for each Surah on this page
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: _buildPageContent(
                    surahIds,
                    surahVerses,
                    pageData,
                    isDark,
                    pageStyle,
                  ),
                ),
              ),
            ),

            // Page footer
            _buildPageFooter(pageNumber, isDark, pageStyle),
          ],
        ),
      ),
    );
  }

  PageStyle _getPageStyle(bool isDark) {
    switch (_currentMushafType) {
      case MushafType.egyptian:
        return PageStyle(
          backgroundColor: isDark
              ? const Color(0xFF1E2A3A)
              : const Color(0xFFF5F8FC),
          textColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
          accentColor: isDark ? Colors.blue[300]! : const Color(0xFF1E4D8C),
          dividerColor: isDark
              ? Colors.grey[700]!
              : const Color(0xFF1E4D8C).withValues(alpha: 0.3),
          fontSize: 24,
          lineHeight: 1.8,
          headerGradient: isDark
              ? [const Color(0xFF1E4D8C), const Color(0xFF0F2942)]
              : [const Color(0xFFE8F0F8), const Color(0xFFD4E4F4)],
        );
      case MushafType.indoPak:
        return PageStyle(
          backgroundColor: isDark
              ? const Color(0xFF242424)
              : const Color(0xFFFFFBF0),
          textColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
          accentColor: isDark ? Colors.teal[300]! : const Color(0xFF006754),
          dividerColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          fontSize: 26,
          lineHeight: 2.0,
          headerGradient: isDark
              ? [const Color(0xFF1E3A35), const Color(0xFF0B2D28)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        );
      case MushafType.warsh:
        return PageStyle(
          backgroundColor: isDark
              ? const Color(0xFF1E1E2E)
              : const Color(0xFFF8F4E8),
          textColor: isDark ? Colors.white : const Color(0xFF2D2D2D),
          accentColor: isDark ? Colors.amber[300]! : const Color(0xFF8B6914),
          dividerColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          fontSize: 24,
          lineHeight: 1.8,
          headerGradient: isDark
              ? [const Color(0xFF2E2A1E), const Color(0xFF1A1610)]
              : [const Color(0xFFF5F0E0), const Color(0xFFE8E0C8)],
        );
      case MushafType.madani:
        return PageStyle(
          backgroundColor: isDark
              ? const Color(0xFF242424)
              : const Color(0xFFFEFDF5),
          textColor: isDark ? Colors.white : const Color(0xFF004B40),
          accentColor: isDark ? Colors.teal[300]! : const Color(0xFF006754),
          dividerColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          fontSize: 24,
          lineHeight: 1.8,
          headerGradient: isDark
              ? [const Color(0xFF1E3A35), const Color(0xFF0B2D28)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        );
    }
  }

  Widget _buildOrnament(Color color, {bool mirror = false}) {
    return Transform.scale(
      scaleX: mirror ? -1 : 1,
      child: Icon(Icons.mosque_outlined, color: color, size: 24),
    );
  }

  /// Build page content with multiple Surahs
  Widget _buildPageContent(
    List<int> surahIds,
    Map<int, List<_PageVerseEntry>> surahVerses,
    MushafPageIndex pageData,
    bool isDark,
    PageStyle style,
  ) {
    final children = <Widget>[];

    for (int i = 0; i < surahIds.length; i++) {
      final surahId = surahIds[i];
      final verses = surahVerses[surahId]!;
      final surahInfo = QuranIndex.quranSurahs.firstWhere(
        (s) => s.id == surahId,
      );
      final isFirstSurahOnPage = i == 0;
      // Always show Surah header on every page for each Surah present
      // In a real Mushaf, every page shows the Surah name at the top
      final showBismillah = isFirstSurahOnPage
          ? pageData.containsBismillah
          : surahId != 9; // Show Bismillah for new Surah except At-Tawbah

      // Surah header (always show for each Surah on this page)
      children.add(_buildSurahHeaderForMushaf(surahInfo, isDark, style));
      children.add(const SizedBox(height: 8));

      // Bismillah for this Surah
      if (showBismillah) {
        children.add(_buildBismillah(isDark, style));
        children.add(const SizedBox(height: 8));
      }

      // Verses for this Surah
      children.add(_buildSurahVersesForPage(verses, isDark, style));

      // Divider between Surahs (if not the last one)
      if (i < surahIds.length - 1) {
        children.add(const SizedBox(height: 16));
        children.add(
          Divider(
            height: 1,
            color: style.dividerColor,
            indent: 40,
            endIndent: 40,
          ),
        );
        children.add(const SizedBox(height: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Build Surah header for Mushaf page (accepts Surah object directly)
  Widget _buildSurahHeaderForMushaf(Surah surah, bool isDark, PageStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: style.headerGradient),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Ornate header decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOrnament(style.accentColor, mirror: true),
              const SizedBox(width: 16),
              Text(
                surah.nameArabic,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : style.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              _buildOrnament(style.accentColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.nameEnglish} • ${surah.verseCount} ${'lbl_verses'.tr}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build verses for a specific Surah on a page
  /// Uses continuous text flow like a real Mushaf (no gaps between verses)
  Widget _buildSurahVersesForPage(
    List<_PageVerseEntry> verses,
    bool isDark,
    PageStyle style,
  ) {
    // Build all verses as a single continuous text block for proper Mushaf flow
    return GestureDetector(
      onTapUp: (details) {
        // Find which verse was tapped based on text position
        _showVerseActionsFromPosition(details.globalPosition, verses);
      },
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        softWrap: true,
        text: TextSpan(
          children: _buildContinuousVerseSpans(verses, isDark, style),
        ),
      ),
    );
  }

  /// Build continuous verse spans with minimal gaps
  List<InlineSpan> _buildContinuousVerseSpans(
    List<_PageVerseEntry> verses,
    bool isDark,
    PageStyle style,
  ) {
    final spans = <InlineSpan>[];

    for (final entry in verses) {
      final verse = entry.verse;
      final isHighlighted =
          widget.highlightSurah == entry.surahId &&
          widget.highlightVerse == verse.verseNumber;

      // Verse text
      spans.add(
        TextSpan(
          text: verse.text,
          style: TextStyle(
            fontFamily: 'Mushaf',
            fontSize: style.fontSize.toDouble(),
            height: 1.6, // Tighter line height
            letterSpacing: 0, // No letter spacing for Arabic
            color: isHighlighted ? Colors.teal : style.textColor,
            backgroundColor: isHighlighted
                ? (isDark
                      ? Colors.teal.withValues(alpha: 0.2)
                      : Colors.teal.withValues(alpha: 0.1))
                : null,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );

      // Verse marker as inline widget with minimal margin
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          baseline: TextBaseline.alphabetic,
          child: _buildCompactVerseMarker(verse.verseNumber, style),
        ),
      );

      // Very small space after verse (just enough to separate)
      spans.add(const TextSpan(text: ' '));
    }

    return spans;
  }

  /// Build ultra-compact verse marker for inline use
  Widget _buildCompactVerseMarker(int verseNumber, PageStyle style) {
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: style.accentColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        verseNumber.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Mushaf',
          fontSize: 6.5,
          fontWeight: FontWeight.bold,
          color: style.accentColor,
          height: 1,
        ),
      ),
    );
  }

  /// Handle tap on verses to show actions
  void _showVerseActionsFromPosition(
    Offset position,
    List<_PageVerseEntry> verses,
  ) {
    // For now, show actions for the first verse
    // A more sophisticated approach would calculate which verse was tapped
    if (verses.isNotEmpty) {
      _showVerseActions(verses.first.surahId, verses.first.verse);
    }
  }

  Widget _buildBismillah(bool isDark, PageStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Mushaf',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: style.accentColor,
        ),
      ),
    );
  }

  Widget _buildPageFooter(int pageNumber, bool isDark, PageStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: style.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Juz indicator
          Text(
            'Juz ${((pageNumber - 1) ~/ 20 + 1).toLocalizedNumber(context)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),

          // Page number in decorative box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: style.accentColor.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              pageNumber.toLocalizedNumber(context),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: style.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMushafBookmarks() {
    final bookmarks =
        PrefUtils().getStringList(
          'mushaf_bookmarks_${_currentMushafType.prefsKey}',
        ) ??
        [];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_currentMushafType.icon, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'lbl_mushaf_bookmarks'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
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
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final page = int.parse(bookmarks[index]);
                    final pageData = MushafPageIndex.getPage(page);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        child: Text(
                          page.toString(),
                          style: const TextStyle(color: Colors.teal),
                        ),
                      ),
                      title: Text(pageData?.surahNameAr ?? ''),
                      subtitle: Text('${'lbl_page'.tr} $page'),
                      onTap: () {
                        Navigator.pop(context);
                        _jumpToPage(page - 1);
                      },
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          bookmarks.removeAt(index);
                          PrefUtils().setStringList(
                            'mushaf_bookmarks_${_currentMushafType.prefsKey}',
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

  /// Show verse action menu (Share, Listen, Bookmark)
  void _showVerseActions(int surahId, Verse verse) {
    final surah = QuranIndex.quranSurahs.firstWhere(
      (s) => s.id == surahId,
      orElse: () => QuranIndex.quranSurahs.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Verse preview
            Text(
              '${surah.nameArabic} - ${'lbl_ayah'.tr} ${verse.verseNumber.toLocalizedNumber(context)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
              ),
              child: Text(
                verse.text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Mushaf',
                  fontSize: 20,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionTile(
              icon: Icons.play_circle_fill,
              color: Colors.orange,
              title: 'lbl_listen_from_here'.tr,
              onTap: () {
                Navigator.pop(context);
                _playAudioFromVerse(surah, verse.verseNumber);
              },
            ),
            _buildActionTile(
              icon: Icons.share,
              color: Colors.green,
              title: 'lbl_share_verse'.tr,
              onTap: () {
                Navigator.pop(context);
                context.showVerseShareSheet(surah: surah, verse: verse);
              },
            ),
            _buildActionTile(
              icon: Icons.bookmark_border,
              color: Colors.teal,
              title: 'lbl_bookmark_page'.tr,
              onTap: () {
                Navigator.pop(context);
                _saveVerseBookmark(surahId, verse.verseNumber);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('msg_page_bookmarked'.tr)),
                );
              },
            ),
            const Divider(height: 24),
            // Practice List
            _buildActionTile(
              icon: _isInPracticeList(surahId, verse.verseNumber)
                  ? Icons.playlist_remove
                  : Icons.error_outline,
              color: Colors.redAccent,
              title: _isInPracticeList(surahId, verse.verseNumber)
                  ? 'msg_unmark_practice'.tr
                  : 'msg_mark_practice'.tr,
              onTap: () {
                Navigator.pop(context);
                _togglePracticeList(surahId, verse.verseNumber);
              },
            ),
            // Voice Verification
            _buildActionTile(
              icon: Icons.mic,
              color: Colors.blueAccent,
              title: 'lbl_verify_recitation'.tr,
              onTap: () {
                Navigator.pop(context);
                _showVoiceDialog(surah, verse);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _playAudioFromVerse(Surah surah, int verseNumber) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show loading indicator
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      // Fetch audio from API with selected reciter
      final reciterId = PrefUtils().getReciterId();
      final audioFile = await _recitationService.fetchChapterAudio(
        reciterId: reciterId,
        chapterNumber: surah.id,
        segments: true,
      );

      // Hide loading
      navigator.pop();

      if (audioFile == null || audioFile.audioUrl.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('msg_audio_load_error'.tr)),
        );
        return;
      }

      // Convert segments to timestamps
      final timestamps = _convertSegmentsToTimestamps(audioFile.timings);

      // Navigate to audio player
      if (mounted) {
        AppRoutes.goToAudioPlayer(
          context,
          surah: surah,
          startVerse: verseNumber,
          reciter: PrefUtils().getReciterName(),
          audioUrls: [audioFile.audioUrl],
          verseTimestamps: timestamps,
        );
      }
    } catch (e) {
      // Hide loading if dialog is still showing
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('msg_audio_load_error'.tr)),
      );
    }
  }

  List<Duration> _convertSegmentsToTimestamps(List<VerseTiming> timings) {
    if (timings.isEmpty) return [];

    // Parse verseKey (format: "surah:verse") to get verse number
    int parseVerseNumber(String verseKey) {
      final parts = verseKey.split(':');
      if (parts.length == 2) {
        return int.tryParse(parts[1]) ?? 0;
      }
      return 0;
    }

    // Find max verse number
    final verseNumbers = timings
        .map((t) => parseVerseNumber(t.verseKey))
        .where((n) => n > 0)
        .toList();

    if (verseNumbers.isEmpty) return [];

    final maxVerse = verseNumbers.reduce((a, b) => a > b ? a : b);
    final timestamps = List<Duration>.filled(maxVerse, Duration.zero);

    for (final timing in timings) {
      final verseNum = parseVerseNumber(timing.verseKey);
      if (verseNum > 0 && verseNum <= maxVerse) {
        timestamps[verseNum - 1] = Duration(milliseconds: timing.timestampFrom);
      }
    }

    return timestamps;
  }

  void _togglePracticeList(int surahId, int verseNumber) {
    final key = '${surahId}_$verseNumber';
    final isInList = _practiceListKeys.contains(key);

    if (isInList) {
      _practiceListKeys.remove(key);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('msg_removed_practice'.tr)));
    } else {
      _practiceListKeys.add(key);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('msg_added_practice'.tr)));
    }

    // Save to preferences
    PrefUtils().setStringList('recitation_errors', _practiceListKeys.toList());

    // Refresh UI
    setState(() {});
  }

  Future<void> _showVoiceDialog(Surah surah, Verse verse) async {
    // 1. Request Permission
    bool available = await _voiceService.requestPermission();

    if (!mounted) return;

    if (!available) {
      // Show Dialog to guide user to settings
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('msg_mic_permission'.tr),
          content: Text('msg_mic_permission_desc'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('lbl_cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                openAppSettings();
              },
              child: Text('lbl_settings'.tr),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Prepare Expected Text
    String expectedText = verse.text;
    if (verse.verseNumber == 1 && surah.id != 1) {
      const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
      if (expectedText.startsWith(bismillahPrefix)) {
        expectedText = expectedText.substring(bismillahPrefix.length).trim();
      } else if (expectedText.startsWith(bismillahSimple)) {
        expectedText = expectedText.substring(bismillahSimple.length).trim();
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VoiceVerificationDialog(
        surah: surah,
        aya: verse,
        expectedText: expectedText,
        onCorrect: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('msg_recitation_correct'.tr)),
            );
          }
        },
        onWrong: (ctx) {
          if (mounted) {
            // Optionally add to practice list
            _togglePracticeList(surah.id, verse.verseNumber);
          }
        },
      ),
    );
  }

  void _saveVerseBookmark(int surahId, int verseNumber) {
    final key = 'verse_bookmark_${surahId}_$verseNumber';
    PrefUtils().setString(
      key,
      '${DateTime.now().millisecondsSinceEpoch}|Surah $surahId, Ayah $verseNumber',
    );

    final bookmarks = PrefUtils().getStringList('verse_bookmarks') ?? [];
    final bookmarkKey = '$surahId:$verseNumber';
    if (!bookmarks.contains(bookmarkKey)) {
      bookmarks.add(bookmarkKey);
      PrefUtils().setStringList('verse_bookmarks', bookmarks);
    }
  }
}

class _PageVerseEntry {
  final int surahId;
  final Verse verse;

  const _PageVerseEntry({required this.surahId, required this.verse});
}

/// Page styling configuration
class PageStyle {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color dividerColor;
  final int fontSize;
  final double lineHeight;
  final List<Color> headerGradient;

  PageStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.dividerColor,
    required this.fontSize,
    required this.lineHeight,
    required this.headerGradient,
  });
}
