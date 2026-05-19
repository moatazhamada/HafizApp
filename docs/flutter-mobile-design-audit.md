# Flutter Mobile Design Audit — Hafiz App

**Date:** 2026-05-13  
**Skill:** `flutter-mobile-design`  
**Scope:** All 24 presentation screens, global widgets, theme system, BLoC patterns, accessibility, RTL, and performance.

---

## Executive Summary

| Severity | Count | Category |
|----------|-------|----------|
| 🔴 Critical | 3 | `textScaler` missing, `buildWhen` missing, Mushaf dark bg too dark |
| 🟡 High | 6 | No `EdgeInsetsDirectional`, no component themes, ad-hoc empty/error states, hardcoded colors, `VoiceVerificationDialog` size, `SurahScreen` rebuild scope |
| 🟢 Medium | 8 | Missing `Semantics` on some screens, onboarding scroll physics, settings scroll, `RandomVerseCard` error handling, etc. |
| 🔵 Low | 5 | Minor const opportunities, `AppTextStyles` not in `TextTheme`, `offline_indicator` dismissible gesture |

---

## System-Level Findings

### 🔴 CR-1: No `textScaler` / `textScaleFactor` handling anywhere
**File:** Entire `lib/`  
**Count:** 0 occurrences  
**Impact:** Users with accessibility font sizes (Settings → Display → Font size) will see broken layouts, clipped text, and overflow errors across all screens. For a **Quran reading app**, this is critical — your core users are elderly or vision-impaired readers who rely on large text.  
**Fix:** Wrap the app root or each reading screen with a `MediaQuery` that clamps `textScaler`:
```dart
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(
      MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5),
    ),
  ),
  child: child,
)
```
Audit every screen for `TextOverflow.ellipsis`, `maxLines`, and flexible layouts.

### 🔴 CR-2: Zero `buildWhen` / `listenWhen` usage in BLoC
**File:** Entire `lib/`  
**Count:** 0 occurrences  
**Impact:** Every `BlocBuilder` rebuilds on **every** state emission. On `surah_screen.dart` (which subscribes to `SurahBloc`, `BookmarkBloc`, `RecitationErrorBloc`), a single ayah highlight or bookmark toggle triggers a full-screen rebuild. This causes jank during audio playback and voice verification.  
**Fix:** Add `buildWhen` to every `BlocBuilder`:
```dart
BlocBuilder<SurahBloc, SurahState>(
  buildWhen: (prev, curr) => prev.ayahs != curr.ayahs, // example
  builder: ...
)
```
Priority: `surah_screen.dart`, `home_screen.dart`, `audio_player_screen.dart`.

### 🔴 CR-3: Mushaf dark mode background is too dark
**File:** `lib/core/theme/app_colors.dart`  
**Line:** `mushafPageBg = 0xFF1E1A1A`  
**Impact:** The skill mandates *"Never pure black for long-form reading. Warm sepia or dark paper tones only."* `0xFF1E1A1A` is effectively OLED black with a hint of red. Extended Quran reading in this mode causes eye strain.  
**Fix:** Use a warm dark paper tone like `0xFF2A2420` or `0xFF1E1E1A` with a blue-gray tint toward the brand hue.

### 🟡 HI-1: No `EdgeInsetsDirectional` usage
**File:** Entire `lib/`  
**Count:** 0 occurrences; 130+ uses of `EdgeInsets.only`/`fromLTRB`  
**Impact:** If the app ever supports a true bidirectional layout engine (or if a user forces LTR while reading Arabic), asymmetric padding will not mirror correctly.  
**Fix:** Replace all asymmetric `EdgeInsets.only(left: ..., right: ...)` with `EdgeInsetsDirectional.only(start: ..., end: ...)` in presentation code.

