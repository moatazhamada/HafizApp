import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/utils/input_formatters.dart';
import '../../injection_container.dart';
import 'bloc/search_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../core/utils/rtl_utils.dart';
import '../../widgets/surah_list_item.dart';
import '../../widgets/loading_indicator.dart';

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
    try {
      _searchBloc = sl<SearchBloc>();
    } catch (e, s) {
      Logger.error('Failed to create SearchBloc: $e\n$s', feature: 'Search');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Defer focus request to avoid _ModalScopeStatus race during route transition
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
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
              inputFormatters: [
                AppInputFormatters.maxLength(100),
                AppInputFormatters.noLeadingSpaces,
              ],
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
          buildWhen: (previous, current) {
            // Skip rebuilds when the same loading state is re-emitted
            // (e.g. debounced keystrokes).
            if (previous.runtimeType != current.runtimeType) return true;
            if (current is SearchLoaded && previous is SearchLoaded) {
              return current.results.length != previous.results.length ||
                  current.verseResults.length != previous.verseResults.length;
            }
            return true;
          },
          builder: (context, state) {
            if (state is SearchLoading) {
              return const LoadingIndicator();
            } else if (state is SearchLoaded) {
              final totalResults =
                  state.results.length + state.verseResults.length;
              return CustomScrollView(
                slivers: [
                  // Online indicator when semantic results were used
                  if (state.isSemantic)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 16,
                          top: 8,
                        ),
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
                        padding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 16,
                          top: 16,
                          bottom: 8,
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
                        final surahIdx = verse.chapterNumber - 1;
                        final surah = surahIdx >= 0 && surahIdx < QuranIndex.quranSurahs.length
                            ? QuranIndex.quranSurahs[surahIdx]
                            : Surah(verse.chapterNumber, 'Surah ${verse.chapterNumber}', 'سورة ${verse.chapterNumber}');

                        final subtitleText = verse.translationText != null &&
                                verse.translationText!.isNotEmpty
                            ? verse.translationText!
                            : '${Localizations.localeOf(context).languageCode == 'ar' ? surah.nameArabic : surah.nameEnglish} • ${'lbl_ayah'.tr} ${verse.verseNumber.toLocalizedNumber(context)}';

                        return Semantics(
                          button: true,
                          label:
                              '${Localizations.localeOf(context).languageCode == 'ar' ? surah.nameArabic : surah.nameEnglish}, ${'lbl_ayah'.tr} ${verse.verseNumber}',
                          child: InkWell(
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: TextDirection.rtl,
                                children: [
                                  // Verse number badge (right side in RTL)
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${verse.verseNumber}',
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Text content (left side in RTL)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildHighlightedText(
                                          context,
                                          verse.arabicText,
                                          _searchController.text,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitleText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textDirection:
                                              verse.translationText != null &&
                                                      verse.translationText!
                                                          .isNotEmpty
                                                  ? TextDirection.ltr
                                                  : TextDirection.rtl,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.38)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
              return EmptyState(
                icon: Icons.search_off_rounded,
                message: 'msg_no_results'.tr,
              );
            } else if (state is SearchError) {
              return ErrorState(
                icon: Icons.error_outline_rounded,
                message: '${'lbl_error'.tr}: ${state.message}',
                onRetry: () => _searchBloc.add(SearchQueryChanged(_searchController.text)),
              );
            }
            // Initial state
            return EmptyState(
              icon: Icons.search_rounded,
              message: 'msg_search_hint'.tr,
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
