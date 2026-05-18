import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/analytics/analytics_service.dart';
import '../../injection_container.dart';
import 'bloc/search_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../core/utils/rtl_utils.dart';
import '../../widgets/surah_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final SearchBloc _searchBloc;
  bool _initializedFromRoute = false;

  @override
  void initState() {
    super.initState();
    _searchBloc = sl<SearchBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initializedFromRoute) {
      _initializedFromRoute = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final initialQuery = args['query'] as String?;
        if (initialQuery != null && initialQuery.isNotEmpty) {
          _searchController.text = initialQuery;
          _searchBloc.add(SearchQueryChanged(initialQuery));
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return BlocProvider<SearchBloc>.value(
      value: _searchBloc,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: Semantics(
            button: true,
            label: 'lbl_back'.tr,
            child: IconButton(
              icon: Icon(rtlBackArrow(context), color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () => NavigatorService.goBack(),
              tooltip: 'lbl_back'.tr,
            ),
          ),
          title: Semantics(
            textField: true,
            label: 'lbl_search_surah'.tr,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
              cursorColor: Theme.of(context).colorScheme.onPrimary,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'lbl_search_surah'.tr,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
                border: InputBorder.none,
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    if (value.text.isNotEmpty) {
                      return IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
                        onPressed: () {
                          _searchController.clear();
                          _searchBloc.add(const SearchQueryChanged(''));
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              onChanged: (value) {
                _searchBloc.add(SearchQueryChanged(value));
              },
            ),
          ),
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SearchLoaded) {
              final totalResults =
                  state.results.length + state.verseResults.length;
              return CustomScrollView(
                slivers: [
                  // Online indicator when semantic results were used
                  if (state.isSemantic)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_outlined,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'msg_search_online'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Surah name results
                  if (state.results.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            '${'lbl_surahs'.tr} (${state.results.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Theme.of(context).colorScheme.onSurface : theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final surah = state.results[index];
                        return Semantics(
                          button: true,
                          label: '${surah.nameEnglish}, ${surah.nameArabic}',
                          child: InkWell(
                            onTap: () {
                              unawaited(
                                sl<AnalyticsService>().logSearchResultTapped(
                                  query: _searchController.text,
                                  resultType: 'surah',
                                  resultIndex: index,
                                ),
                              );
                              NavigatorService.pushNamed(
                                AppRoutes.surahPage,
                                arguments: surah,
                              );
                            },
                            child: SurahListItem(
                              surahId: surah.id,
                              nameEnglish: surah.nameEnglish,
                              nameArabic: surah.nameArabic,
                            ),
                          ),
                        );
                      }, childCount: state.results.length),
                    ),
                  ],

                  // Verse results
                  if (state.verseResults.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          16.0,
                          16.0,
                          8.0,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            '${'lbl_verses'.tr} (${state.verseResults.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Theme.of(context).colorScheme.onSurface : theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final verse = state.verseResults[index];
                        final surah = QuranIndex.quranSurahs.firstWhere(
                          (s) => s.id == verse.chapterNumber,
                            orElse: () {
                              Logger.warning('Invalid surahId: ${verse.chapterNumber}', feature: 'Search');
                              return Surah(verse.chapterNumber, 'Surah ${verse.chapterNumber}', 'سورة ${verse.chapterNumber}');
                            },
                        );

                        return Semantics(
                          button: true,
                          label:
                              '${Localizations.localeOf(context).languageCode == 'ar' ? surah.nameArabic : surah.nameEnglish}, ${'lbl_ayah'.tr} ${verse.verseNumber}',
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            onTap: () {
                              unawaited(
                                sl<AnalyticsService>().logSearchResultTapped(
                                  query: _searchController.text,
                                  resultType: 'verse',
                                  resultIndex: index,
                                ),
                              );
                              NavigatorService.pushNamed(
                                AppRoutes.surahPage,
                                arguments: {
                                  'surah': surah,
                                  'verseIndex': verse.verseNumber - 1,
                                },
                              );
                            },
                            title: _buildHighlightedText(
                              context,
                              verse.arabicText,
                              _searchController.text,
                            ),
                            subtitle:
                                verse.translationText != null &&
                                    verse.translationText!.isNotEmpty
                                ? Text(
                                    verse.translationText!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  )
                                : Text(
                                    '${Localizations.localeOf(context).languageCode == 'ar' ? surah.nameArabic : surah.nameEnglish} • ${'lbl_ayah'.tr} ${verse.verseNumber.toLocalizedNumber(context)}',
                                    style: TextStyle(
                                      color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38) : null,
                                    ),
                                  ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${verse.verseNumber}',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: state.verseResults.length),
                    ),
                  ],

                  // Result count footer
                  if (totalResults > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '$totalResults ${'msg_results_count'.tr}',
                            style: TextStyle(
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else if (state is SearchEmpty) {
              return Center(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'msg_no_results'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is SearchError) {
              return Center(
                child: Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: isDark
                              ? AppColors.of(context).needsReviewStatus.withValues(alpha: 0.7)
                              : AppColors.of(context).needsReviewStatus.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${'lbl_error'.tr}: ${state.message}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.of(context).needsReviewStatus,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            // Initial state
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'msg_search_hint'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static final RegExp _tashkeelPattern = RegExp(
    r'[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
  );

  String _removeTashkeel(String text) => text.replaceAll(_tashkeelPattern, '');

  Widget _buildHighlightedText(
    BuildContext context,
    String fullText,
    String query,
  ) {
    if (query.isEmpty) return _plainText(context, fullText);

    final normalizedFull = _removeTashkeel(fullText);
    final normalizedQuery = _removeTashkeel(query);

    if (normalizedQuery.isEmpty) return _plainText(context, fullText);

    final startIndexNorm = normalizedFull.indexOf(normalizedQuery);
    if (startIndexNorm == -1) return _plainText(context, fullText);

    int originalStart = -1;
    int originalEnd = -1;
    int normIndex = 0;
    int queryLen = normalizedQuery.length;
    int matchCount = 0;

    for (int i = 0; i < fullText.length; i++) {
      final char = fullText[i];
      if (_isTashkeel(char)) continue;

      if (normIndex == startIndexNorm) originalStart = i;

      if (normIndex >= startIndexNorm &&
          normIndex < startIndexNorm + queryLen) {
        matchCount++;
      }

      if (matchCount == queryLen) {
        originalEnd = i + 1;
        break;
      }

      normIndex++;
    }

    while (originalEnd < fullText.length &&
        _isTashkeel(fullText[originalEnd])) {
      originalEnd++;
    }

    if (originalStart == -1 || originalEnd == -1) {
      return _plainText(context, fullText);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).textTheme.bodyLarge?.color;
    final subtleColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
        : Theme.of(context).textTheme.bodyMedium?.color;

    return RichText(
      textDirection: TextDirection.rtl,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: PrefUtils().getQuranFontSize(),
          color: textColor,
        ),
        children: [
          TextSpan(
            text: fullText.substring(0, originalStart),
            style: TextStyle(color: subtleColor),
          ),
          TextSpan(
            text: fullText.substring(originalStart, originalEnd),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.of(context).bismillahColor
                  : Theme.of(context).primaryColor,
              backgroundColor: isDark
                  ? AppColors.of(context).warning.withValues(alpha: 0.3)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
          TextSpan(
            text: fullText.substring(originalEnd),
            style: TextStyle(color: subtleColor),
          ),
        ],
      ),
    );
  }

  bool _isTashkeel(String char) => _tashkeelPattern.hasMatch(char);

  Widget _plainText(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'NotoNaskhArabic',
        fontSize: PrefUtils().getQuranFontSize(),
        color: isDark ? Theme.of(context).colorScheme.onSurface : null,
      ),
    );
  }
}
