# Plan: Fix All Found Issues

**Created:** 2026-04-17
**Based on:** Test report v3.0.0+14 (`testing/test-report-v3.0.0+14-2026-04-17.md`)
**Branch:** master at `cdcc5bf`

---

## Issue Inventory (11 issues, 6 branches/PRs)

| # | Severity | Issue | Branch | Effort |
|---|----------|-------|--------|--------|
| 1 | HIGH | Mushaf screen shows placeholder, no Quran text | `feature/mushaf-text-rendering` | Large |
| 2 | MEDIUM | Audio player has no verse progress display | `feature/audio-verse-tracking` | Medium |
| 3 | MEDIUM | Audio player always uses Alafasy (reciter setting ignored) | `fix/audio-reciter-selection` | Small |
| 4 | MEDIUM | Statistics "surahs completed" hardcoded to 0 | `fix/statistics-real-data` | Small |
| 5 | MEDIUM | Orientation setting requires app restart | `fix/orientation-hot-swap` | Small |
| 6 | LOW | Reading Navigation Mode setting not consumed | **SKIP** — Remove from UI | N/A |
| 7 | LOW | Mushaf type selection saved but never consumed | Same branch as #1 | Trivial |
| 8 | LOW | Deprecated `SemanticsService.announce` | Same branch as any above | Trivial |
| 9 | LOW | Multiple screens use `PrefUtils().getIsDarkMode()` instead of `Theme.of(context)` | `fix/theme-context-usage` | Small |
| 10 | LOW | Bookmarks/Recitation Error screens have hardcoded AppBar color | Same branch as #9 | Trivial |
| 11 | INFO | `unnecessary_non_null_assertion` warnings in surah_screen.dart | Skip | N/A |

---

## Branch 1: `feature/mushaf-text-rendering`
**PR Title:** `feat: Render Quran verse text on mushaf pages`

### What's wrong
The mushaf screen (`lib/presentation/mushaf_screen/mushaf_screen.dart`) shows only the surah name and a book icon placeholder. No actual Quran text is rendered per page.

### Files to change
- `lib/core/quran_index/mushaf_page_index.dart` — Add page-to-verse range mapping
- `lib/presentation/mushaf_screen/mushaf_screen.dart` — Load and render verse text per page

### Implementation
1. **Add page-to-verse data** in `mushaf_page_index.dart`:
   - Add a `static const List<MushafPageRange> _pageRanges` list with 604 entries, each containing `{startSurah, startVerse, endSurah, endVerse}`
   - Add method `static MushafPageRange getVersesForPage(int page)` 
   - This is the largest effort — the data needs to be accurate. Source: standard Madani mushaf page-to-verse mapping (available from Tanzil or quran.com datasets)
   - Alternative: compute ranges from the surah start pages + verse counts dynamically (less accurate for multi-surah pages)

2. **Load verse text per page** in `mushaf_screen.dart`:
   - In `_buildMushafPage`, call `MushafPageIndex.getVersesForPage(pageNumber)` to get the verse range
   - Load the surah JSON(s) from assets, extract the relevant verses
   - Render them in RTL with proper formatting (same Amiri font, `textDirection: TextDirection.rtl`)
   - Handle multi-surah pages (e.g., page 1 has only Al-Fatihah, but later pages may span two surahs)
   - Include bismillah display at surah boundaries

