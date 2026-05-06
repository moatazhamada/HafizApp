# Hafiz App — Quran Foundation Hackathon Submission

## Project Title

**Hafiz — Post-Ramadan Quran Companion**

## Team

<!-- Add your team member names here before submitting -->
- [Your Name]

## Demo Video

<!-- Link your 2-3 minute demo video here after uploading (YouTube unlisted, Loom, or similar) -->
- [Demo Video Link]

## GitHub Repository

https://github.com/abualgait/HafizApp

## Live App

https://play.google.com/store/apps/details?id=com.hafiz.app.hafiz_app

---

## Problem

Every Ramadan, millions of Muslims reconnect with the Quran. They set ambitious goals — complete a khatmah, memorize a surah, perfect their recitation. But once Ramadan ends, the momentum fades. Without tools to track progress, get feedback on recitation, and maintain a daily connection, that spiritual habit dissolves within weeks.

**The gap:** There is no single app that combines reading, memorization practice, voice verification, and progress tracking while syncing across devices via a trusted Quran API.

## Solution

Hafiz bridges this gap. It's an open-source Flutter app that helps users maintain their daily Quran engagement through four integrated pillars:

1. **Read** — Clean mushaf view (604 pages), surah-by-surah reading with translations and tafsir, auto-scroll, juz index
2. **Memorize** — Hifz mode (hide/reveal verses), per-ayah memorization tracking, spaced-repetition review scheduling
3. **Perfect** — Voice verification engine comparing recitation against expected text using edit-distance alignment, with word-level accuracy feedback, support for on-device Whisper models
4. **Track** — Khatmah (complete reading) tracker with daily goals, streak visualization, memorization progress dashboard, reading session history

All synced to the **Quran Foundation** cloud so users never lose progress across devices.

## Quran Foundation API Usage

Hafiz integrates **34 API endpoints** across the Quran Foundation ecosystem — one of the deepest integrations of any Quran app:

### Content API (Quran.com v4) — 8 endpoints

| Endpoint | Feature | Why it matters |
|----------|---------|----------------|
| `GET /verses/by_chapter/{id}` | Surah text loading | Fetches Uthmani text with word-level data for all verses |
| `GET /verses/by_key/{key}` | Single verse lookup | Exact text for voice verification comparison and tafsir |
| `GET /verses/by_page/{n}` | Mushaf page rendering | Glyph codes (`code_v1`, `code_v2`), line positioning for 604-page mushaf — **pixel-perfect rendering** |
| `GET /verses/random` | Daily verse widget | Home screen random verse with translation — auto-refreshes hourly |
| `GET /translations/85/by_chapter/{id}` | Translation display | Abdel Haleem English translation, paginated and cached |
| `GET /tafsirs/169/by_ayah/{key}` | Per-verse tafsir | Ibn Kathir tafsir in bottom sheet and study screen |
| `GET /tafsirs/169/by_chapter/{id}` | Bulk tafsir load | Pre-fetches full surah tafsir with pagination |
| `GET /resources/recitations` + `/chapter_recitations/{id}/{chapter}` | Audio with word sync | Reciter listings + word-level timing segments for highlighted playback |

### User API (Quran Foundation Auth v1) — 20 endpoints

| Endpoint | Feature | Why it matters |
|----------|---------|----------------|
| `POST /activity-days` | Reading activity sync | Reports daily reading events — feeds streak calculations |
| `GET /activity-days` | Activity history | Full reading activity log |
| `GET /streaks/current-streak-days` | Cloud streak | Server-computed streak reconciled with local streak |
| `GET /streaks` | Streak history | Long-term streak visualization |
| `POST /goals` | Reading goals | Syncs daily verse targets to cloud |
| `PUT /goals/{id}` | Update goals | Track progress toward memorization/reading goals |
| `DELETE /goals/{id}` | Remove goals | Clean up completed or abandoned goals |
| `GET /goals/get-todays-plan` | Daily plan | Personalized reading plan with progress percentage |
| `GET /goals/estimate` | Timeline estimation | Predicts goal completion date |
| `POST /reading-sessions` | Session tracking | Records each reading session with position |
| `GET /reading-sessions` | Session history | Full historical log |
| `GET /bookmarks` | Pull bookmarks | Fetches cloud bookmarks for local merge |
| `POST /bookmarks` | Push bookmarks | Uploads local bookmarks to cloud |
| `DELETE /bookmarks/{id}` | Remove bookmark | Bidirectional delete sync |
| `GET /collections` | List collections | Bookmark organization |
| `POST /collections` | Create collection | Auto-creates "Hafiz Bookmarks" collection |
| `POST /posts` | Verse reflections | Personal reflections linked to specific verses |
| `GET /posts` | View reflections | Retrieve reflections for a verse |
| `DELETE /posts/{id}` | Delete reflection | Manage personal content |
| `GET /search?q=...` | Semantic search | AI-powered verse search beyond keyword matching |

### Authentication (OAuth2 + PKCE) — 3 endpoints

- **`/oauth2/auth`** — PKCE authorization redirect
- **`/oauth2/token`** — Token exchange and refresh (auto-retry on 401)
- **`/oauth2/revoke`** — "Delete My Data" compliance — revokes tokens and clears all synced content

### External Integrations

| Source | Purpose |
|--------|---------|
| **QuranHub API** (`api.quranhub.com/v1`) | Qiraat editions — view ayah text in Hafs, Warsh, Qaloon, and other recitation variants |
| **Qurani.ai QRC** (`wss://api.qurani.ai`) | Real-time recitation verification via WebSocket — streams Opus audio, receives tajweed-level feedback |
| **EveryAyah CDN** | Ayah PNG images for mushaf image rendering mode |
| **Tanzil (local assets)** | Offline-first Uthmani text stored as per-surah JSON — always available without network |

### Impact

Hafiz transforms daily Quran engagement from a seasonal habit into a sustained practice:

- **Streak visualization** (local + cloud reconciled) keeps users motivated — missing a day breaks the streak
- **Voice verification with word-level accuracy** gives immediate, actionable feedback without needing a teacher
- **Cloud sync** means users who switch devices or reinstall never lose bookmarks, progress, or reading history
- **Daily verse notifications** bring the Quran back into the user's day even when they forget to open the app

Built for the global Muslim community. Open source. Non-profit.

## Tech Stack

- **Framework:** Flutter 3.x (Dart)
- **Architecture:** Clean Architecture (Presentation → Domain → Data)
- **State Management:** BLoC + HydratedBloc
- **DI:** GetIt
- **Local Storage:** Hive, SharedPreferences
- **Network:** Dio with OAuth2 interceptors
- **Voice:** speech_to_text, flutter_sound, whisper_ggml_plus
- **Push:** flutter_local_notifications
- **Authentication:** flutter_appauth (OAuth2/OpenID Connect)
- **CI/CD:** GitHub Actions + Fastlane

## App Store & Source

- **Google Play:** https://play.google.com/store/apps/details?id=com.hafiz.app.hafiz_app
- **Source:** https://github.com/abualgait/HafizApp
- **Version:** 3.1.0+15
- **Platforms:** Android (primary), iOS
- **License:** Open-source, non-profit (Sadaqah Jariyah)

---

## Submission Checklist

- [x] Project title
- [ ] Team member names
- [x] Short description
- [x] Detailed explanation
- [x] Live demo / working app link (Play Store)
- [x] GitHub repository
- [ ] 2–3 minute demo video (script: `DEMO_VIDEO_SCRIPT.md`)
- [x] API usage description (34 endpoints documented above)
