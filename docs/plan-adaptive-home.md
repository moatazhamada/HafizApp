# Adaptive Home Screen — Implementation Plan

## Vision
Transform the home screen from a static Surah list into an **adaptive surface** that respects the user's mental model—whether they are a Reader, Student, Seeker, or Devotee—while keeping the full index instantly accessible for everyone.

## Core Principles
1. **Elderly-first default** — The "Reader" surface is the default. No learning curve.
2. **Behavioral adaptation, not settings toggles** — Surfaces adapt based on usage patterns.
3. **Suggestive, not forced** — After 7 sessions, gently suggest a better surface. The user decides.
4. **Respectful minimalism** — Animations are smooth but never flashy. SVGs are subtle, decorative.
5. **Scalable architecture** — New features = new cards/widgets, never nav restructuring.

---

## Architecture

```
HomeScreen
└── AdaptiveHomeBloc (manages surface state + behavior tracking)
    ├── UserArchetype (from onboarding: reader | student | seeker | devotee)
    ├── BehaviorTracker (7-session lightweight local tracker)
    ├── SurfaceType (active surface)
    └── ScreenSize (phone | tablet)

Surfaces (Widgets):
├── ReaderSurface      → Surah index dominates, minimal chrome
├── StudentSurface     → Dashboard cards first, compact index below
├── SeekerSurface      → Search-first, discovery cards, index below
└── TabletWorkspace    → Rail + cards + grid + preview pane (iPad)

Shared Components:
├── SurahIndexWidget       (configurable: list | grid | compact)
├── ContinueReadingCard
├── ProgressMiniCards
├── AdaptiveSearchBar
├── JuzChipRow
├── SurfaceSuggestionBanner (gentle nudge after 7 sessions)
└── AnimatedDecorations (subtle SVGs)
```

---

## Data Models

### `UserArchetype`
```dart
enum UserArchetype {
  reader,      // Default — reads sequentially, simple needs
  student,     // Memorizing, tracking progress
  seeker,      // Searching, exploring meanings
  devotee,     // Daily rituals, Khatmah, streaks
}
```

### `SurfaceType`
```dart
enum SurfaceType {
  reader,      // Index-first, large text, minimal chrome
  student,     // Dashboard-first, stats visible
  seeker,      // Search-first, discovery cards
}
```

### `BehaviorSession`
```dart
class BehaviorSession {
  final DateTime timestamp;
  final String primaryAction;   // 'read', 'search', 'bookmark', 'memorize', etc.
  final int durationSeconds;    // approximate session duration
}
```

### `SurfaceSuggestion`
```dart
class SurfaceSuggestion {
  final SurfaceType suggestedSurface;
  final String reasonKey;       // i18n key explaining why
  final bool dismissed;
}
```

---

## Onboarding Flow (Revised)

```
Step 1: Language Selection
  ├─ "Choose your preferred language"
  ├─ 🇬🇧 English  /  🇸🇦 العربية
  └─ Auto-detects from device but lets user override

Step 2: Archetype Selection  
  ├─ "How do you plan to use the app?"
  ├─ 📖 Read & Reflect     → Reader Surface
  ├─ 🎓 Memorize & Learn   → Student Surface
  ├─ 🔍 Search & Explore   → Seeker Surface
  └─ ✨ Daily Practice      → Devotee Surface

Step 3: Mushaf Type (existing)
```

**Language selection must come FIRST** because it affects all subsequent UI text, RTL layout, and even archetype descriptions.

---

## Phase Breakdown

### Phase 1: Foundation
- [ ] Create `SurfaceType`, `UserArchetype`, `BehaviorSession` models
- [ ] Create `AdaptiveHomeBloc` with surface management + behavior tracking
- [ ] Create `PrefUtils` extensions for pers archetype, sessions, suggestion state
- [ ] Create shared widget stubs: `SurahIndexWidget`, `ContinueReadingCard`, `AdaptiveSearchBar`
- [ ] Update onboarding: Add **Language Selection** as Step 1
- [ ] Update onboarding: Add **Archetype Selection** as Step 2
- [ ] Wire onboarding → surface preference

### Phase 2: Reader Surface (Default)
- [ ] Implement `ReaderSurface` widget
  - Full-screen Surah list with Juz section headers
  - Prominent search bar at top
  - Optional "Continue Reading" card (collapses if no recent activity)
  - Large touch targets (64px min)
  - Clean dividers, no heavy shadows
- [ ] Sticky Juz headers using `SliverPersistentHeader`
- [ ] Smooth scroll-to-Juz via right-side scrollbar or chips

