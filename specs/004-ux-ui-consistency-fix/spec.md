# Feature Specification: UX/UI Consistency & Design System Centralization

**Feature Branch**: `004-ux-ui-consistency-fix`
**Created**: 2026-04-28
**Status**: Draft
**Input**: Audit report Pillar 2 (H4, H9, H10, H11, UX-01, UX-03, UX-04, UX-05, UX-06, P1, P2, P11)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cohesive Visual Design Across All Screens (Priority: P1)

As a user navigating through the app, every screen presents a visually consistent experience — unified colors, typography, and spacing. There are no jarring visual differences between screens (e.g., different shades of green, inconsistent font weights, or mismatched padding). Dark mode and light mode transitions are smooth and consistent across every screen.

**Why this priority**: The design system audit found 20+ hardcoded color values scattered across 15+ screens, no centralized typography, and no spacing system. This is the single largest contributor to the "Product Quality & UX" judging score (currently 12-14/20, estimated +3-5 points with fix). It also affects every user interaction.

**Independent Test**: Navigate through every screen (home, surah, bookmarks, search, mushaf, audio, memorization, khatmah, statistics, settings, onboarding, verse study, cloud sync). Verify that all colors come from the centralized theme (no hardcoded hex values), typography uses the defined text styles, and spacing follows the defined scale. Toggle between light and dark mode and verify consistency.

**Acceptance Scenarios**:

1. **Given** the app is in light mode, **When** the user navigates between any two screens, **Then** the primary color, surface color, and text styles are visually consistent (sourced from the same theme tokens).
2. **Given** the app is in dark mode, **When** the user toggles theme, **Then** all screens update correctly using theme tokens — no hardcoded dark colors remain.
3. **Given** any screen in the app, **When** inspecting the widget tree, **Then** all colors reference `Theme.of(context).colorScheme` or custom theme extensions, not inline hex values.
4. **Given** Arabic text on any screen, **When** rendered, **Then** it uses the defined Arabic typography style (NotoNaskhArabic) from the centralized text theme.
5. **Given** English/Latin text on any screen, **When** rendered, **Then** it uses the defined Latin typography style (Poppins) from the centralized text theme.

---

### User Story 2 - Touchable Elements Meet Accessibility Standards (Priority: P2)

As a user with motor impairments (or any user on a small screen), all tappable elements — verse number badges, page indicators, surah selection circles, action buttons — are at least 48x48 pixels (Material Design minimum). I can tap any interactive element without accidentally missing it or hitting an adjacent element.

**Why this priority**: Touch targets below 48x48 (28x28 verse badges, 36x36 page indicators, 40x40 surah circles) are a high-severity accessibility violation that affects daily usage. This is also evaluated in the hackathon "Product Quality & UX" criterion.

**Independent Test**: Use accessibility scanning tools (or manual measurement) to verify all interactive elements across surah screen, mushaf screen, and memorization screen are at least 48x48 logical pixels. Verify the visual size can remain smaller (badge appearance) while the touch target is expanded.

**Acceptance Scenarios**:

1. **Given** the surah reading screen, **When** the user taps a verse number badge, **Then** the tappable area is at least 48x48 pixels (visual appearance can remain smaller via padding/inset).
2. **Given** the mushaf page view, **When** the user taps a page indicator circle, **Then** the touch target is at least 48x48 pixels.
3. **Given** the memorization screen, **When** the user taps a surah number circle to select it, **Then** the touch target is at least 48x48 pixels.
4. **Given** any interactive element in the app, **When** measured, **Then** the touch target area meets or exceeds 48x48 logical pixels per Material Design guidelines.

---

### User Story 3 - Statistics Screen Shows Proper Loading State (Priority: P2)

As a user opening the Statistics screen, I see a clear loading indicator (skeleton/shimmer) while the underlying data is being fetched from BLoCs. I never see a flash of empty state before the actual data appears.

**Why this priority**: The Statistics screen is the only screen missing a loading state entirely — users see a blank flash before data loads, which feels broken. This is flagged as UX-01 (HIGH) in the audit.

**Independent Test**: Open the Statistics screen with a cold app start (BLoCs not yet initialized). Verify a loading shimmer/skeleton appears immediately and transitions smoothly to the populated state when data is available.

**Acceptance Scenarios**:

1. **Given** the Statistics screen is opened for the first time, **When** BLoCs have not yet emitted data, **Then** a loading indicator (shimmer or skeleton) is displayed immediately.
2. **Given** the loading state is showing, **When** BLoCs emit populated data, **Then** the screen smoothly transitions from loading to populated state.
3. **Given** the loading state is showing, **When** BLoCs emit an error, **Then** an error state with retry option is shown (no infinite loading).

---

### User Story 4 - Arabic Localization Is Complete and Correct (Priority: P3)

As an Arabic-speaking user, all text in the app is properly localized — including the recitation session score percentage (currently missing from Arabic translation), settings section labels (not incorrectly uppercased), and empty state placeholders (not hardcoded dashes). Arabic text flows naturally right-to-left without any visual artifacts.

