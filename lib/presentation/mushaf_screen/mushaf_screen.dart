import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hafiz_app/core/mushaf/mushaf_cache_manager.dart';
import 'package:hafiz_app/core/mushaf/mushaf_page_verse_map.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/services/reading_session_tracker.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_bloc.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_event.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/widgets/offline_indicator.dart';
import 'widgets/mushaf_jump_dialog.dart';
import 'widgets/mushaf_page_widget.dart';
import 'widgets/mushaf_bottom_bar.dart';
import 'widgets/mushaf_top_bar.dart';

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
  Timer? _persistDebounce;
  Timer? _prefetchDebounce;
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
    unawaited(sl<AnalyticsService>().logOpenMushaf(_currentPage));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only restore from PageStorage if the screen was NOT opened with an
    // explicit initialPage (e.g. deep link). PageStorage is for surviving
    // orientation changes / rebuilds, not for overriding user intent.
    if (widget.initialPage != null) return;

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
    _finalizeCurrentSession();
    _persistDebounce?.cancel();
    _prefetchDebounce?.cancel();
    _overlayTimer?.cancel();
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _sessionTracker.pause();
        break;
      case AppLifecycleState.resumed:
        _sessionTracker.resume();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didHaveMemoryPressure() {
    imageCache.clear();
    imageCache.clearLiveImages();
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
    return type.getSurahStartPage(surahId);
  }

  /// Convert a page number in the current mushaf type to Madani-equivalent.
  int _toMadaniPage(int page) {
    if (_mushafType.totalPages == MushafPageIndex.totalPages) {
      return page;
    }
    return (page / _mushafType.totalPages * MushafPageIndex.totalPages)
        .round()
        .clamp(1, MushafPageIndex.totalPages);
  }

  // ─── Page Precaching ────────────────────────────────────────────

  void _precacheAdjacentPages(int currentPage) {
    for (final offset in [1, -1, 2, -2]) {
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
      ).catchError((_) {});
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
    final madaniPage = _toMadaniPage(_currentPage);
    final surahId = MushafPageIndex.getSurahForPage(madaniPage);
    final targetPage = _surahToPageInType(surahId, newType);

    // Clear PageStorage so the old page number (e.g. 500 in 604-page mode)
    // doesn't carry over to the new mushaf type (e.g. 30-page mode).
    PageStorage.of(context).writeState(
      context,
      null,
      identifier: _kPageStorageKey,
    );
    final oldController = _pageController;
    setState(() {
      _mushafType = newType;
      _currentPage = targetPage;
      _isZoomed = false;
      PrefUtils().setMushafType(newType.name);
    });
    _pageController = PageController(initialPage: _currentPage - 1);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      _precacheAdjacentPages(_currentPage);
    });
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
                    _currentPage = page;
                    setState(() {});
                    // Debounce persistence — avoid excessive SharedPreferences
                    // writes during rapid page flips.
                    _persistDebounce?.cancel();
                    _persistDebounce = Timer(const Duration(milliseconds: 500), () {
                      PrefUtils().setMushafLastPageForType(_mushafType.name, page);
                      PageStorage.of(context).writeState(context, page, identifier: _kPageStorageKey);
                    });
                    // Debounce prefetch to reduce image cache contention
                    _prefetchDebounce?.cancel();
                    _prefetchDebounce = Timer(const Duration(milliseconds: 200), () {
                      _precacheAdjacentPages(page);
                    });
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
                  child: RepaintBoundary(
                    child: MushafTopBar(
                      colors: colors,
                      onBackPressed: NavigatorService.goBack,
                      onTypePressed: _showMushafTypeSwitcher,
                      onJumpPressed: _showJumpDialog,
                    ),
                  ),
                ),
              if (_showOverlay)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: RepaintBoundary(
                    child: MushafBottomBar(
                      currentPage: _currentPage,
                      mushafType: _mushafType,
                      colors: colors,
                      onJumpPressed: _showJumpDialog,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page Rendering ─────────────────────────────────────────────

  Widget _buildPage(int pageNumber, bool isDark, AppColors colors) {
    return RepaintBoundary(
      child: MushafPageWidget(
        key: ValueKey('mushaf_page_$pageNumber'),
        pageNumber: pageNumber,
        mushafType: _mushafType,
        onZoomChanged: (zoomed) {
          if (mounted) setState(() => _isZoomed = zoomed);
        },
      ),
    );
  }

  // ─── Overlay Bars ───────────────────────────────────────────────

  void _startMushafSession() {
    final ranges = MushafPageVerseMap.getVersesForPage(
      _currentPage,
      totalPages: _mushafType.totalPages,
    );
    for (final range in ranges) {
      _sessionTracker.startSession(
        surahId: range.surahId,
        startVerse: range.startVerse,
      );
      _sessionTracker.updateProgress(range.endVerse);
    }
  }

  void _updateMushafSessionProgress(int page) {
    final ranges = MushafPageVerseMap.getVersesForPage(
      page,
      totalPages: _mushafType.totalPages,
    );
    if (ranges.isEmpty) return;

    for (final range in ranges) {
      _sessionTracker.startSession(
        surahId: range.surahId,
        startVerse: range.startVerse,
      );
      _sessionTracker.updateProgress(range.endVerse);
    }
  }

  void _finalizeCurrentSession() {
    final sessions = _sessionTracker.endSession();
    for (final session in sessions) {
      if (session.endVerse >= session.startVerse) {
        final totalVerses = session.endVerse - session.startVerse + 1;
        
        // Update local dashboard
        try {
          sl<KhatmahBloc>().add(RecordReading(verses: totalVerses));
        } catch (e, s) {
          Logger.warning('Failed to record reading: $e\n$s', feature: 'Mushaf');
        }
        
        // Sync to QF
        unawaited(sl<KhatmahRepository>().reportReadingSession(session));
        
        // Analytics
        unawaited(
          sl<AnalyticsService>().logReadingSession(
            chapterNumber: session.surahId,
            versesRead: totalVerses,
            durationSeconds: session.durationSeconds,
          ),
        );
        
        Logger.info(
          'Mushaf session finalized: ${session.surahId}:${session.startVerse}-${session.endVerse}',
          feature: 'ReadingSessions',
        );
      }
    }
  }

}

