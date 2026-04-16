import 'package:flutter/material.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                final surahId = MushafPageIndex.getSurahForPage(pageNumber);
                final surah = QuranIndex.quranSurahs[surahId - 1];

                return _buildMushafPage(
                  context,
                  theme,
                  isDark,
                  isArabic,
                  pageNumber,
                  surah,
                );
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
    bool isArabic,
    int pageNumber,
    Surah surah,
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    surah.nameArabic,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? surah.nameArabic : surah.nameEnglish,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Icon(
                    Icons.menu_book_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.brown.shade100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$pageNumber / ${MushafPageIndex.totalPages}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 12,
              child: Text(
                pageNumber.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
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
