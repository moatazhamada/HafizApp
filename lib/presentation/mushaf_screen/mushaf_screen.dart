import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';
import '../../core/mushaf/mushaf_rendering_config.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../data/datasource/mushaf/qf_mushaf_page_data_source.dart';
import '../../injection_container.dart';

class MushafScreen extends StatefulWidget {
  final int? initialPage;

  const MushafScreen({super.key, this.initialPage});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _currentPage;
  late String _renderingMode;
  final TextEditingController _pageInputController = TextEditingController();

  /// In-memory cache: pageNumber → API page data (exact verse mapping).
  final Map<int, MushafPageData> _apiPageCache = {};

  /// In-memory cache: pageNumber → local text entries (for offline fallback).
  final Map<int, List<_VerseText>> _localTextCache = {};

  @override
  void initState() {
    super.initState();
    final resolved = widget.initialPage ?? PrefUtils().getMushafLastPage();
    _currentPage = resolved.clamp(1, MushafPageIndex.totalPages);
    _pageController = PageController(initialPage: _currentPage - 1);
    _renderingMode = PrefUtils().getMushafRenderingMode();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  // ─── Data Loading ───────────────────────────────────────────────────

  /// Fetches exact page data from QF API. Caches in-memory.
  Future<MushafPageData?> _fetchApiPage(int pageNumber) async {
    if (_apiPageCache.containsKey(pageNumber)) {
      return _apiPageCache[pageNumber]!;
    }
    try {
      final ds = sl<QfMushafPageDataSource>();
      final page = await ds.fetchPage(pageNumber);
      if (page != null && !page.isEmpty) {
        _apiPageCache[pageNumber] = page;
      }
      return page;
    } catch (_) {
      return null;
    }
  }

  /// Loads verse text from local JSON assets for exact (surahId, verseNumber) pairs.
  Future<List<_VerseText>> _loadTextForVerses(List<PageVerse> pageVerses) async {
    final cacheKey = pageVerses.first.pageNumber;
    if (_localTextCache.containsKey(cacheKey) &&
        _localTextCache[cacheKey]!.length == pageVerses.length) {
      return _localTextCache[cacheKey]!;
    }

    // Group by surah to batch-load JSON files
    final bySurah = <int, List<PageVerse>>{};
    for (final pv in pageVerses) {
      bySurah.putIfAbsent(pv.surahId, () => []).add(pv);
    }

    final Map<String, String> textMap = {}; // "surahId:verseNum" → text
    for (final entry in bySurah.entries) {
      final surahId = entry.key;
      try {
        final jsonStr = await rootBundle.loadString(
          'assets/quran/uthmani/surah_$surahId.json',
        );
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        final versesRaw =
            data.containsKey('verses') ? data['verses'] : data['chapter'];
        final List<dynamic> verseList = versesRaw is List ? versesRaw : [];

        for (final v in verseList) {
          if (v is! Map<String, dynamic>) continue;
          final verseNum =
              (v['verse'] ?? v['verse_number'] ?? 0) as int;
          final text = (v['text'] ?? v['text_uthmani'] ?? '') as String;
          textMap['$surahId:$verseNum'] = text;
        }
      } catch (_) {
        // Skip failed surah loads
      }
    }

    // Build ordered list matching pageVerses order
    final results = <_VerseText>[];
    for (final pv in pageVerses) {
      final surah = QuranIndex.quranSurahs[pv.surahId - 1];
      final text = textMap['${pv.surahId}:${pv.verseNumber}'] ?? '';
      final isFirstVerseOfSurah = pv.verseNumber == 1;
      final showBismillah =
          isFirstVerseOfSurah && pv.surahId != 1 && pv.surahId != 9;

      results.add(_VerseText(
        surahId: pv.surahId,
        verseNumber: pv.verseNumber,
        text: text,
        surahNameArabic: surah.nameArabic,
        showBismillah: showBismillah,
      ));
    }

    _localTextCache[cacheKey] = results;
    return results;
  }

  /// Offline fallback: uses approximate local page index.
  Future<List<_VerseText>> _loadLocalPageText(int pageNumber) async {
    if (_localTextCache.containsKey(pageNumber)) {
      return _localTextCache[pageNumber]!;
    }

    final ranges = MushafPageIndex.getVersesForPage(pageNumber);
    final List<_VerseText> entries = [];

    for (final range in ranges) {
      final surah = QuranIndex.quranSurahs[range.surahId - 1];
      final showBismillah =
          range.startVerse == 1 && range.surahId != 1 && range.surahId != 9;

      try {
        final jsonStr = await rootBundle.loadString(
          'assets/quran/uthmani/surah_${range.surahId}.json',
        );
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        final versesRaw =
            data.containsKey('verses') ? data['verses'] : data['chapter'];
        final List<dynamic> verseList = versesRaw is List ? versesRaw : [];

        for (final v in verseList) {
          if (v is! Map<String, dynamic>) continue;
          final verseNum = (v['verse'] ?? v['verse_number'] ?? 0) as int;
          if (verseNum >= range.startVerse && verseNum <= range.endVerse) {
            final text = (v['text'] ?? v['text_uthmani'] ?? '') as String;
            entries.add(_VerseText(
              surahId: range.surahId,
              verseNumber: verseNum,
              text: text,
              surahNameArabic: surah.nameArabic,
              showBismillah: showBismillah && verseNum == 1,
            ));
          }
        }
      } catch (_) {
        entries.add(_VerseText(
          surahId: range.surahId,
          verseNumber: 0,
          text: '',
          surahNameArabic: surah.nameArabic,
          showBismillah: false,
        ));
      }
    }

    _localTextCache[pageNumber] = entries;
    return entries;
  }

  // ─── Navigation ─────────────────────────────────────────────────────

  void _goToPage(int page) {
    final target = page.clamp(1, MushafPageIndex.totalPages);
    _pageController.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showJumpDialog() {
    _pageInputController.text = _currentPage.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lbl_jump_to_page'.tr),
        content: TextField(
          controller: _pageInputController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'lbl_page'.tr,
            hintText: '1 - ${MushafPageIndex.totalPages}',
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value) ?? _currentPage;
            Navigator.pop(context);
            _goToPage(page);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lbl_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              final page =
                  int.tryParse(_pageInputController.text) ?? _currentPage;
              Navigator.pop(context);
              _goToPage(page);
            },
            child: Text('lbl_go'.tr),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('lbl_mushaf'.tr),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_return),
            onPressed: _showJumpDialog,
            tooltip: 'lbl_jump_to_page'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              reverse: true,
              itemCount: MushafPageIndex.totalPages,
              onPageChanged: (index) {
                setState(() => _currentPage = index + 1);
                PrefUtils().setMushafLastPage(index + 1);
              },
              itemBuilder: (context, index) =>
                  _buildPage(context, theme, isDark, index + 1),
            ),
          ),
          _buildPageIndicator(theme, isDark),
        ],
      ),
    );
  }

  /// Every page starts by fetching API data. All modes benefit from it.
  Widget _buildPage(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    int pageNumber,
  ) {
    return GestureDetector(
      onDoubleTap: _showJumpDialog,
      child: Container(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFBF0),
        child: Stack(
          children: [
            FutureBuilder<MushafPageData?>(
              future: _fetchApiPage(pageNumber),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final apiPage = snapshot.data;
                if (apiPage != null && !apiPage.isEmpty) {
                  return switch (_renderingMode) {
                    MushafRenderingConfig.ayahImagesMode =>
                      _buildAyahImagesPage(isDark, apiPage),
                    MushafRenderingConfig.glyphMode =>
                      _buildGlyphPage(isDark, apiPage),
                    _ => _buildTextPageFromApi(isDark, apiPage),
                  };
                }

                // Offline fallback: approximate local index
                return _buildOfflineTextPage(context, theme, isDark, pageNumber);
              },
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: _buildPageNumberBadge(isDark, pageNumber),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mode: Text (API-powered, accurate) ─────────────────────────────

  Widget _buildTextPageFromApi(bool isDark, MushafPageData apiPage) {
    return FutureBuilder<List<_VerseText>>(
      future: _loadTextForVerses(apiPage.verses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final verses = snapshot.data ?? [];
        if (verses.isEmpty) return const Center(child: Text('—'));

        return _buildTextContent(isDark, verses);
      },
    );
  }

  Widget _buildTextContent(bool isDark, List<_VerseText> verses) {
    final fontSize = PrefUtils().getQuranFontSize();
    final textColor =
        isDark ? const Color(0xFFE8D5B7) : const Color(0xFF1A1A1A);
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

      // Surah header when entering a new surah
      if (v.verseNumber == 1) {
        final surah = QuranIndex.quranSurahs[v.surahId - 1];
        if (i > 0) spans.add(const TextSpan(text: '\n'));
        spans.add(TextSpan(
          text: '${surah.nameArabic}\n',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color:
                isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
          ),
        ));
        if (v.showBismillah) {
          spans.add(const TextSpan(
            text: 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 20,
              color: Colors.grey,
            ),
          ));
        }
      }

      spans.add(TextSpan(
        text: '${v.text} ',
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: fontSize,
          height: 2.0,
          color: textColor,
        ),
      ));
      spans.add(TextSpan(
        text: ' ۝${_toArabicNumeral(v.verseNumber)} ',
        style: arabicVerseNumStyle,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }

  // ─── Mode: Ayah Images ──────────────────────────────────────────────

  Widget _buildAyahImagesPage(bool isDark, MushafPageData apiPage) {
    return FutureBuilder<List<_VerseText>>(
      future: _loadTextForVerses(apiPage.verses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final verses = snapshot.data ?? [];
        if (verses.isEmpty) return const Center(child: Text('—'));

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              // Surah header for first verse if it's verse 1
              if (verses.first.verseNumber == 1)
                _buildAyahSurahHeader(isDark, verses.first),
              const SizedBox(height: 4),
              ...verses
                  .where((v) => v.text.isNotEmpty)
                  .map((v) => _buildAyahImage(isDark, v)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAyahSurahHeader(bool isDark, _VerseText verse) {
    final surah = QuranIndex.quranSurahs[verse.surahId - 1];
    return Column(
      children: [
        Text(
          surah.nameArabic,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
          ),
        ),
        if (verse.showBismillah) ...[
          const SizedBox(height: 4),
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 18,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
        const Divider(height: 16, thickness: 0.5),
      ],
    );
  }

  Widget _buildAyahImage(bool isDark, _VerseText verse) {
    final imageUrl =
        MushafRenderingConfig.ayahImageUrl(verse.surahId, verse.verseNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.fitWidth,
        placeholder: (ctx, url) => const SizedBox(
          height: 28,
          child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
        ),
        errorWidget: (ctx, url, err) => _buildAyahTextFallback(isDark, verse),
      ),
    );
  }

  Widget _buildAyahTextFallback(bool isDark, _VerseText verse) {
    final fontSize = PrefUtils().getQuranFontSize();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        text: TextSpan(children: [
          TextSpan(
            text: '${verse.text} ',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: fontSize,
              height: 2.0,
              color: isDark
                  ? const Color(0xFFE8D5B7)
                  : const Color(0xFF1A1A1A),
            ),
          ),
          TextSpan(
            text: ' ۝${_toArabicNumeral(verse.verseNumber)} ',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: fontSize - 4,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Mode: QF Glyph ─────────────────────────────────────────────────

  Widget _buildGlyphPage(bool isDark, MushafPageData apiPage) {
    if (!apiPage.hasGlyphData) {
      // No glyph words — fallback to text
      return _buildTextPageFromApi(isDark, apiPage);
    }

    final lines = apiPage.glyphLines;
    if (lines.isEmpty) return const Center(child: Text('—'));

    final sortedLineNums = lines.keys.toList()..sort();
    final fontSize = PrefUtils().getQuranFontSize() + 4;
    final textColor =
        isDark ? const Color(0xFFE8D5B7) : const Color(0xFF1A1A1A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Text(
            'lbl_qf_attribution'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: sortedLineNums.map((lineNum) {
                  final glyphs = lines[lineNum]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.5),
                    child: Text(
                      glyphs.join(' '),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: fontSize,
                        height: 2.2,
                        color: textColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Offline Fallback (approximate local index) ─────────────────────

  Widget _buildOfflineTextPage(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    int pageNumber,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.brown.shade200,
          width: 0.5,
        ),
      ),
      child: FutureBuilder<List<_VerseText>>(
        future: _loadLocalPageText(pageNumber),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final verses = snapshot.data ?? [];
          if (verses.isEmpty ||
              (verses.length == 1 && verses.first.text.isEmpty)) {
            final surahId = MushafPageIndex.getSurahForPage(pageNumber);
            final surah = QuranIndex.quranSurahs[surahId - 1];
            return _buildPlaceholder(isDark, pageNumber, surah);
          }
          return Padding(
            padding: const EdgeInsets.only(
                left: 20, right: 20, top: 28, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOfflineHeader(isDark, verses),
                const SizedBox(height: 12),
                Expanded(child: _buildTextContent(isDark, verses)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineHeader(bool isDark, List<_VerseText> verses) {
    final surah = QuranIndex.quranSurahs[verses.first.surahId - 1];
    final isFirst = verses.first.verseNumber == 1;
    return Column(
      children: [
        if (isFirst) ...[
          Text(
            surah.nameArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (verses.first.showBismillah) ...[
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 22,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const Divider(height: 20, thickness: 0.5),
        ],
      ],
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────────────

  Widget _buildPlaceholder(bool isDark, int pageNumber, Surah surah) {
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
            '$pageNumber / ${MushafPageIndex.totalPages}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumberBadge(bool isDark, int pageNumber) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: (isDark
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFFFFFBF0))
              .withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 14,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(ThemeData theme, bool isDark) {
    final surahId = MushafPageIndex.getSurahForPage(_currentPage);
    final surah = QuranIndex.quranSurahs[surahId - 1];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? surah.nameArabic : surah.nameEnglish,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: _showJumpDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${'lbl_page'.tr} $_currentPage',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final n = int.tryParse(c);
      return n != null ? d[n] : c;
    }).join();
  }
}

/// Verse text loaded from local JSON assets.
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
