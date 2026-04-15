# Spec: Mushaf Screen (Page View)

## Status: PENDING REVIEW

## Branch strategy
- Create branch `feature/mushaf-screen` from latest `master` (after PR #35 merges)
- Open PR targeting `master`

## Description
Add a horizontal page-flipping Mushaf (Quran book) view that displays Quran pages as images, similar to a physical Mushaf. Users can swipe between 604 pages, tap to highlight verses, and bookmark pages.

## Dependencies to add
- None (uses built-in `PageView` widget)
- Future: mushaf page images hosted remotely or bundled as assets

## Files to create
1. `lib/presentation/mushaf_screen/mushaf_screen.dart` — Main screen with PageView
2. `lib/presentation/mushaf_screen/widgets/interactive_mushaf_page.dart` — Single page widget with tap zones for verse highlighting
3. `lib/core/quran_index/mushaf_page_index.dart` — Maps page numbers to surah/verse ranges
4. `assets/quran/mushaf_page_index.json` — JSON data mapping pages to surahs/verses
5. `lib/core/quran_index/mushaf_types.dart` — Enum for MushafType (Madani, Egyptian, IndoPak, Warsh)
6. `lib/core/network/mushaf_image_provider.dart` — Provides image URLs for mushaf pages

## Files to modify
1. `lib/routes/app_routes.dart` — Add `/mushaf_screen` route and `goToMushaf()` helper
2. `lib/injection_container.dart` — Register MushafPageIndex
3. `lib/localization/en_us/en_us_translations.dart` — Add mushaf-related strings
4. `lib/localization/ar_eg/ar_eg_translations.dart` — Add Arabic translations
5. `lib/presentation/home_screen/home_screen.dart` — Add mushaf item to NavigationDrawer

## Acceptance criteria
- [ ] Horizontal RTL page swiping through 604 pages
- [ ] Page number indicator with tap-to-jump
- [ ] Verse highlighting on tap
- [ ] Bookmark page support
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — no new failures
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- Page images can be placeholder colored containers initially
- The mushaf_page_index.json maps each page (1-604) to its surah and verse range
- Must work offline
- Respect current theme (light/dark)
