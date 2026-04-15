# Spec: Settings Enhancements

## Status: PENDING REVIEW

## Branch strategy
- Create branch `feature/settings-enhancements` from latest `master`
- Open PR targeting `master`

## Description
Enhance the settings screen with display preferences (font size, orientation, default Quran view), Ramadan settings, and reading navigation mode.

## Dependencies to add
- None

## Files to create
1. `lib/core/ramadan/ramadan_theme.dart` — RamadanTheme + RamadanCountdown widgets
2. `lib/core/ramadan/ramadan_date_manager.dart` — Ramadan date calculations and region selector

## Files to modify
1. `lib/presentation/settings_screen/settings_screen.dart` — Add sections for display preferences, orientation, default Quran view, Ramadan region, auto-scroll
2. `lib/core/utils/pref_utils.dart` — Add preference methods for new settings (orientation mode, default Quran view, font size, etc.)
3. `lib/localization/en_us/en_us_translations.dart` — Add new setting strings
4. `lib/localization/ar_eg/ar_eg_translations.dart` — Add Arabic translations

## Acceptance criteria
- [ ] Display preferences: Quran font size, regular font size
- [ ] Orientation: Portrait / Landscape / Auto-rotate
- [ ] Default Quran view: Surah view / Mushaf view
- [ ] Reading navigation: Scroll mode / Page mode
- [ ] Ramadan region selector
- [ ] All settings persist across app restarts
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- PrefUtils already uses SharedPreferences
- Keep existing settings intact, only add new sections
