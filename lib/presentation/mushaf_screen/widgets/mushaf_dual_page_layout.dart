import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/data/datasource/mushaf/qf_mushaf_page_data_source.dart';
import 'package:hafiz_app/presentation/mushaf_screen/widgets/mushaf_page_widget.dart';

class MushafDualPageLayout extends StatelessWidget {
  final int leftPage;
  final int rightPage;
  final Map<int, MushafPageData?> pageDataMap;
  final Set<int> loadingPages;
  final Set<int> errorPages;
  final bool isDark;

  const MushafDualPageLayout({
    super.key,
    required this.leftPage,
    required this.rightPage,
    required this.pageDataMap,
    required this.loadingPages,
    required this.errorPages,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildPage(context, leftPage),
        ),
        Container(
          width: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildPage(context, rightPage),
        ),
      ],
    );
  }

  Widget _buildPage(BuildContext context, int page) {
    if (page < 1 || page > MushafPageIndex.totalPages) {
      return const SizedBox.shrink();
    }

    return MushafPageWidget(
      pageNumber: page,
      pageData: pageDataMap[page],
      isLoading: loadingPages.contains(page),
      isDark: isDark,
      errorMessage: errorPages.contains(page) ? 'Error loading page' : '',
    );
  }
}
