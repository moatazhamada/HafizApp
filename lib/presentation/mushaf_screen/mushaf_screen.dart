import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import '../../core/app_export.dart';
import '../../core/mushaf/mushaf_rendering_config.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/quran_surah.dart';

class MushafScreen extends StatefulWidget {
  final int? initialPage;

  const MushafScreen({super.key, this.initialPage});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _currentPage;
  final TextEditingController _pageInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final resolved = widget.initialPage ?? PrefUtils().getMushafLastPage();
    _currentPage = resolved.clamp(1, MushafPageIndex.totalPages);
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageInputController.dispose();
    super.dispose();
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
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
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                int sliderValue =
                    int.tryParse(_pageInputController.text) ?? _currentPage;
                sliderValue = sliderValue.clamp(1, MushafPageIndex.totalPages);
                return Slider(
                  value: sliderValue.toDouble(),
                  min: 1,
                  max: MushafPageIndex.totalPages.toDouble(),
                  divisions: MushafPageIndex.totalPages - 1,
                  label: '$sliderValue',
                  onChanged: (value) {
                    setDialogState(() {});
                    _pageInputController.text = value.toInt().toString();
                  },
                );
              },
            ),
          ],
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.mushafPageBg,
      appBar: AppBar(
        title: Text(_getPageTitle()),
        centerTitle: true,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
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
              itemBuilder: (context, index) => _buildPage(isDark, index + 1),
            ),
          ),
          _buildPageIndicator(theme, isDark),
        ],
      ),
    );
  }

  String _getPageTitle() {
    final surahId = MushafPageIndex.getSurahForPage(_currentPage);
    final surah = QuranIndex.quranSurahs[surahId - 1];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? surah.nameArabic : surah.nameEnglish;
  }

  // ─── Page Builder ───────────────────────────────────────────────────

  Widget _buildPage(bool isDark, int pageNumber) {
    final ranges = MushafPageIndex.getVersesForPage(pageNumber);
    if (ranges.isEmpty) {
      return Center(child: Text('lbl_verse_unavailable'.tr));
    }

    // Build flat list of (surahId, verseNumber, isSurahStart, showBismillah)
    final ayahs = <_AyahRef>[];
    for (final range in ranges) {
      final surah = QuranIndex.quranSurahs[range.surahId - 1];
      final isSurahStart = range.startVerse == 1;
      final showBismillah =
          isSurahStart && range.surahId != 1 && range.surahId != 9;

      if (isSurahStart) {
        ayahs.add(
          _AyahRef(
            surahId: range.surahId,
            verseNumber: 0, // sentinel for surah header
            surahNameArabic: surah.nameArabic,
            showBismillah: showBismillah,
          ),
        );
      }

      for (int v = range.startVerse; v <= range.endVerse; v++) {
        ayahs.add(
          _AyahRef(
            surahId: range.surahId,
            verseNumber: v,
            surahNameArabic: surah.nameArabic,
            showBismillah: false,
          ),
        );
      }
    }

    return GestureDetector(
      onDoubleTap: _showJumpDialog,
      child: Container(
        color: AppColors.of(context).mushafPageBg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ayahs.map((ref) {
                          if (ref.verseNumber == 0) {
                            return _buildSurahHeader(isDark, ref);
                          }
                          return _buildAyahImage(isDark, ref);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                // Page number badge
                _buildPageNumberBadge(isDark, pageNumber),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Surah Header ───────────────────────────────────────────────────

  Widget _buildSurahHeader(bool isDark, _AyahRef ref) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            ref.surahNameArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ),
        if (ref.showBismillah)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 \u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0670\u0646\u0650 \u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 16,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        Divider(
          height: 12,
          thickness: 0.5,
          color: isDark
              ? colors.mushafPageBorder.withValues(alpha: 0.4)
              : colors.mushafPageBorder,
        ),
      ],
    );
  }

  // ─── Ayah Image ─────────────────────────────────────────────────────

  Widget _buildAyahImage(bool isDark, _AyahRef ref) {
    final imageUrl = MushafRenderingConfig.ayahImageUrl(
      ref.surahId,
      ref.verseNumber,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.fitWidth,
        placeholder: (ctx, url) => const SizedBox(
          height: 28,
          child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
        ),
        errorWidget: (ctx, url, err) => _buildAyahNumberFallback(isDark, ref),
      ),
    );
  }

  /// Minimal fallback when an ayah image fails to load — just show the verse number.
  Widget _buildAyahNumberFallback(bool isDark, _AyahRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '\u06DD${_toArabicNumeral(ref.verseNumber)}',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 14,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }

  // ─── Page Number Badge ──────────────────────────────────────────────

  Widget _buildPageNumberBadge(bool isDark, int pageNumber) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.of(context).mushafPageBg.withValues(alpha: 0.8),
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
      ),
    );
  }

  // ─── Bottom Page Indicator ──────────────────────────────────────────

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

  // ─── Helpers ────────────────────────────────────────────────────────

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

/// Lightweight reference to a single ayah on a page.
/// verseNumber == 0 is a sentinel meaning "this is a surah header".
class _AyahRef {
  final int surahId;
  final int verseNumber;
  final String surahNameArabic;
  final bool showBismillah;

  const _AyahRef({
    required this.surahId,
    required this.verseNumber,
    required this.surahNameArabic,
    required this.showBismillah,
  });
}
