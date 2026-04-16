# Spec: Musali Teaser Screen Refactor

## Status: PENDING REVIEW

## Priority: Low (not blocking)

## Branch strategy
- Create branch `fix/musali-teaser-refactor` from latest `master`
- Open PR targeting `master`

## Problem
The current Musali teaser screen is confusing and poorly designed:
- The slide content/titles are cryptic and don't communicate value ("The name tricked you. And that's the secret.")
- Users can't understand what Musali is or why they should care
- The auto-slide animation feels jarring
- No clear call-to-action or visual hierarchy
- The teaser flow interrupts the onboarding experience

## Current behavior
1. After onboarding "Get Started", user lands on musali teaser
2. 4 slides auto-advance with cryptic messages
3. Skip/Next buttons at bottom
4. Final slide says "Musali" with "Think again" subtitle
5. After dismissing, goes to home screen

## Proposed changes
- Redesign as a simple, elegant "Coming Soon" card/banner instead of a full-screen teaser
- OR: Rewrite copy to clearly explain what Musali is and why the user should be excited
- Consider making it a dismissible banner on the home screen instead of a separate screen
- Add actual app preview/mockup if available
- Improve animations (subtle fade instead of auto-advance)

## Files involved
- `lib/presentation/musali_teaser_screen/musali_teaser_screen.dart` — Main screen
- `lib/presentation/musali_teaser_screen/bloc/musali_teaser_bloc.dart` — BLoC
- `lib/presentation/musali_teaser_screen/bloc/musali_teaser_event.dart` — Events
- `lib/presentation/musali_teaser_screen/bloc/musali_teaser_state.dart` — States
- `lib/localization/en_us/en_us_translations.dart` — Slide text
- `lib/localization/ar_eg/ar_eg_translations.dart` — Arabic slide text

## Acceptance criteria
- [ ] Clear, understandable messaging that explains Musali
- [ ] Does not confuse or frustrate users
- [ ] Easy to skip/dismiss
- [ ] Works in both English and Arabic
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- This is cosmetic/content work, not a functional feature
- Can be deferred until after all functional features are restored
- The teaser screen is shown after onboarding before reaching home screen