### 🟡 HI-2: No custom component themes in `ThemeData`
**File:** `lib/main.dart`  
**Impact:** Every `ElevatedButton`, `Card`, `InputDecoration`, `BottomSheet`, and `Dialog` uses Material 3 defaults. This causes visual inconsistency — some buttons are green (seed color), others have hardcoded black text (`custom_elevated_button.dart`).  
**Fix:** Register themes:
```dart
ThemeData(
  elevatedButtonTheme: ElevatedButtonThemeData(...),
  cardTheme: CardTheme(...),
  inputDecorationTheme: InputDecorationTheme(...),
  bottomSheetTheme: BottomSheetThemeData(...),
)
```

### 🟡 HI-3: `AppTextStyles` not wired into `ThemeData.textTheme`
**File:** `lib/core/theme/app_text_styles.dart`  
**Impact:** Widgets cannot use `Theme.of(context).textTheme.bodyLarge` to get app-specific typography. Every screen imports `AppTextStyles` directly, making dynamic theming (e.g., dyslexia-friendly font) impossible.  
**Fix:** Map `AppTextStyles` into `TextTheme` inside `main.dart`:
```dart
theme: ThemeData(
  textTheme: TextTheme(
    bodyLarge: AppTextStyles.bodyLarge,
    headlineSmall: AppTextStyles.headingSmall,
    // ... etc
  ),
)
```

### 🟡 HI-4: No reusable `EmptyState` or `ErrorState` widgets
**File:** Multiple screens  
**Impact:** 10+ screens each roll their own empty/error UI. This causes inconsistency in icon choice, messaging, and retry action placement.  
**Fix:** Create `lib/widgets/empty_state.dart` and `lib/widgets/error_state.dart` with standardized illustration, message, and retry button.

### 🟡 HI-5: Hardcoded `Colors.` constants (387 occurrences)
**File:** Many (`main.dart`, `offline_indicator.dart`, `recitation_error_screen.dart`, `settings_screen.dart`, etc.)  
**Impact:** Breaks dark mode consistency. `Colors.red`, `Colors.grey`, `Colors.white` do not adapt to theme changes.  
**Fix:** Replace with `Theme.of(context).colorScheme.error`, `.onSurfaceVariant`, `.surface`, etc.

### 🟡 HI-6: `VoiceVerificationDialog` likely has unbounded width
**File:** `lib/presentation/surah_screen/widgets/voice_verification_dialog.dart`  
**Impact:** Dialogs without `ConstrainedBox` or `AlertDialog` wrapping can stretch to screen width on tablets, looking broken.  
**Fix:** Ensure the dialog uses `AlertDialog` or wraps content in `ConstrainedBox(maxWidth: 400)`.

---

## Screen-by-Screen Audit

### 1. `about_screen.dart`
**BLoC:** None  
**Severity:** 🟢 Medium  
**Issues:**
- Uses plain `ListView` (acceptable for short content).
- No `Semantics` wrapper.
- `EdgeInsets.only(left: 16)` used — should be `EdgeInsetsDirectional.only(start: 16)`.

### 2. `audio_player_screen.dart`
**BLoC:** None (receives args)  
**Severity:** 🟡 High  
**Issues:**
- `Semantics` present (good) but not on the scrubber/seek bar.
- No `buildWhen` on any state listener — audio position updates likely rebuild the full screen 30×/second.
- `ListView.builder` used for playlist (good).
- Mini-player vs full-screen transition may lack `Hero` tag for continuity.
- **Dark mode:** Verify ayah highlight color contrast against dark background.

