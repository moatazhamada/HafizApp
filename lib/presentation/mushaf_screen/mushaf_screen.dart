import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_app/core/mushaf/mushaf_page_verse_map.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';
import 'package:hafiz_app/widgets/offline_indicator.dart';
import 'widgets/mushaf_jump_dialog.dart';
import 'widgets/mushaf_page_widget.dart';

class MushafScreen extends StatefulWidget {
  final int? initialPage;

  const MushafScreen({super.key, this.initialPage});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _currentPage;
  late MushafType _mushafType;
  bool _showOverlay = true;
  bool _isZoomed = false;
  Timer? _overlayTimer;
  final Map<int, List<_VerseText>> _localTextCache = {};

  @override
  void initState() {
    super.initState();
    _mushafType = MushafType.fromString(PrefUtils().getMushafType());
    final resolved =
        widget.initialPage ??
        PrefUtils().getMushafLastPageForType(_mushafType.name);
    _currentPage = resolved.clamp(1, _mushafType.totalPages);

    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  int _pageIndexToNumber(int index) => index + 1;

  int _surahToPageInType(int surahId, MushafType type) {
    if (type.totalPages == 604) {
      return MushafPageIndex.getPageForSurah(surahId).clamp(1, 604);
    }
    final madaniStart = MushafPageIndex.surahStartPages[surahId - 1];
    return (madaniStart / 604.0 * type.totalPages)
        .round()
        .clamp(1, type.totalPages);
  }

  // ─── Page Precaching ────────────────────────────────────────────

  void _precacheAdjacentPages(int currentPage) {
    for (final offset in [1, 2, -1]) {
      final target = currentPage + offset;
      if (target < 1 || target > _mushafType.totalPages) continue;
      final url = _mushafType.pageImageUrl(target);
      precacheImage(NetworkImage(url), context);
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
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.white,
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

    final ranges = MushafPageVerseMap.getVersesForPage(pageNumber);
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
      } catch (_) {
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
              PageView.builder(
                reverse: true,
                key: ValueKey(_mushafType),
                controller: _pageController,
                physics: _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: _mushafType.totalPages,
                onPageChanged: (index) {
                  final page = _pageIndexToNumber(index);
                  _currentPage = page;
                  _isZoomed = false;
                  PrefUtils().setMushafLastPageForType(_mushafType.name, page);
                  _precacheAdjacentPages(page);
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
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '$pageNumber / ${_mushafType.totalPages}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
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
    final verseNumColor = isDark ? Colors.white38 : Colors.black38;

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
                fontSize: 16,
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
              IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                onPressed: () => NavigatorService.goBack(),
                tooltip: 'lbl_back'.tr,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.menu_book, color: colors.textPrimary),
                onPressed: _showMushafTypeSwitcher,
                tooltip: 'lbl_select_mushaf_type'.tr,
              ),
              IconButton(
                icon: Icon(Icons.search, color: colors.textPrimary),
                onPressed: _showJumpDialog,
                tooltip: 'lbl_jump_to_page'.tr,
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
                  GestureDetector(
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
