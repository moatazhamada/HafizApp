# Hafiz — Quran Memorization Assistant

![image](https://github.com/abualgait/HafizApp/assets/38107393/aaa45a94-030c-40fc-afb6-108bd43f8742)

**Maintain your daily connection with the Quran — read, memorize, perfect your recitation, and track your progress.**

[![Google Play](https://img.shields.io/badge/Google_Play-Download-green?logo=google-play)](https://play.google.com/store/apps/details?id=com.hafiz.app.hafiz_app)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)

---

## Features

### 📖 Reading
- **Mushaf View** — 604-page horizontal RTL PageView with 3 rendering modes (text, ayah images, QF glyph code_v2), jump-to-page, surah info overlay
- **Surah-by-Surah** — Per-verse reading with inline translation toggle, auto-scroll (0.25x–3.0x), juz index grid
- **Audio Player** — Verse-by-verse playback with speed control (0.5x–2x), sleep timer, loop

### 🧠 Memorization
- **Hifz Mode** — Hide/reveal verses for self-testing, tap to reveal individual verses
- **Memorization Tracker** — Per-surah status (memorized/in-progress/not-started), spaced-repetition review scheduling
- **Practice List** — Mark difficult verses, review them separately

### 🎙 Voice Verification
- Recite any verse and get instant feedback — compares spoken recitation against expected text
- **Word-level accuracy** — Each word color-coded green (correct) or red (mismatch)
- Supports on-device **Whisper** models (tiny/base/small), custom ASR endpoint, and sheikh audio coaching

### 📊 Progress Tracking
- **Khatmah Tracker** — Daily reading goals with interactive presets (10/20/50/100/200 verses), today's progress ring
- **Streak Visualization** — Weekly heatmap + **cloud-reconciled streak** (local streak merged with Quran Foundation cloud streak)
- **Memorization Dashboard** — Overall progress, due-for-review reminders, per-surah status cards
- **Statistics** — Bookmark count, practice verse count, reading activity summary

### ☁️ Cloud Sync (Quran Foundation)
- **Bookmark Sync** — Bidirectional push/pull via QF Collections ("Hafiz Bookmarks")
- **Activity Sync** — Daily reading activity reported to QF for streak computation
- **Goals Sync** — Daily verse targets pushed to QF Goals API
- **Verse Reflections** — Personal notes linked to specific verses via QF Post API
- **OAuth2/OpenID Connect** — Secure authentication with PKCE, token refresh, "Delete My Data" support

### 🎨 UX
- Shimmer loading skeletons on khatmah dashboard, bookmarks list, and surah screens
- Haptic feedback on bookmark toggle, hifz mode reveal, voice verification results
- Pull-to-refresh on khatmah dashboard and bookmarks
- Error states with localized messages and retry buttons
- Daily verse notification — start each day with a random Quran verse

### ⚙️ Settings
- Language (English/Arabic/System) — all UI and Quran metadata localized
- Theme (Light/Dark/System)
- Quran font size (16–40)
- Orientation (System/Portrait/Landscape)
- Mushaf type (Madani/Egyptian/Indo-Pak/Warsh)
- Recitation coach settings (provider, qiraat, reciter, whisper model)
- Daily verse notification toggle

---

## Architecture

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the full layer diagram, data flow, dependency injection structure, and API integration details.

```
Presentation (UI + BLoC)
    ↓
Domain (Entities, Repository Interfaces, Use Cases)
    ↓
Data (Data Sources, Models, Repository Implementations)
    ↓
Core (Config, Theme, Network, Utils)
```

---

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run debug (with production flavor)
flutter run --flavor production

# Run all tests
flutter test

# Analyze
flutter analyze

# Build release APK
flutter build apk --release --flavor production
```

### Environment Variables

Set these for Quran Foundation API integration:

```bash
export QF_CLIENT_ID="your-client-id"
export QF_CLIENT_SECRET="your-client-secret"
export QF_PRODUCTION=true  # default: true
```

---

## Quran Text Source

- Unmodified Uthmani text from verified Tanzil repository
- Bundled locally as per-surah JSON under `assets/quran/uthmani/`
- Remote fallback via Quran.com API v4 only if local file is missing

---

## Acknowledgments

- **Original concept & foundation:** [abualgait](https://github.com/abualgait)
- **Source:** [HafizApp](https://github.com/abualgait/HafizApp)
- **Quran Foundation** — APIs for content, authentication, and user data sync
- **Tanzil** — Verified Uthmani Quran text (CC BY-ND 3.0)

This app is non-profit. Intended as a good deed for us and our families.

---

## License

MIT License — see [LICENSE](LICENSE)