### 3. `auth/` (QfAuthBloc)
**BLoC:** `QfAuthBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- No dedicated auth screen file found — bloc exists but screen may be embedded in `settings` or `cloud_sync`.
- Ensure auth error states show inline, not just console logs.

### 4. `bookmarks_screen.dart`
**BLoC:** `BookmarkBloc`  
**Severity:** 🟡 High  
**Issues:**
- `ListView.builder` used (good).
- Empty state exists but is ad-hoc (inline `Column`).
- Swipe-to-delete has no `Semantics` for "Remove bookmark" action.
- `BlocBuilder` lacks `buildWhen` — toggling one bookmark rebuilds the entire list.
- Arabic verse text uses `textDirection.rtl` (good).

### 5. `changelog_screen.dart`
**BLoC:** None  
**Severity:** 🔵 Low  
**Issues:**
- Plain `ListView` acceptable.
- No `Semantics`.
- Minor: Markdown rendering should respect text scale.

### 6. `cloud_sync_screen.dart`
**BLoC:** `CloudSyncBloc`  
**Severity:** 🟡 High  
**Issues:**
- Plain `ListView` for settings rows.
- Inline error text uses `colorScheme.error` (good) but no retry widget.
- Auth state mixed with sync state — consider separating UI concerns.
- No `Semantics` on sync toggle.

### 7. `force_update_screen.dart`
**BLoC:** None  
**Severity:** 🟢 Medium  
**Issues:**
- Modal barrier may block accessibility gestures.
- Ensure `Semantics` announces "Update required" on dialog open.

### 8. `goals_screen.dart`
**BLoC:** `GoalsBloc`  
**Severity:** 🟡 High  
**Issues:**
- `_ErrorView` exists (good) but is private and screen-local.
- Empty state is inline ad-hoc.
- `ListView.builder` not used — uses plain `ListView` for goal list (could be long).
- No `Semantics` on progress indicators.

### 9. `help_screen.dart`
**BLoC:** None  
**Severity:** 🔵 Low  
**Issues:**
- Plain `ListView` acceptable.
- No `Semantics` on expandable sections.

### 10. `home_screen.dart` ⭐
**BLoC:** `HomeBloc` + `AdaptiveHomeBloc`  
**Severity:** 🟡 High  
**Issues:**
- Two BLoCs with nested `BlocBuilder` trees and **zero `buildWhen`** — surface switching, activity heatmap updates, and continue-reading card changes all rebuild the full scaffold.
- `AnimatedSurfaceSwitcher` exists (good) but verify it uses `AnimatedSwitcher` with `layoutBuilder` to avoid layout jumps.
- `SurahIndexWidget` uses `ListView.builder` (good).
- `ActivityHeatmap` may rebuild unnecessarily when `AdaptiveHomeBloc` emits.
- `Semantics` on app bar and bottom nav (good).
- Missing `Semantics` on surface suggestion banner dismiss button.
- **RTL:** Navigation arrows in `AdaptiveNavigation` must follow RTL semantics (next = left, prev = right).

### 11. `khatmah_screen.dart`
**BLoC:** `KhatmahBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- Plain `ListView` used for khatmah list (could be long if user has many).
- Empty state is inline.
- No `Semantics` on completion progress rings.

### 12. `memorization_screen.dart`
**BLoC:** `MemorizationBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- Plain `ListView` used for revision queue.
- Empty state inline.
- **Critical for Quran app:** Memorization cards should use calm, desaturated tones. Verify no bright red/green gamification.
- No `Semantics` on SRS due-date badges.

### 13. `musali_teaser_screen.dart`
**BLoC:** `MusaliTeaserBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- Teaser screen should have clear dismiss action.
- Ensure `Semantics` announces this is a promotional/teaser screen.

### 14. `mushaf_screen.dart` ⭐
**BLoC:** None  
**Severity:** 🟡 High  
**Issues:**
- `PageView` used (good) — verify `allowImplicitScrolling: true` for preloading adjacent pages.
- `textDirection.rtl` applied (good).
- **Dark mode background:** `0xFF1E1A1A` is too dark for extended reading (CR-3).
- `SafeArea` used (good) but verify landscape: two-page spread on tablets.
- `Semantics` missing on page-turn gesture. Screen readers cannot navigate pages.
- `MushafJumpDialog` uses `ListView.builder` (good) but no `Semantics` on list items.
- `MushafPageWidget` uses `CachedNetworkImage` (good) but no fade-in placeholder.

