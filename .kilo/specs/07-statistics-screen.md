# Spec: Statistics Screen

## Status: PENDING REVIEW

## Branch strategy
- Create branch `feature/statistics-screen` from latest `master`
- Open PR targeting `master`

## Description
Add a statistics/progress screen showing reading streak, verses read, bookmarks count, practice verses count, and recent activity.

## Dependencies to add
- None

## Files to create
1. `lib/presentation/statistics_screen/statistics_screen.dart` — Statistics UI with cards and charts

## Files to modify
1. `lib/routes/app_routes.dart` — Add statistics route
2. `lib/localization/en_us/en_us_translations.dart` — Add statistics strings
3. `lib/localization/ar_eg/ar_eg_translations.dart` — Add Arabic translations
4. `lib/presentation/home_screen/home_screen.dart` — Add statistics to NavigationDrawer

## Acceptance criteria
- [ ] Display verses read count
- [ ] Display bookmarks count
- [ ] Display practice verses count
- [ ] Display reading streak (days)
- [ ] Recent activity section
- [ ] Empty state when no data
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- Data comes from existing PrefUtils (streak tracking) and repositories (bookmarks, practice)
- Purely read-only screen, no settings or modifications
- Statistics strings already partially exist in translations (`stats_title`, etc.)
