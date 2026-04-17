import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/quran_surah.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;

  const MushafScreen({super.key, this.initialPage = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _currentPage;
  final TextEditingController _pageInputController = TextEditingController();
  final Map<int, List<_VerseEntry>> _cache = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, MushafPageIndex.totalPages);
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  Future<List<_VerseEntry>> _loadVersesForPage(int pageNumber) async {
    if (_cache.containsKey(pageNumber)) return _cache[pageNumber]!;

    final ranges = MushafPageIndex.getVersesForPage(pageNumber);
    final List<_VerseEntry> entries = [];

    for (final range in ranges) {
      final surah = QuranIndex.quranSurahs[range.surahId - 1];
      final showBismillah =
          range.startVerse == 1 && range.surahId != 1 && range.surahId != 9;

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
              _VerseEntry(
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
          _VerseEntry(
            surahId: range.surahId,
            verseNumber: 0,
            text: '',
            surahNameArabic: surah.nameArabic,
            showBismillah: false,
          ),
        );
      }
    }

    _cache[pageNumber] = entries;
    return entries;
  }

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
                setState(() {
                  _currentPage = index + 1;
                });
              },
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                return _buildMushafPage(context, theme, isDark, pageNumber);
              },
            ),
          ),
          _buildPageIndicator(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildMushafPage(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    int pageNumber,
  ) {
    return GestureDetector(
      onDoubleTap: _showJumpDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.brown.shade200,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            FutureBuilder<List<_VerseEntry>>(
              future: _loadVersesForPage(pageNumber),
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
                    left: 20,
                    right: 20,
                    top: 28,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPageHeader(isDark, verses),
                      const SizedBox(height: 12),
                      Expanded(child: _buildVerseContent(isDark, verses)),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFFFFFBF0))
                            .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pageNumber',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
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

  Widget _buildPageHeader(bool isDark, List<_VerseEntry> verses) {
    final surah = QuranIndex.quranSurahs[verses.first.surahId - 1];
    final isFirstVerseOfSurah = verses.first.verseNumber == 1;

    return Column(
      children: [
        if (isFirstVerseOfSurah) ...[
          Text(
            surah.nameArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
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
              fontFamily: 'Amiri',
              fontSize: 22,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const Divider(height: 20, thickness: 0.5),
        ],
      ],
    );
  }

  Widget _buildVerseContent(bool isDark, List<_VerseEntry> verses) {
    final fontSize = PrefUtils().getQuranFontSize();
    final textColor = isDark
        ? const Color(0xFFE8D5B7)
        : const Color(0xFF1A1A1A);
    final verseNumColor = isDark ? Colors.white38 : Colors.black38;

    final List<InlineSpan> spans = [];
    final arabicVerseNum = TextStyle(
      fontFamily: 'Amiri',
      fontSize: fontSize - 4,
      color: verseNumColor,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < verses.length; i++) {
      final entry = verses[i];

      if (i > 0 && entry.surahId != verses[i - 1].surahId) {
        final nextSurah = QuranIndex.quranSurahs[entry.surahId - 1];
        spans.add(
          TextSpan(
            text: '\n${nextSurah.nameArabic}\n',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
            ),
          ),
        );
        if (entry.showBismillah) {
          spans.add(
            TextSpan(
              text: 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: fontSize - 2,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          );
        }
      }

      spans.add(
        TextSpan(
          text: '${entry.text} ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize,
            height: 1.9,
            color: textColor,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: ' \u06DD${_toArabicNumeral(entry.verseNumber)} ',
          style: arabicVerseNum,
        ),
      );
    }

    return SingleChildScrollView(
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        text: TextSpan(children: spans),
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) {
      final n = int.tryParse(d);
      return n != null ? arabicDigits[n] : d;
    }).join();
  }

  Widget _buildPlaceholder(bool isDark, int pageNumber, Surah surah) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            surah.nameArabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
}

class _VerseEntry {
  final int surahId;
  final int verseNumber;
  final String text;
  final String surahNameArabic;
  final bool showBismillah;

  const _VerseEntry({
    required this.surahId,
    required this.verseNumber,
    required this.text,
    required this.surahNameArabic,
    required this.showBismillah,
  });
}
