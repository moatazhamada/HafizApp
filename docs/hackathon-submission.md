# Hafiz App — Quran Foundation Hackathon Submission

> **Version:** 3.3.0+23  
> **Live Demo:** https://moatazhamada.github.io/HafizApp/  
> **Video Walkthrough:** https://youtu.be/A9g0FEGydnY  
> **Download:** [APK](https://github.com/moatazhamada/HafizApp/raw/hackathon-demo-page/appbundle/hafiz-3.3.0+23.apk) | [AAB](https://github.com/moatazhamada/HafizApp/raw/hackathon-demo-page/appbundle/hafiz-3.3.0+23.aab)

## Project Overview

**Hafiz** is a comprehensive Quran companion app designed to strengthen users' relationship with the Quran through adaptive, personalized experiences. It combines deep Quran.Foundation API integration with intelligent UX that adapts to each user's behavior and goals.

---

## Technical Requirements Checklist

### ✅ Content API Usage

| API Category | Endpoints Used | Feature |
|-------------|----------------|---------|
| **Quran APIs** | `GET /verses/by_chapter/{id}` | Surah reading with Uthmani text |
| | `GET /verses/by_key/{key}` | Verse study & word-level data |
| | `GET /verses/by_page/{page}` | Mushaf page rendering with glyph codes |
| | `GET /verses/random` | Daily verse of the day |
| **Audio APIs** | `GET /resources/recitations` | Reciter list |
| | `GET /chapter_recitations/{id}/{chapter}` | Chapter audio playback |
| **Tafsir APIs** | `GET /tafsirs/{id}/by_ayah/{key}` | Per-ayah tafsir |
| | `GET /tafsirs/{id}/by_chapter/{id}` | Chapter tafsir |
| **Translation APIs** | `GET /translations/{id}/by_chapter/{id}` | English translation (The Clear Quran) |
| **Post APIs** | `GET /auth/v1/posts/feed` | Quran Reflect community feed |
| | `GET /auth/v1/posts?verseKey={key}` | Verse-specific reflections |
| | `POST /auth/v1/posts` | Create reflections |
| **Search API** | `GET /search?q={query}` | Quran text search |
| **Verse Media** | `GET /verses/media?verse_key={key}` | Verse-related images/media |

All content APIs route through **`api.quran.foundation`** (switched from legacy `api.quran.com`).

### ✅ User API Usage

| API Category | Endpoints Used | Feature |
|-------------|----------------|---------|
| **Bookmarks** | `GET/POST/DELETE /auth/v1/bookmarks` | Real-time sync on add/remove + batch sync |
| **Collections** | `GET/POST /auth/v1/collections` | Bookmark collections (auto-created 'Hafiz Bookmarks') |
| **Streak Tracking** | `GET /auth/v1/streaks/current-streak-days` | Reading streak counter |
| | `GET /auth/v1/streaks` | Streak history |
| **Activity & Goals** | `POST /auth/v1/activity-days` | Log daily reading activity |
| | `GET /auth/v1/activity-days` | Activity history for heatmap |
| | `GET/POST /auth/v1/goals` | Reading goals & plans |
| | `GET /auth/v1/goals/get-todays-plan` | Today's reading plan |
| **Reading Sessions** | `POST /auth/v1/reading-sessions` | Track reading sessions (fired after each recitation) |
| | `GET /auth/v1/reading-sessions` | Session history |
| **Posts** | `POST /auth/v1/posts` | Share reflections |
| | `GET /auth/v1/posts/feed` | Community reflections feed |

### ✅ Authentication

- **OAuth2 Authorization Code + PKCE** with OpenID Connect
- Backend-safe token exchange (confidential client pattern)
- Automatic scope fallback for graceful degradation
- `offline_access` for refresh tokens

---

## Judging Criteria Alignment

### Impact on Quran Engagement (30 points)

**Adaptive Surfaces** — The app detects user behavior and presents one of three home screen surfaces:
- **Reader Surface**: Minimal, search-first layout for elderly/traditional users
- **Student Surface**: Dashboard with memorization progress, activity heatmap, streaks, and review queue
- **Seeker Surface**: Discovery-focused with verse of the day, today's juz, Quran Reflect feed, and topic search

**Behavior Tracking** — After 7 sessions, the app gently suggests switching surfaces based on usage patterns (search-heavy → Seeker, bookmark/memorization-heavy → Student).

**Memorization System** — Full memorization tracker with due reviews using spaced repetition concepts.

**Khatmah & Goals** — Reading goals with daily plans, streak tracking, and progress visualization.

### Product Quality & UX (20 points)

**Responsive Design** — All major screens adapt to tablets (>900px) with NavigationRail, constrained content widths, and touch-friendly targets.

**Animations** — Staggered entry animations, cross-fade surface transitions, and smooth scroll-triggered effects.

**Accessibility** — Large touch targets, semantic labels, RTL support for Arabic, and offline-first architecture.

**Material 3** — Consistent theming, color scheme adaptation, and modern component usage.

### Technical Execution (20 points)

**Architecture** — Clean Architecture with BLoC pattern, dependency injection (GetIt), and repository pattern.

**API Integration Depth** — 20+ endpoints across 4 API categories with proper error handling, caching (memory + Hive), and graceful fallbacks.

**Offline-First** — Local Quran text, cached API responses, and sync-on-connect for user data.

**QRC Integration** — Real-time recitation correction via WebSocket (Qurani.ai QRC).

### Innovation & Creativity (15 points)

**User Archetypes** — Onboarding flow with archetype selection (Reader/Student/Seeker/Devotee) that personalizes the entire app experience.

**Adaptive Home** — The home screen is not static; it evolves based on the user's archetype and behavior.

**Activity Heatmap** — GitHub-style visualization of reading activity using Quran.Foundation Activity Day data.

**Reading Session Insights** — Today's duration + weekly bar chart showing verses read per day.

**Quran Reflect Feed** — Community reflections feed demonstrating deep Post API integration.

**Verse Media** — Image carousel in Random Verse card showing verse-related media from Content API.

**Real Recent Search History** — SharedPreferences-backed search history with functional clear button.

### Effective Use of APIs (15 points)

**Content API Migration** — Fully migrated from legacy `api.quran.com` to `api.quran.foundation` content endpoints.

**User API Breadth** — Uses bookmarks, collections, streaks, activity days, goals, reading sessions, and posts.

**Auth Best Practices** — PKCE flow, backend token exchange, scope fallback, and refresh token handling.

---

## API Configuration

```dart
// Content API base
static const String qfContentBase = 'https://api.quran.foundation';

// User API base
static const String productionApiBaseUrl = 'https://apis.quran.foundation';

// OAuth2
static const String productionAuthBaseUrl = 'https://oauth2.quran.foundation';

// Scopes requested
[
  'openid', 'offline_access', 'user',
  'bookmark', 'collection', 'reading_session',
  'goal', 'streak', 'activity_day', 'post',
  'preference', 'content', 'search'
]
```

---

## Screenshots & Demo Flow

### Onboarding
1. Language selection (EN/AR/System)
2. User archetype selection (Reader/Student/Seeker/Devotee)
3. Mushaf type preference

### Home Screens
- **Reader**: Large search bar, continue reading card, full Surah index with Juz headers
- **Student**: Memorization progress, activity heatmap, reading insights, streak card, stats grid, quick actions
- **Seeker**: Smart search, discovery cards (Verse of Day, Today's Juz, Quran Reflect), real recent search history

### Tablet Workspace
- NavigationRail with 10 destinations on screens >900px
- Auth header with avatar/sign-in state
- Same adaptive surfaces optimized for larger screens

### Quran Reflect
- Community reflections feed
- Author info, timestamps, verse references
- Pull-to-refresh

---

## GitHub Repository

**Primary Branch:** `feature/creativity-and-enhancements-to-the-app`  
**Hackathon Demo Branch:** `hackathon-demo-page` (hosts the live demo site + signed builds)

Key commits:
1. `refactor: make screens responsive on large displays`
2. `feat: adaptive onboarding flow with language + archetype selection`
3. `feat: implement Student & Seeker surfaces with adaptive behavior tracking`
4. `feat: Phase 6 - staggered animations and surface cross-fade transitions`
5. `refactor: route all content APIs through Quran.Foundation`
6. `feat: add Activity Heatmap and wire Verse of the Day to RandomVerseCard`
7. `feat: add Quran Reflect feed screen and update About screen for hackathon`
8. `feat: reading insights, verse media, and Quran Reflect animations`
9. `feat: real recent search history + Quran Reflect i18n + final polish`

---

## Future Enhancements (Post-Hackathon)

- **Hadith References**: Show hadiths related to specific ayahs
- **Rooms/Groups**: Community reading groups via Quran.Foundation Rooms API
- **Advanced Search**: Semantic search using Search API v1
- **Notes API**: Personal verse notes with Quran.Foundation sync

---

*Built with Flutter, powered by Quran.Foundation APIs, designed for the Ummah.*