**Why this priority**: Missing the score percentage in Arabic (UX-04), `.toUpperCase()` on Arabic text (P11), and unlocalized mushaf placeholders (UX-03) are medium-severity issues that affect the Arabic-speaking user base — the app's primary audience.

**Independent Test**: Switch the app language to Arabic. Complete a voice recitation session and verify the score shows a percentage (e.g., "85%"). Open Settings and verify section labels are properly cased (not garbled by `.toUpperCase()`). Navigate to Mushaf view and verify empty verse data shows a localized message, not "—".

**Acceptance Scenarios**:

1. **Given** the app language is Arabic, **When** a recitation session completes, **Then** the session score message includes the numerical percentage (e.g., "لقد تلوت الآيات بشكل صحيح. النسبة: 85%").
2. **Given** the app language is Arabic, **When** viewing the Settings screen, **Then** section labels use proper Arabic casing (locale-aware capitalization, no `.toUpperCase()`).
3. **Given** the Mushaf view with an empty verse, **When** the verse data is unavailable, **Then** a localized placeholder message is displayed (e.g., "الآية غير متوفرة") instead of "—".
4. **Given** the search screen, **When** the search field is displayed, **Then** the AppBar background matches all other screens (uses theme default, not a custom color override).

---

### Edge Cases

- What happens when a new screen is added to the app after the design system is centralized? → The theme tokens must be the only way to reference colors/typography, enforced by linting rules or code review guidelines.
- What happens when touch target expansion causes overlapping tap areas? → Adjust spacing or use `HitTestBehavior.opaque` with proper hit testing to prevent conflicts.
- What happens when the Arabic font (NotoNaskhArabic) doesn't support a specific character? → Fall back to the theme's default font family for that character.
- What happens when the Statistics screen BLoC emits both loading and error simultaneously? → Error state takes precedence over loading state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST define a centralized design system with all color tokens, typography styles, and spacing constants in a single theme configuration. (H4)
- **FR-002**: All screens MUST reference colors from the centralized theme (`Theme.of(context).colorScheme` or extensions) — zero hardcoded hex color values in screen/widget files. (H4)
- **FR-003**: All screens MUST reference typography from the centralized text theme — no inline font family or font size specifications in screen/widget files. (P1)
- **FR-004**: The app MUST define a spacing scale (e.g., 4/8/12/16/24/32) and all screens MUST use these spacing tokens instead of arbitrary dimensions. (P2)
- **FR-005**: All interactive elements MUST have a minimum touch target of 48x48 logical pixels. (H9 / UX-05)
- **FR-006**: The Statistics screen MUST display a loading state (shimmer/skeleton) while BLoCs are initializing. (H11 / UX-01)
- **FR-007**: The Arabic session score message MUST include the `{score}%` placeholder so Arabic users see their recitation accuracy percentage. (H10 / UX-04)
- **FR-008**: Settings screen section labels MUST use locale-aware capitalization, not `.toUpperCase()`, which garbles Arabic text. (P11)
- **FR-009**: Mushaf empty verse placeholders MUST display a localized message instead of a hardcoded "—". (UX-03)
- **FR-010**: The Search screen AppBar MUST use the theme default background, consistent with all other screens. (UX-06)

### Key Entities

- **AppTheme**: Centralized theme configuration containing ColorScheme extensions, TextTheme with Arabic/Latin font mappings, and spacing constants
- **SpacingTokens**: Named spacing values (xs=4, sm=8, md=12, lg=16, xl=24, xxl=32) used across all screens
- **TouchTarget**: Wrapper widget ensuring minimum 48x48 tap area while allowing smaller visual appearance

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero hardcoded hex color values exist in any screen or widget file (verified by codebase search).
- **SC-002**: Zero inline `TextStyle(fontFamily: ...)` or `TextStyle(fontSize: ...)` specifications in screen files — all reference the text theme.
- **SC-003**: All interactive elements pass accessibility audit with minimum 48x48 touch targets.
- **SC-004**: Statistics screen shows a loading indicator within 100ms of opening, before any data is loaded.
- **SC-005**: Arabic recitation score displays the numerical percentage (e.g., "85%") alongside the text message.
- **SC-006**: The hackathon judging score for "Product Quality & UX" improves from estimated 12-14 to 17-20 out of 20.

## Assumptions

- The existing `AppColors` class with 11 surah-specific tokens will be extended (not replaced) to become the centralized color system.
- Poppins and NotoNaskhArabic font assets are already bundled in the project and will continue to be used.
- The visual appearance of verse badges can remain smaller (28-32px) as long as the tappable area is 48x48 — achieved via padding or `Material` widget wrapping.
- The shimmer/skeleton loading pattern can follow Material 3 conventions or use a simple `LinearProgressIndicator` placeholder.
- Settings screen currently applies `.toUpperCase()` to English section labels — the fix should apply upper-casing only for non-Arabic locales.
