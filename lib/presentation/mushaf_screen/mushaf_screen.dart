import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_export.dart';
import '../../core/analytics/analytics_helper.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/mushaf_types.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../domain/entities/verse.dart';
import '../../injection_container.dart';
import '../../core/network/mushaf_image_provider.dart';
import '../surah_screen/bloc/surah_bloc.dart';
import '../../core/utils/number_converter.dart';
import '../../widgets/verse_share_sheet.dart';
import '../../core/audio/recitation_service.dart';
import '../../core/audio/recitation_models.dart';
import '../surah_screen/voice_verification_service.dart';
import '../surah_screen/widgets/voice_verification_dialog.dart';
import 'widgets/interactive_mushaf_page.dart';

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

  // Font size control

  @override
  void initState() {
    super.initState();
    _currentMushafType = widget.mushafType;

    // Load saved font size preference

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

    // Pre-cache adjacent images
    _precacheAdjacentPages(_currentPage);

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

      // Precache images for adjacent pages for continuous smooth scrolling
      _precacheAdjacentPages(page);
    }
  }

  void _precacheAdjacentPages(int currentPage) {
    if (!mounted) return;

    // Cache next page (if exists)
    if (currentPage < _currentMushafType.totalPages) {
      final nextUrl = MushafImageProvider.getImageUrl(
        _currentMushafType,
        currentPage + 1,
      );
      precacheImage(
        CachedNetworkImageProvider(nextUrl),
        context,
        onError: (e, s) => debugPrint('Precache fail: $e'),
      );
    }

    // Cache previous page (if exists)
    if (currentPage > 1) {
      final prevUrl = MushafImageProvider.getImageUrl(
        _currentMushafType,
        currentPage - 1,
      );
      precacheImage(
        CachedNetworkImageProvider(prevUrl),
        context,
        onError: (e, s) => debugPrint('Precache fail: $e'),
      );
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
        title: Text('${'lbl_mushaf'.tr} - ${_currentMushafType.displayName}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showMushafSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  reverse: true, // RTL scrolling for Quran
                  onPageChanged: _onPageChanged,
                  itemCount: _currentMushafType.totalPages,
                  itemBuilder: (context, index) {
                    final pageNumber = _currentMushafType.totalPages - index;
                    return _buildMushafPage(pageNumber, isDark);
                  },
                ),
              ),
            ),
            // Bottom page indicator
            if (_showPageIndicator)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${_currentPage.toLocalizedNumber(context)} / ${_currentMushafType.totalPages.toLocalizedNumber(context)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafPage(int pageNumber, bool isDark) {
    return InteractiveMushafPage(
      pageNumber: pageNumber,
      mushafType: _currentMushafType,
      isDark: isDark,
      onVerseTapped: (surahId, verseNum) {
        // -1 indicates a raw tap anywhere on the page without specific JSON coordinates yet plotted
        if (surahId == -1) {
          final pageData = MushafPageIndex.getPage(pageNumber);
          if (pageData != null) {
            final int sId = pageData.surahId;
            final int vNum = pageData.startVerse;
            final verses = _surahCache[sId];
            if (verses != null) {
              try {
                final verse = verses.firstWhere((v) => v.verseNumber == vNum);
                _showVerseActions(sId, verse);
              } catch (_) {}
            }
          }
        } else {
          // A precise bounding-box tap
          final verses = _surahCache[surahId];
          if (verses != null) {
            try {
              final verse = verses.firstWhere((v) => v.verseNumber == verseNum);
              _showVerseActions(surahId, verse);
            } catch (_) {}
          }
        }
      },
    );
  }

  // New Settings Bottom Sheet
  void _showMushafSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'lbl_mushaf_settings'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Actions Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildSettingsIcon(
                  Icons.bookmark_border,
                  'lbl_bookmark'.tr,
                  () {
                    Navigator.pop(context);
                    _showBookmarkDialog();
                  },
                ),
                _buildSettingsIcon(
                  Icons.bookmarks_outlined,
                  'lbl_bookmarks'.tr,
                  () {
                    Navigator.pop(context);
                    _showMushafBookmarks();
                  },
                ),
                _buildSettingsIcon(Icons.pageview, 'lbl_jump'.tr, () {
                  Navigator.pop(context);
                  _showPageJumpDialog();
                }),
                _buildSettingsIcon(Icons.layers, 'lbl_type'.tr, () {
                  Navigator.pop(context);
                  _showMushafTypeSelector();
                }),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
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
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.teal.withValues(alpha: 0.2),
                    ),
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
