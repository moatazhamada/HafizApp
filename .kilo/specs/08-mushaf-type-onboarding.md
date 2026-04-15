# Spec: Mushaf Type Onboarding

## Status: PENDING REVIEW

## Branch strategy
- Create branch `feature/mushaf-type-onboarding` from latest `master` (depends on mushaf screen spec #02)
- Open PR targeting `master`

## Description
Add a first-run onboarding flow that lets users select their preferred Mushaf type (Madani, Egyptian, Indo-Pak, Warsh) and a feature discovery overlay for new features.

## Dependencies to add
- None

## Files to create
1. `lib/presentation/onboarding_screen/mushaf_type_onboarding.dart` — Mushaf type selector screen shown on first run
2. `lib/presentation/onboarding/feature_onboarding.dart` — Feature discovery tooltip system

## Files to modify
1. `lib/core/utils/pref_utils.dart` — Add mushaf type preference
2. `lib/routes/app_routes.dart` — Add onboarding route
3. `lib/localization/en_us/en_us_translations.dart` — Add onboarding strings
4. `lib/localization/ar_eg/ar_eg_translations.dart` — Add Arabic translations

## Acceptance criteria
- [ ] 4 Mushaf types shown with preview images
- [ ] Skip option
- [ ] Selection persisted
- [ ] Only shown on first run (check PrefUtils flag)
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- Depends on `mushaf_types.dart` from spec #02
- Preview images can be placeholder containers initially
