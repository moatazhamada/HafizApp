import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hafiz_app/core/mushaf/mushaf_cache_manager.dart';
import 'package:hafiz_app/core/mushaf/mushaf_page_verse_map.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/core/services/reading_session_tracker.dart';
import 'package:hafiz_app/domain/entities/reading_session.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/widgets/offline_indicator.dart';
import 'widgets/mushaf_jump_dialog.dart';
import 'widgets/mushaf_page_widget.dart';

class MushafScreen extends StatefulWidget {
  final int? initialPage;

  const MushafScreen({super.key, this.initialPage});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen>
    with WidgetsBindingObserver {
  // late final → cannot be reassigned; survives rebuilds, orientation flips,
  // and any lifecycle event that does NOT fully dispose the State.
  late PageController _pageController;
  late int _currentPage;
  late MushafType _mushafType;
  bool _showOverlay = true;
  bool _isZoomed = false;
  Timer? _overlayTimer;
  final Map<int, List<_VerseText>> _localTextCache = {};

  // PageStorage bucket key — used as a fallback if prefs are slow/unavailable.
  static const String _kPageStorageKey = 'mushaf_current_page';

  // Reading Session Tracking
  final ReadingSessionTracker _sessionTracker = ReadingSessionTracker();

  // --------------------------------------------------------------------------
  // CRITICAL: Mushaf Page Direction
  // --------------------------------------------------------------------------
  // The Mushaf is the physical Quran — it is ALWAYS an Arabic (RTL) book.
  // Page 1 (Al-Fatiha) MUST appear on the RIGHT side of the screen, and
  // users swipe LEFT to advance to the next page (page 2, 3, … 604).
  //
  // This is NOT affected by the app's UI language. An English-speaking user
  // reading the Mushaf still turns pages the same way an Arabic-speaking user
  // does, because the content itself is Arabic.
  //
  // Therefore PageView.reverse is HARDCODED to `true` below.
  // DO NOT make this conditional on TextDirection, locale, or any setting.
  // If you change this, you will break the Mushaf for every user.
  // --------------------------------------------------------------------------
  static const bool _kMushafPageReverse = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (PrefUtils().isKeepScreenOn()) {
      WakelockPlus.enable();
    }
    _mushafType = MushafType.fromString(PrefUtils().getMushafType());
    final resolved =
        widget.initialPage ??
        PrefUtils().getMushafLastPageForType(_mushafType.name);
    _currentPage = resolved.clamp(1, _mushafType.totalPages);

    _pageController = PageController(initialPage: _currentPage - 1);
    _startMushafSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If PageStorage has a saved page (e.g. after orientation change),
    // restore it so the user doesn't jump back to the initial page.
    final storage = PageStorage.of(context);
    final saved = storage.readState(context, identifier: _kPageStorageKey);
    if (saved is int && saved != _currentPage && saved >= 1 && saved <= _mushafType.totalPages) {
      _currentPage = saved;
      // Jump without animation so the user sees the exact page instantly.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage - 1);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MushafScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent pushes a new initialPage (e.g. deep-link), honour it.
    if (widget.initialPage != null &&
        widget.initialPage != oldWidget.initialPage) {
      _currentPage = widget.initialPage!.clamp(1, _mushafType.totalPages);
      _pageController.jumpToPage(_currentPage - 1);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Orientation or split-screen resize can reset the PageView viewport.
    // Re-assert the correct page after the frame settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        final page = _pageController.page?.round() ?? _currentPage - 1;
        final expected = _currentPage - 1;
        if (page != expected) {
          _pageController.jumpToPage(expected);
        }
      }
    });
  }

  @override
  void dispose() {
    final session = _sessionTracker.endSession();
    if (session != null) {
      _postMushafReadingSession(session);
    }
    WidgetsBinding.instance.removeObserver(this);
    _overlayTimer?.cancel();
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  /// Persist the current page to both prefs and PageStorage so it survives
  /// orientation changes, app backgrounding, and even widget disposal.
  void _persistPage(int page) {
    _currentPage = page;
    PrefUtils().setMushafLastPageForType(_mushafType.name, page);
    PageStorage.of(context).writeState(
      context,
      page,
      identifier: _kPageStorageKey,
    );
  }

  int _pageIndexToNumber(int index) => index + 1;

  int _surahToPageInType(int surahId, MushafType type) {
    if (type.totalPages == 604) {
      return MushafPageIndex.getPageForSurah(surahId).clamp(1, 604);
    }
    // Verse-proportional mapping: compute the cumulative verse fraction
    // up to this surah's start, and map to target type pages.
    const totalVerses = 6236;
    int cumulativeVerses = 0;
    for (int i = 0; i < surahId - 1; i++) {
      cumulativeVerses += MushafPageIndex.surahVerseCounts[i];
    }
    final fraction = cumulativeVerses / totalVerses;
    return (fraction * (type.totalPages - 1)).round().clamp(1, type.totalPages);
  }

  // ─── Page Precaching ────────────────────────────────────────────

  void _precacheAdjacentPages(int currentPage) {
    for (final offset in [1, 2, -1]) {
      final target = currentPage + offset;
      if (target < 1 || target > _mushafType.totalPages) continue;
      final url = _mushafType.pageImageUrl(target);
      precacheImage(
        CachedNetworkImageProvider(
          url,
          cacheManager: MushafCacheManager.instance,
          cacheKey: MushafCacheManager.cacheKey(_mushafType.name, target),
        ),
        context,
      );
    }
  }

  // ─── Mushaf Type Switcher ───────────────────────────────────────

  void _showMushafTypeSwitcher() {
    showModalBottomSheet<MushafType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'lbl_select_mushaf_type'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...MushafType.all.map(
                  (type) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(type.colorValue),
                      radius: 16,
                      child: Icon(
                        Icons.menu_book,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18,
                      ),
                    ),
                    title: Text(type.label.tr),
                    subtitle: Text(
                      type.descriptionKey.tr,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: type == _mushafType
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(ctx).pop(type),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((selected) {
      if (selected != null && selected != _mushafType) {
        _switchMushafType(selected);
      }
    });
  }

  void _switchMushafType(MushafType newType) {
    final surahId = MushafPageIndex.getSurahForPage(_currentPage);
    final targetPage = _surahToPageInType(surahId, newType);

    _localTextCache.clear();
    setState(() {
      _mushafType = newType;
      _currentPage = targetPage;
      _isZoomed = false;
      PrefUtils().setMushafType(newType.name);
    });
    _pageController.dispose();
    _pageController = PageController(initialPage: _currentPage - 1);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAdjacentPages(_currentPage);
    });
  }

  // ─── Offline Text Loading ───────────────────────────────────────

  Future<List<_VerseText>> _loadLocalPageText(int pageNumber) async {
    if (_localTextCache.containsKey(pageNumber)) {
      return _localTextCache[pageNumber]!;
    }

    final ranges = MushafPageVerseMap.getVersesForPage(
      pageNumber,
      totalPages: _mushafType.totalPages,
    );
    final isWarsh = _mushafType == MushafType.warsh;
    final List<_VerseText> entries = [];

    for (final range in ranges) {
      final surah = QuranIndex.quranSurahs[range.surahId - 1];
      final showBismillah =
          range.startVerse == 1 &&
          (isWarsh
              ? range.surahId == 1
              : range.surahId != 1 && range.surahId != 9);

      try {
        final jsonStr = await rootBundle.loadString(
          'assets/quran/uthmani/surah_${range.surahId}.json',
        );
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        final versesRaw = data.containsKey('verses')
            ? data['verses']
            : data['chapter'];
        final List<dynamic> verseList = versesRaw is List ? versesRaw : [];

        for (final v in verseList) {
          if (v is! Map<String, dynamic>) continue;
          final verseNum = (v['verse'] ?? v['verse_number'] ?? 0) as int;
          if (verseNum >= range.startVerse && verseNum <= range.endVerse) {
            final text = (v['text'] ?? v['text_uthmani'] ?? '') as String;
            entries.add(
              _VerseText(
                surahId: range.surahId,
                verseNumber: verseNum,
                text: text,
                surahNameArabic: surah.nameArabic,
                showBismillah: showBismillah && verseNum == 1,
              ),
            );
          }
        }
      } catch (e) {
        Logger.warning('Mushaf verse text load failed: $e', feature: 'Mushaf');
        entries.add(
          _VerseText(
            surahId: range.surahId,
            verseNumber: 0,
            text: '',
            surahNameArabic: surah.nameArabic,
            showBismillah: false,
          ),
        );
      }
    }

    _localTextCache[pageNumber] = entries;
    return entries;
  }

  // ─── Navigation ─────────────────────────────────────────────────

  void _goToPage(int page) {
    final target = page.clamp(1, _mushafType.totalPages);
    _persistPage(target);
    setState(() {});
    _pageController.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showJumpDialog() {
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MushafJumpDialog(
        currentPage: _currentPage,
        totalPages: _mushafType.totalPages,
        mushafType: _mushafType,
        surahToPage: _surahToPageInType,
      ),
    ).then((page) {
      if (page != null && page != _currentPage) {
        _goToPage(page);
      }
    });
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.mushafPageBg,
      body: OfflineIndicator(
        child: GestureDetector(
          onTap: _toggleOverlay,
          child: Stack(
            children: [
              // NEVER change reverse — see the _kMushafPageReverse constant
              // and the class-level comment above initState().
              //
              // Force LTR directionality around the PageView so that
              // reverse:true always puts page 1 on the right and swipe-left
              // advances, regardless of the app's UI locale (Arabic/English).
              Directionality(
                textDirection: TextDirection.ltr,
                child: PageView.builder(
                  reverse: _kMushafPageReverse,
                  key: ValueKey(_mushafType),
                  controller: _pageController,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  itemCount: _mushafType.totalPages,
                  onPageChanged: (index) {
                    final page = _pageIndexToNumber(index);
                    _isZoomed = false;
                    _persistPage(page);
                    _precacheAdjacentPages(page);
                    _updateMushafSessionProgress(page);
                    if (_showOverlay) {
                      _overlayTimer?.cancel();
                      _overlayTimer = Timer(const Duration(seconds: 3), () {
                        if (mounted) setState(() => _showOverlay = false);
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final pageNumber = _pageIndexToNumber(index);
                    return _buildPage(pageNumber, isDark, colors);
                  },
                ),
              ),
              if (_showOverlay)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(isDark, colors),
                ),
              if (_showOverlay)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(isDark, colors),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page Rendering ─────────────────────────────────────────────

  Widget _buildPage(int pageNumber, bool isDark, AppColors colors) {
    return MushafPageWidget(
      key: ValueKey('mushaf_page_$pageNumber'),
      pageNumber: pageNumber,
      mushafType: _mushafType,
      fallback: _buildOfflineFallback(pageNumber, isDark, colors),
      onZoomChanged: (zoomed) {
        if (mounted) setState(() => _isZoomed = zoomed);
      },
    );
  }

  Widget _buildOfflineFallback(int pageNumber, bool isDark, AppColors colors) {
    return FutureBuilder<List<_VerseText>>(
      future: _loadLocalPageText(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark
                  ? colors.mushafTextPrimary.withValues(alpha: 0.4)
                  : colors.mushafPageBorder.withValues(alpha: 0.4),
            ),
          );
        }
        final verses = snapshot.data ?? [];
        if (verses.isEmpty ||
            (verses.length == 1 && verses.first.text.isEmpty)) {
          final surahId = MushafPageIndex.getSurahForPage(pageNumber);
          final surah = QuranIndex.quranSurahs[surahId - 1];
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '$pageNumber / ${_mushafType.totalPages}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _buildTextContent(isDark, colors, verses),
        );
      },
    );
  }

  Widget _buildTextContent(
    bool isDark,
    AppColors colors,
    List<_VerseText> verses,
  ) {
    final fontSize = PrefUtils().getQuranFontSize();
    final textColor = colors.mushafTextPrimary;
    final verseNumColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    final List<InlineSpan> spans = [];
    final arabicVerseNumStyle = TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: fontSize - 4,
      color: verseNumColor,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < verses.length; i++) {
      final v = verses[i];
      if (v.text.isEmpty) continue;

      if (v.verseNumber == 1) {
        if (i > 0) spans.add(const TextSpan(text: '\n'));
        spans.add(
          TextSpan(
            text: '${v.surahNameArabic}\n',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colors.mushafSurahHeaderColor,
            ),
          ),
        );
        if (v.showBismillah) {
          spans.add(
            TextSpan(
              text:
                  '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
                  '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0670\u0646\u0650 '
                  '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650\n',
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: PrefUtils().getQuranFontSize() - 8,
                color: colors.textSecondary,
              ),
            ),
          );
        }
      }

      spans.add(
        TextSpan(
          text: '${v.text} ',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: fontSize,
            height: 2.0,
            color: textColor,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: ' \u06DD${_toArabicNumeral(v.verseNumber)} ',
          style: arabicVerseNumStyle,
        ),
      );
    }

    return SingleChildScrollView(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }

  // ─── Overlay Bars ───────────────────────────────────────────────

  void _startMushafSession() {
    final ranges = MushafPageVerseMap.getVersesForPage(
      _currentPage,
      totalPages: _mushafType.totalPages,
    );
    if (ranges.isNotEmpty) {
      final firstRange = ranges.first;
      _sessionTracker.startSession(
        surahId: firstRange.surahId,
        startVerse: firstRange.startVerse,
      );
    }
  }

  void _updateMushafSessionProgress(int page) {
    final ranges = MushafPageVerseMap.getVersesForPage(
      page,
      totalPages: _mushafType.totalPages,
    );
    if (ranges.isNotEmpty && ranges.first.surahId == _sessionTracker.surahId) {
      _sessionTracker.updateProgress(ranges.last.endVerse);
    }
  }

  Future<void> _postMushafReadingSession(ReadingSession session) async {
    try {
      final isAuthenticated = await sl<QfAuthRemoteDataSource>().isAuthenticated();
      if (!isAuthenticated) return;
      final dataSource = sl<QfGoalsRemoteDataSource>();
      await dataSource.postReadingSession(
        chapterNumber: session.surahId,
        verseNumber: session.startVerse,
        startVerse: session.startVerse,
        endVerse: session.endVerse,
        duration: session.durationSeconds,
        readAt: session.readAt,
      );
      Logger.info(
        'Mushaf reading session posted to QF: ${session.surahId}:${session.startVerse}-${session.endVerse}',
        feature: 'ReadingSessions',
      );
    } catch (e) {
      Logger.warning(
        'Failed to post mushaf reading session: $e',
        feature: 'ReadingSessions',
      );
    }
  }

  Widget _buildTopBar(bool isDark, AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.mushafPageBg,
            colors.mushafPageBg.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'lbl_back'.tr,
                child: IconButton(
                  icon: Icon(rtlBackArrow(context), color: colors.textPrimary),
                  onPressed: () => NavigatorService.goBack(),
                  tooltip: 'lbl_back'.tr,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: 'lbl_select_mushaf_type'.tr,
                child: IconButton(
                  icon: Icon(Icons.menu_book, color: colors.textPrimary),
                  onPressed: _showMushafTypeSwitcher,
                  tooltip: 'lbl_select_mushaf_type'.tr,
                ),
              ),
              Semantics(
                button: true,
                label: 'lbl_jump_to_page'.tr,
                child: IconButton(
                  icon: Icon(Icons.search, color: colors.textPrimary),
                  onPressed: _showJumpDialog,
                  tooltip: 'lbl_jump_to_page'.tr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, AppColors colors) {
    final pageData = MushafPageIndex.getPageData(_currentPage);
    final surahId =
        pageData?.surahId ?? MushafPageIndex.getSurahForPage(_currentPage);
    final surah = surahId >= 1 && surahId <= 114
        ? QuranIndex.quranSurahs[surahId - 1]
        : null;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final juz = MushafPageIndex.getJuzForPage(_currentPage);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            colors.mushafPageBg,
            colors.mushafPageBg.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (surah != null)
                Text(
                  isArabic ? surah.nameArabic : surah.nameEnglish,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${'lbl_juz'.tr} ${juz.toLocalizedNumber(context)}',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'lbl_semantics_page_indicator'
                        .tr
                        .replaceAll('{current}', '$_currentPage')
                        .replaceAll('{total}', '${_mushafType.totalPages}'),
                    child: GestureDetector(
                      onTap: _showJumpDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.mushafPageBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPage.toLocalizedNumber(context)} / ${_mushafType.totalPages.toLocalizedNumber(context)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const d = [
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669',
    ];
    return number.toString().split('').map((c) {
      final n = int.tryParse(c);
      return n != null ? d[n] : c;
    }).join();
  }
}

class _VerseText {
  final int surahId;
  final int verseNumber;
  final String text;
  final String surahNameArabic;
  final bool showBismillah;

  const _VerseText({
    required this.surahId,
    required this.verseNumber,
    required this.text,
    required this.surahNameArabic,
    required this.showBismillah,
  });
}
