# Spec: Verse Sharing & Deep Links

## Status: PENDING REVIEW

## Branch strategy
- Create branch `feature/verse-sharing` from latest `master`
- Open PR targeting `master`

## Description
Add ability to share Quran verses as text, image, or link. Also support deep links so users can open the app directly to a specific verse via URL.

## Dependencies to add
- `share_plus: ^10.1.4` (share dialog)
- `app_links: ^6.4.1` (deep link handling)

## Files to create
1. `lib/widgets/verse_share_sheet.dart` — Bottom sheet with share options (text, image, link)
2. `lib/core/deep_link/deep_link_service.dart` — Handles incoming deep links and generates shareable URLs

## Files to modify
1. `lib/main.dart` — Initialize DeepLinkService in MyApp
2. `lib/routes/app_routes.dart` — No new routes needed
3. `lib/localization/en_us/en_us_translations.dart` — Add sharing strings
4. `lib/localization/ar_eg/ar_eg_translations.dart` — Add Arabic translations
5. `lib/presentation/surah_screen/surah_screen.dart` — Add share button to verse context menu

## Acceptance criteria
- [ ] Share verse as text with attribution
- [ ] Copy verse text to clipboard
- [ ] Copy deep link to clipboard
- [ ] Handle incoming deep links (open to specific surah/verse)
- [ ] Share sheet accessible from surah screen verse long-press menu
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- Deep link format: `hafiz://verse/{surahId}/{verseNumber}` and `hafiz://page/{pageNumber}`
- Android intent-filter needs to be added to AndroidManifest.xml
- iOS universal links need apple-app-site-association