### 15. `onboarding_screen.dart`
**BLoC:** `OnboardingBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- `PageView` used for multi-page flow (good).
- `MushafTypeOnboarding` receives args — ensure it handles missing args gracefully.
- No `Semantics` on page indicators.
- Archetype selection uses grid — ensure touch targets ≥48dp.
- **RTL:** Onboarding pages must respect RTL for Arabic locale. Verify `PageView` scroll direction reverses.

### 16. `quran_reflect_feed_screen.dart`
**BLoC:** None  
**Severity:** 🟢 Medium  
**Issues:**
- `ListView.builder` used (good).
- Empty state inline.
- No `Semantics` on post cards.
- **Dark mode:** Card backgrounds must be distinguishable from scaffold background.

### 17. `recitation_error_screen.dart`
**BLoC:** `RecitationErrorBloc`  
**Severity:** 🟡 High  
**Issues:**
- `ListView.builder` used (good).
- Inline error text inside `BlocConsumer` (acceptable but not reusable).
- `Colors.white` used for check icon — hardcoded, breaks dark mode.
- Empty state inline.
- No `Semantics` on error severity badges.

### 18. `recitation_session_screen.dart`
**BLoC:** `RecitationSessionBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- `ListView.builder` used (good).
- Empty state inline.
- No `Semantics` on session cards.

### 19. `search_screen.dart`
**BLoC:** `SearchBloc`  
**Severity:** 🟡 High  
**Issues:**
- `Semantics` on search field and results (good).
- `textDirection.rtl` on Arabic results (good).
- No `buildWhen` — every keystroke debounce rebuilds the entire results list.
- Empty state is just a `Text` widget — lacks illustration or guidance.
- Error state is inline `Text('${"lbl_error".tr}: ${state.message}')` — not reusable.
- **RTL:** Search field should align right when Arabic keyboard is active.

### 20. `settings_screen.dart`
**BLoC:** None  
**Severity:** 🟡 High  
**Issues:**
- Plain `ListView` used (acceptable for static content).
- `textDirection.rtl` on Arabic preview (good).
- Multiple hardcoded `Colors.grey` and `Colors.red`.
- No `Semantics` on toggle switches.
- **Critical:** Font size setting must integrate with `textScaler` (CR-1). Currently it may use a custom scale that ignores system accessibility.
- Mushaf type selection should preview the actual Mushaf page, not just a color swatch.

### 21. `statistics_screen.dart`
**BLoC:** None (reads `RecitationErrorBloc`)  
**Severity:** 🟢 Medium  
**Issues:**
- Reads `RecitationErrorBloc` state for practice count — ensure this doesn't cause unnecessary rebuilds.
- Plain `ListView` acceptable.
- Charts/graphs need `Semantics` labels describing the data for screen readers.

### 22. `surah_screen.dart` ⭐⭐
**BLoC:** `SurahBloc` + `BookmarkBloc` + `RecitationErrorBloc` + `QfAuthBloc`  
**Severity:** 🟡 High  
**Issues:**
- **Most complex screen in the app.** 4 BLoCs, 8 local widgets, 4 sheets/dialogs.
- **Zero `buildWhen` on any `BlocBuilder`** — this is the highest-priority fix. Audio playback, bookmark toggles, error states, and auth changes all rebuild the entire ayah list.
- `Semantics` heavily used (good) but missing on `VerseMenuSheet` and `AutoScrollSpeedSheet` options.
- `SurahNavigationBar` has `textDirection.rtl` but arrows are forced LTR — verify RTL semantics (next = left, prev = right).
- `VoiceVerificationDialog` — likely unbounded width on tablets (HI-6).
- `TafsirSheet` uses `textDirection.rtl` (good) but no `Semantics` on copy/share actions.
- `BismillahWidget` has `Semantics` (good).
- **Performance:** `CustomScrollView` or `ListView.builder` should be used for long surahs (Al-Baqarah). If using `Column` with `List.generate`, this is a critical performance bug.
- **Dark mode:** Ayah highlight color must be visible against both light and dark backgrounds.
- **Accessibility:** Touch targets on verse menu buttons must be ≥48dp.

