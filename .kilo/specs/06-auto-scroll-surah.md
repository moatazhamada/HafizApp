# Spec: Auto-Scroll in Surah Screen

## Status: PENDING REVIEW

## Branch strategy
- Create branch `feature/auto-scroll` from latest `master`
- Open PR targeting `master`

## Description
Add auto-scroll functionality to the surah reading screen so the Quran text scrolls automatically at a configurable speed, useful for hands-free reading.

## Dependencies to add
- None

## Files to modify
1. `lib/presentation/surah_screen/surah_screen.dart` — Add auto-scroll toggle button, speed control, and scroll animation logic
2. `lib/core/utils/pref_utils.dart` — Add auto-scroll speed preference
3. `lib/localization/en_us/en_us_translations.dart` — Add auto-scroll strings
4. `lib/localization/ar_eg/ar_eg_translations.dart` — Add Arabic translations

## Acceptance criteria
- [ ] Toggle button in app bar to enable/disable auto-scroll
- [ ] Configurable speed (slow / normal / fast)
- [ ] Smooth continuous scrolling
- [ ] Tap to pause/resume
- [ ] Speed preference persisted
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- Use ScrollController.animateTo in a periodic timer
- Must not conflict with manual scrolling
- Disable during hifz (memorization) mode