### Phase 3: Student & Seeker Surfaces
- [ ] Implement `StudentSurface` widget
  - Dashboard cards: Goals, Memorization Progress, Practice List
  - Compact Surah index below fold
- [ ] Implement `SeekerSurface` widget
  - Large search bar + recent searches
  - Discovery cards: Verse of Day, Related Topics
  - Compact Surah index below

### Phase 4: Adaptive Behavior Engine
- [ ] Track 7 sessions locally (action type, timestamp)
- [ ] After 7 sessions: analyze dominant action type
- [ ] Show `SurfaceSuggestionBanner` if detected mismatch
  - "You seem to be tracking your memorization a lot. Switch to Student view?"
  - "Keep Current" / "Try It" buttons
  - Dismissible, never returns if dismissed

### Phase 5: Tablet Workspace
- [ ] Permanent `NavigationRail` on left for screens > 600px
- [ ] Two-column layout: cards + Surah grid
- [ ] Preview pane: tap Surah → see metadata + actions without leaving
- [ ] Surface-specific card arrangement for tablets

### Phase 6: Polish
- [ ] Add subtle SVG decorations (geometric Islamic patterns, faint background)
- [ ] Entry animations for cards (staggered fade + translate)
- [ ] Scroll-triggered animations for list items
- [ ] Hero transitions preserved for Surah titles

---

## Animation Specs (Restrained)

| Element | Animation | Duration | Curve |
|---------|-----------|----------|-------|
| Card entry | Fade + translateY(20→0) | 400ms | easeOutQuad |
| List item entry | Fade + translateX | 300ms | easeOut |
| Surface switch | Cross-fade | 300ms | easeInOut |
| Search expand | Width + height | 250ms | easeOutCubic |
| Juz header sticky | Opacity fade on collapse | 150ms | linear |
| Suggestion banner | Slide down + fade | 400ms | easeOutBack |
| SVG decorations | Slow continuous float (±4px) | 6s | sine |

**No bouncy animations. No rotation. No scale pops.**

---

## SVG Decorations (Subtle)

- **Background pattern**: Very low opacity (3-5%) geometric Islamic pattern behind the Surah list
- **Hero card accent**: Small decorative corner flourish on Continue Reading card
- **Empty state**: Elegant illustration for "No recent activity"
- **Suggestion banner**: Small lightbulb or compass icon

All SVGs: single-color, theme-aware (`primary` at 10% opacity).

---

## Responsive Breakpoints

| Breakpoint | Behavior |
|------------|----------|
| < 600px (Phone) | Single column, surface layout |
| 600-900px (Large Phone / Small Tablet) | Surface layout with slightly wider cards |
| > 900px (Tablet / iPad) | `TabletWorkspace` with rail + grid + preview |

---

## Files to Create / Modify

### New Files
```
lib/presentation/home_screen/bloc/adaptive_home_bloc.dart
lib/presentation/home_screen/bloc/adaptive_home_event.dart
lib/presentation/home_screen/bloc/adaptive_home_state.dart
lib/presentation/home_screen/surfaces/reader_surface.dart
lib/presentation/home_screen/surfaces/student_surface.dart
lib/presentation/home_screen/surfaces/seeker_surface.dart
lib/presentation/home_screen/surfaces/tablet_workspace.dart
lib/presentation/home_screen/widgets/surah_index_widget.dart
lib/presentation/home_screen/widgets/continue_reading_card.dart
lib/presentation/home_screen/widgets/adaptive_search_bar.dart
lib/presentation/home_screen/widgets/juz_header.dart
lib/presentation/home_screen/widgets/surface_suggestion_banner.dart
lib/presentation/onboarding_screen/language_selection_page.dart
lib/presentation/onboarding_screen/archetype_selection_page.dart
lib/core/models/user_archetype.dart
lib/core/models/surface_type.dart
lib/core/models/behavior_session.dart
lib/core/tracking/behavior_tracker.dart
```

### Modified Files
```
lib/presentation/onboarding_screen/onboarding_screen.dart
lib/presentation/home_screen/home_screen.dart
lib/core/utils/pref_utils.dart
lib/routes/app_routes.dart
```

---

## Open Questions

1. Should we derive Surah metadata (verse count, revelation type) from existing indices or add to `QuranSurah` model?
2. Should the behavior tracker be a simple `List<String>` in SharedPreferences or a lightweight Hive/sembast box?
3. For iPad preview pane: should tapping a Surah show inline preview or push to detail? (Master-detail vs. push)
4. Do we want to support swipe-to-switch surfaces as a power-user gesture?
