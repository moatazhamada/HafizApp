import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart';
import 'bloc/search_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../widgets/surah_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchBloc _searchBloc = sl<SearchBloc>();

  @override
  void dispose() {
    _searchController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _searchBloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => NavigatorService.goBack(),
          ),
          title: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: 'Search Surah...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              _searchBloc.add(SearchQueryChanged(value));
            },
          ),
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading) {
              return const Center(child: CircularProgressIndicator());
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
                        child: Text(
                          'Surahs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final surah = state.results[index];
                        return InkWell(
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
                        child: Text(
                          'Verses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final verse = state.verseResults[index];
                        // Find surah info for display
                        final surah = QuranIndex.quranSurahs.firstWhere(
                          (s) => s.id == verse.chapterId,
                          orElse: () => QuranIndex.quranSurahs[0], // fallback
                        );

                        return ListTile(
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
                        );
                      }, childCount: state.verseResults.length),
                    ),
                  ],
                ],
              );
            } else if (state is SearchEmpty) {
              return const Center(child: Text('No results found.'));
            } else if (state is SearchError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            // Initial state
            return const Center(child: Text('Type to search for a Surah.'));
          },
        ),
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
    if (query.isEmpty) return _plainText(fullText);

    // Heuristic for simple substring match, respecting Diacritics
    final normalizedFull = _removeTashkeel(fullText);
    final normalizedQuery = _removeTashkeel(query);

    if (normalizedQuery.isEmpty) return _plainText(fullText);

    final startIndexNorm = normalizedFull.indexOf(normalizedQuery);
    if (startIndexNorm == -1) {
      return _plainText(fullText);
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

    if (originalStart == -1 || originalEnd == -1) return _plainText(fullText);

    return RichText(
      textDirection: TextDirection.rtl,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 18,
          color:
              Colors.black, // Default color, will use Theme in real app ideally
        ),
        children: [
          TextSpan(
            text: fullText.substring(0, originalStart),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          TextSpan(
            text: fullText.substring(originalStart, originalEnd),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber.withValues(alpha: 0.4)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
          TextSpan(
            text: fullText.substring(originalEnd),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
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

  Widget _plainText(String text) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
    );
  }
}