### 23. `tajweed_roadmap_screen.dart`
**BLoC:** `TajweedRoadmapBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- Plain `ListView` used for roadmap steps.
- Empty state inline.
- No `Semantics` on progress nodes.

### 24. `verse_study_screen.dart`
**BLoC:** `VerseStudyBloc`  
**Severity:** 🟢 Medium  
**Issues:**
- `textDirection.rtl` used (good).
- No `Semantics` on study card flip gesture.
- Empty/error states inline.

---

## Widget Audit

### Global Widgets (`lib/widgets/`)

| Widget | Grade | Issues |
|--------|-------|--------|
| `BaseButton` | 🟡 B | Abstract class returns `SizedBox.shrink()` — runtime error if subclass misses override. No `Semantics`. |
| `CustomAppBar` | 🟡 B | Transparent background with `scrolledUnderElevation: 0` — verify text remains readable over scrollable content. Height uses `.v` (responsive) which is fine. |
| `CustomElevatedButton` | 🟡 B | Wraps `ElevatedButton` in `Container` — redundant. Default text style is hardcoded black/400/14, ignores `ThemeData.elevatedButtonTheme`. Height `57.v` is fixed — may truncate at large text scales. |
| `CustomImageView` | 🟢 B+ | Supports SVG, network, file, asset. Uses `CachedNetworkImage` fallback. Good. |
| `OfflineIndicator` | 🟢 B+ | `BlocBuilder` for connectivity — **no `buildWhen`** but state changes are rare so acceptable. Dismissible banner. `Colors.white` hardcoded for icon/text. |
| `RandomVerseCard` | 🟢 B+ | Self-loading with `textDirection.rtl` (good). No error-state UI if fetch fails — shows perpetual shimmer or blank. |
| `ShimmerLoading` | 🟢 A- | Adapts colors to dark/light mode. Good reusable set (`ShimmerBox`, `ShimmerListTile`, etc.). |
| `SurahListItem` | 🟡 B | `textDirection.rtl` (good). `Hero` tag used (good). Hides English name for Arabic locale (good). No `Semantics` on the whole tile. Touch target is the full tile — verify it's ≥48dp tall. |
| `VerseShareSheet` | 🟢 B+ | Uses `.tr` for labels. `textDirection.rtl` not explicitly set — may default to LTR in English locale even when sharing Arabic text. |

### Home Screen Widgets

| Widget | Grade | Issues |
|--------|-------|--------|
| `ActivityHeatmap` | 🟢 B+ | May rebuild with `AdaptiveHomeBloc` — verify it only rebuilds when heatmap data changes. |
| `AdaptiveNavigation` | 🟡 B | Must reverse nav arrows in RTL (next = left, prev = right). Verify `Directionality.of(context)` check. |
| `AnimatedSurfaceSwitcher` | 🟢 B+ | Verify `AnimatedSwitcher.layoutBuilder` prevents overflow during transition. |
| `ContinueReadingCard` | 🟢 B+ | `Semantics` present (good). Progress indicator should announce percentage to screen reader. |
| `ReadingSessionInsights` | 🟢 B | No `Semantics` on stat numbers. |
| `StaggeredListItem` | 🟢 B+ | Animation is good, but verify `AnimationController` is disposed. |
| `SurahIndexWidget` | 🟢 A- | `ListView.builder` (good). `const SliverPadding` (good). |
| `SurfaceSuggestionBanner` | 🟢 B | Missing `Semantics` on dismiss button. |

### Surah Screen Widgets

| Widget | Grade | Issues |
|--------|-------|--------|
| `AutoScrollSpeedSheet` | 🟢 B | No `Semantics` on speed slider. |
| `BismillahWidget` | 🟢 A- | `Semantics` present. `textDirection.rtl` present. |
| `CompletionDialog` | 🟢 B+ | `ExcludeSemantics` on Lottie (good). Missing `Semantics` on "Continue" button. |
| `SurahNavigationBar` | 🟡 B | Arrows forced LTR — verify RTL reversal. Touch targets look small (verify ≥48dp). |
| `TafsirSheet` | 🟢 B+ | `textDirection.rtl` (good). No `Semantics` on copy/share. |
| `VerseMenuSheet` | 🟢 B | No `Semantics` on menu options. Touch targets should be full-width rows ≥48dp. |
| `VerseRange` | 🟢 B | No `Semantics` on range selector. |
| `VoiceVerificationDialog` | 🟡 C+ | Likely unbounded width on tablets. Complex state (recording, processing, result) — ensure each state transition is announced via `SemanticsService.announce`. |

### Mushaf Screen Widgets

| Widget | Grade | Issues |
|--------|-------|--------|
| `MushafJumpDialog` | 🟢 B+ | `ListView.builder` (good). `textDirection.rtl` (good). No `Semantics` on list items. |
| `MushafPageWidget` | 🟡 B | `CachedNetworkImage` used but no fade-in placeholder or error widget. No `Semantics` describing page number. |

### Onboarding Widgets

| Widget | Grade | Issues |
|--------|-------|--------|
| `OnboardingButtons` | 🟢 B | Verify `Hero` tag consistency between pages. |
| `OnboardingScaffold` | 🟢 B | `SafeArea` used (good). Ensure `PageController` is disposed. |

---

## Theme System Audit

| Aspect | Grade | Notes |
|--------|-------|-------|
| Theme switching (light/dark/system) | 🟢 A | `HydratedBloc` + `PrefUtils` — robust. |
| Color tokens (`AppColors`) | 🟡 B+ | Comprehensive but hand-rolled instead of `ColorScheme` extension. Mushaf dark bg too dark (CR-3). |
| Spacing tokens (`AppSpacing`) | 🟢 A- | Good scale. Touch target `48.0` defined. |
| Typography tokens (`AppTextStyles`) | 🟡 B | Good variety (Quran sizes, numeric, body). Not wired into `ThemeData.textTheme` (HI-3). No `TextHeightBehavior` for Uthmani diacritics. |
| Material 3 adoption | 🟡 B | `useMaterial3: true` set. `ColorScheme.fromSeed` used. No component themes registered (HI-2). |
| Responsive design | 🟢 B+ | Figma-based `size_utils.dart` with `.h`, `.v`, `.adaptSize`. |
| RTL support | 🟡 B | Strong local `textDirection.rtl` discipline. No `EdgeInsetsDirectional` (HI-1). No global `Directionality` wrapper. |

---

## Action Priority Matrix

### P0 — Fix This Week

1. **Add `textScaler` clamping** system-wide or at least on reading screens (CR-1).
2. **Add `buildWhen` to all `BlocBuilder` instances** on `surah_screen.dart`, `home_screen.dart`, `audio_player_screen.dart` (CR-2).
3. **Warm up Mushaf dark mode background** from `0xFF1E1A1A` to `0xFF2A2420` or similar (CR-3).

### P1 — Fix Before Next Release

4. Create reusable `EmptyState` and `ErrorState` widgets (HI-4).
5. Replace hardcoded `Colors.` with theme-derived colors in `offline_indicator`, `recitation_error_screen`, `settings_screen` (HI-5).
6. Add `Semantics` to all interactive elements missing them (search results, verse menu, Mushaf page, settings toggles).
7. Replace asymmetric `EdgeInsets.only(left/right)` with `EdgeInsetsDirectional` in presentation code (HI-1).
8. Wire `AppTextStyles` into `ThemeData.textTheme` (HI-3).
9. Register custom component themes in `main.dart` (HI-2).
10. Add fade-in placeholder to `MushafPageWidget`.

### P2 — Polish

11. Add `Hero` tag to audio player mini-player → full-screen transition.
12. Ensure `VoiceVerificationDialog` has bounded width on tablets.
13. Add `SemanticsService.announce` to voice verification state transitions.
14. Review onboarding `PageView` scroll direction for RTL locale.
15. Add `TextHeightBehavior` to Quran text styles to prevent diacritic clipping.

---

*End of audit.*
