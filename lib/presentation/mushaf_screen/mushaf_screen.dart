import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/mushaf_types.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../domain/entities/verse.dart';
import '../../injection_container.dart';
import '../surah_screen/bloc/surah_bloc.dart';
import '../../core/utils/number_converter.dart';

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
  final PageController _pageController = PageController(initialPage: 0);
  final SurahBloc _surahBloc = sl<SurahBloc>();
  
  // Cache for loaded Surah verses
  final Map<int, List<Verse>> _surahCache = {};
  
  int _currentPage = 1;
  bool _showPageIndicator = true;
  Timer? _pageIndicatorTimer;
  bool _isLoading = true;
  late MushafType _currentMushafType;
  
  // Track visible pages for efficient loading
  final Set<int> _loadedSurahs = {};
  
  @override
  void initState() {
    super.initState();
    _currentMushafType = widget.mushafType;
    _currentPage = widget.initialPage ?? 1;
    _loadInitialData();
    
    // Auto-hide page indicator
    _resetPageIndicatorTimer();
    
    // Set system UI for immersive reading
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }
  
  Future<void> _loadInitialData() async {
    // Pre-load some Surahs around the initial page
    final initialPage = MushafPageIndex.getPage(_currentPage);
    if (initialPage != null) {
      await _loadSurah(initialPage.surahId);
    }
    
    setState(() => _isLoading = false);
    
    // Jump to initial page after build
    if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToPage(widget.initialPage! - 1);
      });
    }
  }
  
  Future<void> _loadSurah(int surahId) async {
    if (_loadedSurahs.contains(surahId) || _surahCache.containsKey(surahId)) return;

    _surahBloc.add(LoadSurahEvent(surahId: surahId.toString()));

    try {
      final state = await _surahBloc.stream.firstWhere(
        (s) =>
            s is SuccessSurahState &&
            s.chapters.isNotEmpty &&
            s.chapters.first.chapterId == surahId,
      );

      if (state is SuccessSurahState) {
        _surahCache[surahId] = state.chapters;
        _loadedSurahs.add(surahId);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading surah $surahId: $e');
    }
  }
  
  void _onPageChanged(int pageIndex) {
    final page = pageIndex + 1;
    if (page != _currentPage && page >= 1 && page <= _currentMushafType.totalPages) {
      setState(() => _currentPage = page);
      _resetPageIndicatorTimer();
      
      // Load upcoming Surahs
      final currentPageData = MushafPageIndex.getPage(page);
      if (currentPageData != null) {
        _loadSurah(currentPageData.surahId);
        // Preload next Surah if we're near the end
        final surahInfo = QuranIndex.quranSurahs.firstWhere(
          (s) => s.id == currentPageData.surahId,
          orElse: () => QuranIndex.quranSurahs.first,
        );
        if (currentPageData.endVerse >= surahInfo.verseCount - 5 &&
            currentPageData.surahId < 114) {
          _loadSurah(currentPageData.surahId + 1);
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
                _jumpToPage(page - 1);
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
        leading: Icon(
          type.icon,
          color: isSelected ? Colors.teal : null,
        ),
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
    });
    
    // Save preference
    PrefUtils().setString('mushaf_type', type.prefsKey);
    
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
            Text('msg_bookmark_current_page'.tr
                .replaceAll('{page}', _currentPage.toString())),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('msg_page_bookmarked'.tr)),
              );
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
      final key = 'mushaf_bookmark_${_currentMushafType.prefsKey}_$_currentPage';
      PrefUtils().setString(
        key,
        '${DateTime.now().millisecondsSinceEpoch}|$note',
      );
      
      final bookmarks = PrefUtils().getStringList(
        'mushaf_bookmarks_${_currentMushafType.prefsKey}',
      ) ?? [];
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
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            // RTL PageView for authentic Mushaf experience
            Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                reverse: true, // RTL: starts from right side
                onPageChanged: _onPageChanged,
                itemCount: _currentMushafType.totalPages,
                itemBuilder: (context, index) {
                  final pageNumber = index + 1;
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
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
    );
  }
  
  Widget _buildMushafPage(int pageNumber, bool isDark) {
    final pageData = MushafPageIndex.getPage(pageNumber);
    if (pageData == null) return const SizedBox.shrink();
    
    final verses = _surahCache[pageData.surahId];
    if (verses == null) {
      return Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    
    // Filter verses for this page
    final pageVerses = verses.where((v) => 
      v.verseNumber >= pageData.startVerse && 
      v.verseNumber <= pageData.endVerse
    ).toList();
    
    final isSurahStart = pageData.isSurahStart;
    final showBismillah = pageData.containsBismillah;
    
    // Page styling based on Mushaf type
    final pageStyle = _getPageStyle(isDark);
    
    return Container(
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
          // Surah header for first page of Surah
          if (isSurahStart) ...[
            _buildSurahHeader(pageData, isDark, pageStyle),
            Divider(height: 1, color: pageStyle.dividerColor),
          ],
          
          // Page content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Bismillah
                  if (showBismillah) _buildBismillah(isDark, pageStyle),
                  
                  // Verses
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: _buildPageVerses(
                        pageVerses, 
                        pageData.surahId,
                        isDark,
                        pageStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Page footer
          _buildPageFooter(pageNumber, isDark, pageStyle),
        ],
      ),
    );
  }
  
  PageStyle _getPageStyle(bool isDark) {
    switch (_currentMushafType) {
      case MushafType.egyptian:
        return PageStyle(
          backgroundColor: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFF5F8FC),
          textColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
          accentColor: isDark ? Colors.blue[300]! : const Color(0xFF1E4D8C),
          dividerColor: isDark ? Colors.grey[700]! : const Color(0xFF1E4D8C).withValues(alpha: 0.3),
          fontSize: 24,
          lineHeight: 2.2,
          headerGradient: isDark 
              ? [const Color(0xFF1E4D8C), const Color(0xFF0F2942)]
              : [const Color(0xFFE8F0F8), const Color(0xFFD4E4F4)],
        );
      case MushafType.indoPak:
        return PageStyle(
          backgroundColor: isDark ? const Color(0xFF242424) : const Color(0xFFFFFBF0),
          textColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
          accentColor: isDark ? Colors.teal[300]! : const Color(0xFF006754),
          dividerColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          fontSize: 26,
          lineHeight: 2.4,
          headerGradient: isDark 
              ? [const Color(0xFF1E3A35), const Color(0xFF0B2D28)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        );
      case MushafType.warsh:
        return PageStyle(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F4E8),
          textColor: isDark ? Colors.white : const Color(0xFF2D2D2D),
          accentColor: isDark ? Colors.amber[300]! : const Color(0xFF8B6914),
          dividerColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          fontSize: 24,
          lineHeight: 2.2,
          headerGradient: isDark 
              ? [const Color(0xFF2E2A1E), const Color(0xFF1A1610)]
              : [const Color(0xFFF5F0E0), const Color(0xFFE8E0C8)],
        );
      case MushafType.madani:
        return PageStyle(
          backgroundColor: isDark ? const Color(0xFF242424) : const Color(0xFFFEFDF5),
          textColor: isDark ? Colors.white : const Color(0xFF004B40),
          accentColor: isDark ? Colors.teal[300]! : const Color(0xFF006754),
          dividerColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          fontSize: 24,
          lineHeight: 2.2,
          headerGradient: isDark 
              ? [const Color(0xFF1E3A35), const Color(0xFF0B2D28)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        );
    }
  }
  
  Widget _buildSurahHeader(MushafPageIndex pageData, bool isDark, PageStyle style) {
    final surah = QuranIndex.quranSurahs.firstWhere(
      (s) => s.id == pageData.surahId,
      orElse: () => QuranIndex.quranSurahs[0],
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.headerGradient,
        ),
      ),
      child: Column(
        children: [
          // Ornate header decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOrnament(style.accentColor, mirror: true),
              const SizedBox(width: 20),
              Text(
                surah.nameArabic,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : style.accentColor,
                ),
              ),
              const SizedBox(width: 20),
              _buildOrnament(style.accentColor),
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
  
  Widget _buildOrnament(Color color, {bool mirror = false}) {
    return Transform.scale(
      scaleX: mirror ? -1 : 1,
      child: Icon(Icons.mosque_outlined, color: color, size: 24),
    );
  }
  
  Widget _buildBismillah(bool isDark, PageStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: style.accentColor,
        ),
      ),
    );
  }
  
  Widget _buildPageVerses(
    List<Verse> verses, 
    int surahId, 
    bool isDark,
    PageStyle style,
  ) {
    // Build continuous text with verse markers
    final spans = <InlineSpan>[];
    
    for (final verse in verses) {
      // Check if this verse should be highlighted
      final isHighlighted = widget.highlightSurah == surahId && 
                            widget.highlightVerse == verse.verseNumber;
      
      spans.add(TextSpan(
        text: verse.text,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: style.fontSize.toDouble(),
          height: style.lineHeight,
          color: isHighlighted ? Colors.teal : style.textColor,
          backgroundColor: isHighlighted 
              ? (isDark ? Colors.teal.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.1))
              : null,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ));
      
      // Verse end marker
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: style.accentColor,
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
              color: style.accentColor,
            ),
          ),
        ),
      ));
    }
    
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      text: TextSpan(children: spans),
    );
  }
  
  Widget _buildPageFooter(int pageNumber, bool isDark, PageStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: style.dividerColor),
        ),
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
              border: Border.all(color: style.accentColor.withValues(alpha: 0.5)),
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
    final bookmarks = PrefUtils().getStringList(
      'mushaf_bookmarks_${_currentMushafType.prefsKey}',
    ) ?? [];
    
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
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
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
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
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
