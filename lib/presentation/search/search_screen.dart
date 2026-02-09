import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart';
import 'bloc/search_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../widgets/surah_list_item.dart';
import '../../widgets/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<SearchBloc>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              leading: Semantics(
                button: true,
                label: 'lbl_back'.tr,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => NavigatorService.goBack(),
                ),
              ),
              title: Semantics(
                textField: true,
                label: 'lbl_search_surah'.tr,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'lbl_search_surah'.tr,
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    context.read<SearchBloc>().add(SearchQueryChanged(value));
                  },
                ),
              ),
            ),
            body: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 8,
                    itemBuilder: (context, index) => const SkeletonListItem(),
                  );
                } else if (state is SearchLoaded) {
                  return CustomScrollView(
                    slivers: [
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
                                'lbl_surahs'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final surah = state.results[index];
                            return Semantics(
                              button: true,
                              label:
                                  '${surah.nameEnglish}, ${surah.nameArabic}',
                              child: InkWell(
                                onTap: () {
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
                                'lbl_verses'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final verse = state.verseResults[index];
                            // Find surah info for display
                            final surah = QuranIndex.quranSurahs.firstWhere(
                              (s) => s.id == verse.chapterId,
                              orElse: () =>
                                  QuranIndex.quranSurahs[0], // fallback
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
                                  NavigatorService.pushNamed(
                                    AppRoutes.surahPage,
                                    arguments: {
                                      'surah': surah,
                                      'verseIndex': verse.verseNumber - 1,
                                      'resume': true,
                                    },
                                  );
                                },
                                title: _buildHighlightedText(
                                  context,
                                  verse.text, // Full Uthmani Text
                                  _searchActionTextForHighlighting(
                                    _searchController.text,
                                  ),
                                ),
                                subtitle: Text(
                                  '${Localizations.localeOf(context).languageCode == 'ar' ? surah.nameArabic : surah.nameEnglish} • ${'lbl_ayah'.tr} ${verse.verseNumber.toLocalizedNumber(context)}',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : null,
                                  ),
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${verse.verseNumber}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }, childCount: state.verseResults.length),
                        ),
                      ],
                    ],
                  );
                } else if (state is SearchEmpty) {
                  return Center(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        'msg_no_results'.tr,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                } else if (state is SearchError) {
                  return Center(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        '${'lbl_error'.tr}: ${state.message}',
                        style: TextStyle(
                          color: isDark ? Colors.redAccent : Colors.red,
                        ),
                      ),
                    ),
                  );
                }
                // Initial state
                return Center(
                  child: Text(
                    'msg_search_hint'.tr,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Matches implementation in SurahLocalDataSource
  String _removeTashkeel(String text) {
    final tashkeel = RegExp(
      r'[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
    );
    return text.replaceAll(tashkeel, '');
  }

  // Use current search query, handling potential state issues if BLoC isn't perfectly synced with controller
  // But controller text is what matches user input.
  String _searchActionTextForHighlighting(String query) => query;

  Widget _buildHighlightedText(
    BuildContext context,
    String fullText,
    String query,
  ) {
    if (query.isEmpty) return _plainText(context, fullText);

    // Heuristic for simple substring match, respecting Diacritics
    final normalizedFull = _removeTashkeel(fullText);
    final normalizedQuery = _removeTashkeel(query);

    if (normalizedQuery.isEmpty) return _plainText(context, fullText);

    final startIndexNorm = normalizedFull.indexOf(normalizedQuery);
    if (startIndexNorm == -1) {
      return _plainText(context, fullText);
    } // Should match if logic is correct

    // Now map normalized indices back to original indices.
    // This is O(N) but N is small (verse length).

    int originalStart = -1;
    int originalEnd = -1;

    int normIndex = 0;
    int queryLen = normalizedQuery.length;
    int matchCount = 0;

    for (int i = 0; i < fullText.length; i++) {
      final char = fullText[i];
      if (_isTashkeel(char)) {
        // Skip tashkeel in "alignment" check
        continue;
      }

      // char is a base letter/symbol. matches normalizedFull[normIndex]
      if (normIndex == startIndexNorm) {
        originalStart = i;
      }

      if (normIndex >= startIndexNorm &&
          normIndex < startIndexNorm + queryLen) {
        matchCount++;
      }

      if (matchCount == queryLen) {
        // We found the last char of the match.
        // But we need to include subsequent tashkeel if any?
        // Usually we mark end AFTER this char.
        // We'll peek ahead for tashkeel later or just let the span loop handle generic run.
        // Actually, we need precise index.
        originalEnd = i + 1;
        break;
      }

      normIndex++;
    }

    // Include trailing diacritics in the highlight if they belong to the last letter?
    // Yes, visually better.
    while (originalEnd < fullText.length &&
        _isTashkeel(fullText[originalEnd])) {
      originalEnd++;
    }

    if (originalStart == -1 || originalEnd == -1) {
      return _plainText(context, fullText);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;
    final subtleColor = isDark
        ? Colors.grey[400]
        : Theme.of(context).textTheme.bodyMedium?.color;

    return RichText(
      textDirection: TextDirection.rtl,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: textColor),
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
                  ? const Color(0xFF004B40)
                  : Theme.of(context).primaryColor,
              backgroundColor: isDark
                  ? Colors.amberAccent
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

  bool _isTashkeel(String char) {
    return RegExp(
      r'[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
    ).hasMatch(char);
  }

  Widget _plainText(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 18,
        color: isDark ? Colors.white : null,
      ),
    );
  }
}
