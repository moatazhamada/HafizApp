# Hafiz App — Hackathon Submission

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

Hafiz makes extensive use of the Quran Foundation's v4 Content API and v1 Auth API:

### Content API v4

| Endpoint | Feature | Why it matters |
|----------|---------|----------------|
| `GET /quran/verses/by_key/{key}` | Verse text retrieval | Fetches exact Uthmani text for voice verification comparison |
| `GET /quran/verses/by_page/{page}` | Mushaf page rendering | Loads verse mappings, glyph codes (`code_v1`, `code_v2`), line positioning for 604-page mushaf |
| `GET /translations/{id}/by_chapter/{id}` | Translation display | Fetches all verses of a surah with pagination (`per_page=50`), cached locally |
| `GET /translations/{id}/by_ayah/{key}` | Per-verse translation | Quick lookup for verse context menus and study screen |
| `GET /tafsirs/{id}/by_ayah/{key}` | Tafsir display | Ibn Kathir tafsir per ayah via bottom sheet |
| `GET /tafsirs/{id}/by_chapter/{id}` | Bulk tafsir load | Pre-fetches all tafsir for a surah with pagination |
| `GET /resources/recitations` | Audio listings | Available reciters and chapter recitations for audio playback |

### Auth API v1

| Endpoint | Feature | Why it matters |
|----------|---------|----------------|
| `POST /activity-days` | Reading activity sync | Reports daily reading events (type `QURAN`, verses read, time spent) — feeds streak calculations |
| `GET /streaks/current-streak-days` | Cloud streak | Fetches server-computed streak for reconciliation with local streak |
| `POST /goals` | Reading goals | Syncs daily verse targets to cloud |
| `GET /goals/get-todays-plan` | Goal progress | Pulls today's plan with progress percentage |
| `POST /reading-sessions` | Session tracking | Reports each reading session (last verse position) |
| `POST/PUT/DELETE /bookmarks` | Bookmark sync | Bidirectional sync — push local bookmarks, pull cloud bookmarks. Uses "Hafiz Bookmarks" collection |
| `POST /collections` | Bookmark organization | Creates/manages bookmark collections |
| `POST /posts` | Verse reflections | Users add personal reflections linked to specific verses |

### Authentication

- **OAuth2 + PKCE** via `flutter_appauth` with OpenID Connect
- Handles token refresh automatically via Dio interceptors
- "Delete My Data" support revokes tokens and removes synced content per QF Developer Terms

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

## App Store

- **Google Play:** https://play.google.com/store/apps/details?id=com.hafiz.app.hafiz_app
- **Source:** https://github.com/abualgait/HafizApp
- **Version:** 3.1.0 (hackathon release)
