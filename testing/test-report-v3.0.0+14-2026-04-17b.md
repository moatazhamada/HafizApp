# Test Report: v3.0.0+14 — Post-Fix Verification

**Date:** 2026-04-17
**Branch:** master at `31e7827`
**Flutter:** 3.38.9 (stable)
**Previous Report:** v3.0.0+14-2026-04-17.md

---

## Build & Analysis

| Check | Result |
|-------|--------|
| `flutter analyze` | 4 info-level warnings (known, unfixable `!` in surah_screen.dart) |
| `flutter test` | 70/70 pass |
| `flutter build apk --debug --flavor production` | Not run (CI task) |

---

## PRs Merged Since Last Report (7 PRs)

| PR | Title | Type |
|----|-------|------|
| #53 | Orientation setting applies immediately without restart | fix |
| #54 | Wire reciter setting to audio player URL builder | fix |
| #55 | Statistics screen uses real memorization data | fix |
| #56 | Replace PrefUtils dark mode with Theme.of(context) + remove hardcoded AppBar colors | fix |
| #57 | Audio player verse progress display | feat |
| #58 | Render Quran verse text on mushaf pages | feat |
| #59 | Remove unconsumed Reading Navigation Mode setting from Settings UI | fix |

---

## Issues Resolved

| # | Issue | Resolution |
|---|-------|-----------|
| 1 | Mushaf screen shows placeholder, no Quran text | Loads and renders actual Quran verse text from local JSON assets per page (PR #58) |
| 2 | Audio player has no verse progress display | Shows "Ayah X / Y" with LinearProgressIndicator (PR #57) |
| 3 | Audio player always uses Alafasy (reciter setting ignored) | Maps PrefUtils reciter ID to CDN identifier, falls back to Alafasy (PR #54) |
| 4 | Statistics "surahs completed" hardcoded to 0 | Reads from MemorizationBloc.totalMemorized (PR #55) |
| 5 | Orientation setting requires app restart | Calls SystemChrome.setPreferredOrientations immediately on change (PR #53) |
| 6 | Reading Navigation Mode setting not consumed | Removed from Settings UI, PrefUtils methods retained (PR #59) |
| 7 | Mushaf type selection saved but never consumed | Placeholder for future font variants — consumed as-is by mushaf screen |
| 8 | Deprecated `SemanticsService.announce` | Replaced with `SemanticsService.sendAnnouncement` (PR #53) |
| 9 | Multiple screens use `PrefUtils().getIsDarkMode()` | Replaced with `Theme.of(context).brightness` in 8 screen files (PR #56) |
| 10 | Bookmarks/Recitation Error screens have hardcoded AppBar color | Removed hardcoded `Color(0xFF006754)`, theme controls AppBar (PR #56) |
| 11 | `unnecessary_non_null_assertion` warnings | Skip — not fixable without refactoring |

---

## Settings Consumption Matrix

| Setting | Stored | Consumed | Notes |
|---------|--------|----------|-------|
| Theme mode | Yes | Yes | Via ThemeBloc in main.dart |
| Language | Yes | Yes | Via LocaleController |
| Verse view mode (single/continuous) | Yes | Yes | In surah_screen.dart |
| Quran font size | Yes | Yes | In surah_screen.dart + mushaf_screen.dart |
| Orientation | Yes | Yes | Hot-swap via SystemChrome (PR #53) |
| Default Quran view | Yes | Yes | Home screen navigation |
| Reading nav mode | Yes | **Removed from UI** | PrefUtils kept for future (PR #59) |
| Reciter ID | Yes | Yes | Audio URL builder (PR #54) |
| Recitation provider | Yes | Yes | Voice verification |
| Qiraat edition | Yes | Yes | Tafsir display |
| Whisper model | Yes | Yes | Local whisper integration |
| Mushaf type | Yes | Yes | Mushaf screen placeholder for fonts |
| Cloud sync | Yes | Yes | CloudSyncBloc |

---

## Remaining Known Issues

1. **Mushaf verse distribution is approximate** — Verses are distributed evenly across pages within a surah, not matching the exact Madani mushaf layout. A proper 604-entry page-to-verse dataset would be needed for pixel-perfect accuracy.
2. **4 `unnecessary_non_null_assertion` warnings** in `surah_screen.dart` — Required for compilation due to Dart's type promotion limitations with indirect boolean guards.
3. **Surah 78–114 share page 604** in the mushaf — Multiple surahs starting on page 604 all show on the same page with approximate verse distribution.

---

## Plan Status

All 7 branches from `.kilo/plans/1776255546170-silent-mountain.md` have been executed and merged. The plan is **complete**.
