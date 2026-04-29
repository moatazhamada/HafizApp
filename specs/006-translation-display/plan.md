# Implementation Plan: Spec 006 — Translation Display

## Research Findings

- QF Content API: `/content/v1/translations/{id}/by_chapter/{surahId}` returns verse translations
- Default English: Sahih International (ID 131)
- VerseModel already has `translationText` field but `fromJson` never populates it
- Surah screen has two rendering modes but neither references translationText
- Search screen QF results have translation in response but UI ignores it

## Data Flow

```
QF Content API → QfTranslationRemoteDataSource → TranslationCache → SurahBloc/SurahScreen
                                                                     → SearchBloc/SearchScreen
```

## Implementation Steps

1. Create `QfTranslationRemoteDataSource` (new file)
2. Register in injection_container.dart
3. Update `VerseModel.fromJson` to parse translation when present
4. Add translation toggle to surah_screen AppBar
5. Fetch translations async in surah_screen, cache per surah
6. Render translation below each verse (both rich-text and single-line modes)
7. Show translation in search results
8. Persist toggle state in PrefUtils
9. Add i18n strings for translation toggle

## Key Decisions

- Translations fetched independently from surah data (separate API call, async)
- In-memory cache: `Map<int, Map<int, String>>` (surahId → verseNumber → translation)
- QF Content API is primary source (not Quran.com)
- Translation toggle is a global toggle in the surah AppBar