3. **Consume mushaf type** (Issue #7):
   - Read `PrefUtils().getMushafType()` to determine font/style variant
   - For now, all types use the same Uthmani text. The setting is a placeholder for future font variants.

### Translation keys needed
- None (page numbers and verse text don't need translation)

---

## Branch 2: `feature/audio-verse-tracking`
**PR Title:** `feat: Audio player verse progress display`

### What's wrong
The audio player screen shows play/pause/speed but doesn't display which verse is currently playing. The handler already emits verse index via `currentVerseStream`.

### Files to change
- `lib/presentation/audio_player/audio_player_screen.dart` — Add verse progress UI

### Implementation
1. **Listen to verse stream** — Already partially done in `initState`:
   ```dart
   _handler.currentVerseStream.listen((verseIndex) {
     if (mounted) setState(() {});
   });
   ```
   But `setState` doesn't update any verse-specific UI. Store the verse index:
   ```dart
   int _currentVerse = -1;
   // In listener:
   _currentVerse = verseIndex;
   ```

2. **Add verse progress indicator** below the surah name:
   - Show "Verse X / Y" with a LinearProgressIndicator
   - Use `_getVerseCount(widget.surahId)` for total
   - Text direction: RTL for Arabic verse numbers

3. **Add verse text preview** (optional, nice-to-have):
   - Load the current verse's Arabic text from the surah JSON
   - Display in RTL below the progress bar
   - This requires loading the surah JSON, which is an async operation — consider caching

---

## Branch 3: `fix/audio-reciter-selection`
**PR Title:** `fix: Wire reciter setting to audio player URL builder`

### What's wrong
`audio_player_screen.dart` hardcodes `ar.alafasy` in the audio URL. The `PrefUtils().getReciterId()` setting is saved but never consumed.

### Files to change
- `lib/presentation/audio_player/audio_player_screen.dart` — Use reciter setting in URL

### Implementation
1. **Read reciter setting** in `_buildVerseUrls`:
   ```dart
   final reciterId = PrefUtils().getReciterId();
   // Default to alafasy if not set
   final effectiveReciter = (reciterId.isNotEmpty) ? reciterId : 'ar.alafasy';
   ```
2. **Use in URL**:
   ```dart
   'https://cdn.islamic.network/quran/audio/128/$effectiveReciter/${surahId * 1000 + i + 1}.mp3'
   ```

### Risk
Different reciters may have different verse counts or URL formats. The `cdn.islamic.network` API supports multiple reciters, but verify a few (e.g., `ar.abdurrahmaansudais`, `ar.hudhaify`) before committing. Add fallback to Alafasy on 404.

---

## Branch 4: `fix/statistics-real-data`
**PR Title:** `fix: Statistics screen uses real memorization data`

### What's wrong
`statistics_screen.dart` line 60: `value: 0` hardcoded for "surahs completed".

### Files to change
- `lib/presentation/statistics_screen/statistics_screen.dart` — Read from MemorizationBloc

### Implementation
1. **Add MemorizationBloc** to the screen's MultiBlocProvider/MultiBlocBuilder
2. **Count memorized surahs** from `MemorizationLoaded` state where status is `memorized`
3. **Replace `value: 0`** with the actual count
4. **Optional**: Add total verses read (from session history), reading streak (from khatmah data)

---

## Branch 5: `fix/orientation-hot-swap`
**PR Title:** `fix: Orientation setting applies immediately without restart`

### What's wrong
`main.dart` only reads orientation setting at startup. Changing it in settings requires app restart.

### Files to change
- `lib/presentation/settings_screen/settings_screen.dart` — Call `SystemChrome` on change

### Implementation
1. **In the orientation setting's `onChanged` callback**, after saving the pref:
   ```dart
   import 'package:flutter/services.dart';
   
   SystemChrome.setPreferredOrientations(_getOrientations(value));
   ```
2. **Add helper**:
   ```dart
   List<DeviceOrientation> _getOrientations(String mode) {
     switch (mode) {
       case 'portrait': return [DeviceOrientation.portraitUp];
       case 'landscape': return [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];
       default: return DeviceOrientation.values;
     }
   }
   ```

---

## Branch 6: ~~`fix/consume-reading-nav-mode`~~ → SKIP

**Decision:** Skip. The Reading Navigation Mode setting is saved but not consumed. Instead of implementing the complex PageView refactor, remove the setting from the Settings UI to avoid dead settings. Add it back when fully implemented in a future cycle.

### Files to change
- `lib/presentation/settings_screen/settings_screen.dart` — Remove the Reading Nav Mode toggle

### Implementation
1. **Remove the ListTile** for Reading Navigation Mode from the settings screen
2. **Keep** the `PrefUtils` methods (`getReadingNavMode`, `setReadingNavMode`) for future use

---

## Cross-cutting fixes (piggyback on any branch)

### Fix #8: Deprecated `SemanticsService.announce`
**File:** `lib/presentation/surah_screen/surah_screen.dart` line 841

Replace:
```dart
SemanticsService.announce(
  _isHifzMode ? 'lbl_hifz_mode_on'.tr : 'lbl_hifz_mode_off'.tr,
  TextDirection.ltr,
);
```
With:
```dart
SemanticsService.sendAnnouncement(
  AnnounceSemanticsEvent(
    _isHifzMode ? 'lbl_hifz_mode_on'.tr : 'lbl_hifz_mode_off'.tr,
    TextDirection.ltr,
  ),
);
```

Include in the first branch that touches `surah_screen.dart`.

### Fix #9 + #10: Theme context + hardcoded AppBar colors
**Files:**
- `lib/presentation/bookmarks/bookmarks_screen.dart`
- `lib/presentation/recitation_error/recitation_error_screen.dart`
- `lib/presentation/memorization/memorization_screen.dart`
- `lib/presentation/khatmah/khatmah_screen.dart`
- `lib/presentation/recitation_session/recitation_session_screen.dart`

Replace `PrefUtils().getIsDarkMode()` with `Theme.of(context).brightness == Brightness.dark`.
Replace hardcoded `Color(0xFF006754)` AppBar backgrounds with `Theme.of(context).colorScheme.primary` or remove explicit color.

Can be its own small branch `fix/theme-context-usage`.

---

## Branch 7: `fix/remove-dead-setting`
**PR Title:** `fix: Remove unconsumed Reading Navigation Mode setting`

### What's wrong
The Reading Nav Mode setting appears in Settings but has no effect on the app. Per user decision, remove it from the UI to avoid confusing users. The PrefUtils methods stay for future re-addition.

### Files to change
- `lib/presentation/settings_screen/settings_screen.dart` — Remove Reading Nav Mode ListTile

---

## Issue #11: Skip — `unnecessary_non_null_assertion`

The 4 warnings in `surah_screen.dart` lines 475/503 are **not fixable without refactoring**. The `!` operators are required for compilation because Dart cannot promote `Surah?` types through indirect boolean guards (`hasPrev`/`hasNext`). The correct fix would be:

```dart
// Instead of:
final prevSurah = hasPrev ? QuranIndex.quranSurahs[surah!.id - 2] : null;
// Use:
final prevSurah = surah != null && surah!.id > 1
    ? QuranIndex.quranSurahs[surah!.id - 2]
    : null;
```

But this doesn't help — the ternary still returns `Surah?`. The only real fix is to restructure with `if (surah == null) return SizedBox.shrink();` early-exit pattern. This is a style preference, not a bug. **Skip for now.**

---

## Execution Order

| Order | Branch | Depends on | Risk | Merge Priority |
|-------|--------|-----------|------|----------------|
| 1 | `fix/orientation-hot-swap` | None | Low | Quick win |
| 2 | `fix/audio-reciter-selection` | None | Low | Quick win |
| 3 | `fix/statistics-real-data` | None | Low | Quick win |
| 4 | `fix/theme-context-usage` | None | Low | Quick win |
| 5 | `feature/audio-verse-tracking` | None | Medium | Nice improvement |
| 6 | `feature/mushaf-text-rendering` | None | High | Large effort, highest value |
| 7 | `fix/remove-dead-setting` | None | Low | Cleanup |

Each branch gets its own PR with squash-merge. Update `testing/` with a new test report after all are merged.

---

## Final Verification

After all branches are merged:
1. `flutter analyze` — 0 errors, 0 warnings (4 remaining info-level `!` warnings)
2. `flutter test` — All 70+ tests pass
3. `flutter build apk --debug --flavor production` — Builds successfully
4. Create new test report: `testing/test-report-v{version}-YYYY-MM-DD.md`
5. Update `CLAUDE.md`, `feature_checklist.md`, `RELEASE_NOTES.md`
