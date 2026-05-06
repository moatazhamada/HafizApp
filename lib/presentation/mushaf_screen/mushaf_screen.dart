import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/data/datasource/mushaf/qf_mushaf_page_data_source.dart';
import 'package:hafiz_app/injection_container.dart';
import 'bloc/mushaf_bloc.dart';
import 'bloc/mushaf_event.dart';
import 'bloc/mushaf_state.dart';
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
  late MushafBloc _bloc;
  final Set<int> _loadingPages = {};
  final Set<int> _errorPages = {};
  final Map<int, MushafPageData?> _pageDataMap = {};
  bool _showOverlay = true;
  bool _dualPage = false;

  @override
  void initState() {
    super.initState();
    _bloc = MushafBloc(dataSource: sl<QfMushafPageDataSource>());
    _dualPage = PrefUtils().getMushafDualPage();
    final resolved = widget.initialPage ?? PrefUtils().getMushafLastPage();
    _currentPage = resolved.clamp(1, MushafPageIndex.totalPages);
    _pageController = PageController(
      initialPage: _currentPage - 1,
      viewportFraction: 1.0,
    );
    _bloc.add(LoadPage(_currentPage));
    _bloc.stream.listen(_onBlocState);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onBlocState(MushafState state) {
    if (!mounted) return;
    setState(() {
      if (state is MushafPageLoading) {
        _loadingPages.add(state.pageNumber);
        _errorPages.remove(state.pageNumber);
      } else if (state is MushafPageLoaded) {
        _loadingPages.remove(state.pageNumber);
        _errorPages.remove(state.pageNumber);
        _pageDataMap[state.pageNumber] = state.pageData;
      } else if (state is MushafPageError) {
        _loadingPages.remove(state.pageNumber);
        _errorPages.add(state.pageNumber);
        _pageDataMap.remove(state.pageNumber);
      } else if (state is MushafDualPageToggled) {
        _dualPage = state.dualPageEnabled;
      }
    });
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
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MushafJumpDialog(currentPage: _currentPage),
    ).then((page) {
      if (page != null && page != _currentPage) {
        _goToPage(page);
      }
    });
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.mushafPageBg,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              reverse: false,
              itemCount: MushafPageIndex.totalPages,
              onPageChanged: (index) {
                final page = index + 1;
                setState(() => _currentPage = page);
                PrefUtils().setMushafLastPage(page);
                _bloc.add(LoadPage(page));
                final nextPages = [page - 1, page + 1, page + 2]
                    .where((p) => p >= 1 && p <= MushafPageIndex.totalPages)
                    .toList();
                _bloc.add(PrefetchPages(nextPages));
                if (_showOverlay) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _showOverlay = false);
                  });
                }
              },
              itemBuilder: (context, index) {
                final page = index + 1;
                return _buildPageContent(page, isDark, colors);
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
    );
  }

  Widget _buildPageContent(int page, bool isDark, AppColors colors) {
    return Stack(
      children: [
        MushafPageWidget(
          pageNumber: page,
          pageData: _pageDataMap[page],
          isLoading: _loadingPages.contains(page),
          isDark: isDark,
          errorMessage: _errorPages.contains(page) ? 'Tap to retry' : '',
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    colors.mushafPageBg,
                    colors.mushafPageBg.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.mushafPageBg,
                    colors.mushafPageBg.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isDark, AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.mushafPageBg,
            colors.mushafPageBg.withValues(alpha: 0.9),
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
                icon: Icon(Icons.search, color: colors.textPrimary),
                onPressed: _showJumpDialog,
                tooltip: 'lbl_jump_to_page'.tr,
              ),
              IconButton(
                icon: Icon(
                  _dualPage ? Icons.book : Icons.chrome_reader_mode,
                  color: colors.textPrimary,
                ),
                onPressed: () => _bloc.add(const ToggleDualPage()),
                tooltip: 'Toggle dual page',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, AppColors colors) {
    final surahId = MushafPageIndex.getSurahForPage(_currentPage);
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
            colors.mushafPageBg.withValues(alpha: 0.9),
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
                    'Juz $juz',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textHint,
                    ),
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
                        _toArabicNumeral(_currentPage),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_currentPage / ${MushafPageIndex.totalPages}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavArrow(true, isArabic),
                  _buildNavArrow(false, isArabic),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavArrow(bool isPrev, bool isArabic) {
    final surahId = MushafPageIndex.getSurahForPage(_currentPage);
    final targetSurahId = isPrev ? surahId - 1 : surahId + 1;
    if (targetSurahId < 1 || targetSurahId > 114) {
      return const SizedBox(width: 80);
    }
    final targetSurah = QuranIndex.quranSurahs[targetSurahId - 1];
    final targetPage = MushafPageIndex.getPageForSurah(targetSurahId);

    return TextButton.icon(
      onPressed: () => _goToPage(targetPage),
      icon: Icon(
        isPrev ? Icons.skip_previous : Icons.skip_next,
        size: 18,
      ),
      label: Text(
        isArabic ? targetSurah.nameArabic : targetSurah.nameEnglish,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const d = [
      '\u0660', '\u0661', '\u0662', '\u0663', '\u0664',
      '\u0665', '\u0666', '\u0667', '\u0668', '\u0669',
    ];
    return number.toString().split('').map((c) {
      final n = int.tryParse(c);
      return n != null ? d[n] : c;
    }).join();
  }
}
