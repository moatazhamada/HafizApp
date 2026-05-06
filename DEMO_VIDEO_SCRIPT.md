# HafizApp — Quran Foundation Hackathon Demo Video Script

**Video Length:** 2:45–3:00  
**Format:** Screen recording with voiceover  
**Tone:** Passionate, authentic, demo-driven  
**Submission deadline:** May 20, 2026

---

## Pre-Production Notes

- **Record on an Android device** (or emulator at native resolution) with the production flavor build
- **Use a screen recorder** that captures touch indicators (e.g., Android Studio screen record, or `adb shell screenrecord`)
- **Prepare the app state** beforehand: log in to QF cloud sync, have bookmarks ready, record a short recitation session, set up a khatmah goal
- **Audio:** Record voiceover separately in a quiet room; sync in post
- **Editing:** CapCut, DaVinci Resolve, or similar — add subtle zoom on key interactions

---

## Video Script

### 🎬 SCENE 1 — HOOK (0:00–0:15)

**Visual:** App icon on home screen → tap to open → splash screen fades into the home screen showing the random verse widget and surah grid.

**Voiceover:**

> "After Ramadan ends, most people's Quran reading drops off dramatically. HafizApp is designed to change that — a comprehensive Quran companion that keeps you connected through beautiful reading, intelligent memorization coaching, and deep cloud sync with the Quran Foundation ecosystem."

---

### 🎬 SCENE 2 — MUSHAF & READING (0:15–0:50)

**Visual:** Tap a surah from the home grid → SurahScreen with Arabic text, RTL layout. Swipe/scroll through verses. Tap the **mushaf icon** → switch to MushafScreen with 604-page horizontal PageView. Show the three rendering modes (toggle in settings: text → ayah images → glyph).

**Voiceover:**

> "HafizApp offers three distinct mushaf rendering modes — text, ayah images, and glyph-based pixel-perfect rendering using Quran Foundation's code_v2 API. Users can choose between four mushaf styles at onboarding: Madani, Egyptian, Indo-Pak, or Warsh — catering to Muslims worldwide. Every page renders with proper RTL layout and beautiful Uthmani script."

**On-screen text overlay:** `Content API: Quran.com v4 verses, glyph codes (code_v2)`

---

### 🎬 SCENE 3 — TRANSLATION & TAFSIR (0:50–1:10)

**Visual:** From SurahScreen, tap a verse → VerseStudyScreen opens showing three tabs: Arabic text, Abdel Haleem English translation, Ibn Kathir tafsir — all side by side. Scroll through tafsir content.

**Voiceover:**

> "Understanding is key to connection. Every verse has instant access to translations and tafsir — powered by the Quran Foundation content APIs. Abdel Haleem's English translation and Ibn Kathir tafsir are available for every single ayah."

**On-screen text overlay:** `Content API: Translations (#85), Tafsirs (#169), Verse by key`

---

### 🎬 SCENE 4 — AUDIO & SHEIKH COACH (1:10–1:35)

**Visual:** Open AudioPlayerScreen. Select reciter (Al-Afasy). Play verse — show word-by-word highlighting as audio plays. Adjust speed. Toggle the Sheikh Audio Coach bottom sheet — show word-level sync highlighting each word as the sheikh recites.

**Voiceover:**

> "The audio player streams verse-by-verse recitation with word-level timing sync. But what makes HafizApp special is the Sheikh Audio Coach — it highlights each word in real-time as the reciter says it, creating an interactive model for memorization practice. You can loop specific verses, adjust playback speed, and set sleep timers."

**On-screen text overlay:** `Content API: Recitations with segments, Chapter audio`

---

### 🎬 SCENE 5 — VOICE VERIFICATION (1:35–1:55)

**Visual:** In SurahScreen, tap the microphone icon → start recitation mode. Show the user reciting a verse. Display real-time feedback: green (correct), red (mistakes), missing words. Show the recitation session saved. Navigate to RecitationErrorScreen showing logged errors.

**Voiceover:**

> "HafizApp goes beyond reading — it listens to you. Our voice verification uses a dual-engine approach: a local speech-to-text alignment algorithm and a real-time WebSocket connection to Qurani.ai for tajweed-level feedback. Mistakes are logged and reviewable, creating a feedback loop for continuous improvement."

**On-screen text overlay:** `Qurani.ai QRC WebSocket · Local STT + Levenshtein alignment`

---

### 🎬 SCENE 6 — CLOUD SYNC & USER APIS (1:55–2:20)

**Visual:** Open CloudSyncScreen → show OAuth2 login flow (QF PKCE). Then show bookmarks synced. Open KhatmahScreen showing a daily reading goal with streak counter. Open MemorizationScreen showing per-surah progress. Open StatisticsScreen showing reading analytics.

**Voiceover:**

> "Everything syncs to the Quran Foundation cloud via OAuth2. Bookmarks, reading goals, memorization progress, and daily streaks — all persisted across devices. We use over twenty QF API endpoints: bookmarks, collections, activity days, goals, reading sessions, and verse reflections. The khatmah feature creates personalized daily reading plans to build post-Ramadan habits."

**On-screen text overlay:** `User APIs: Bookmarks, Collections, Streaks, Activity Days, Goals, Reading Sessions, Posts`

---

### 🎬 SCENE 7 — HOME WIDGET & SMART FEATURES (2:20–2:40)

**Visual:** Show Android home screen with the HafizApp widget displaying a random verse. Tap the widget → deep link opens the app directly to that verse. Show the SearchScreen with semantic search results. Toggle language between English and Arabic in settings.

**Voiceover:**

> "A home screen widget keeps the Quran visible throughout your day — auto-refreshing with a new verse every hour. Tapping it deep-links directly to that verse. We also support Quran Foundation's semantic search and full bilingual localization — English and Arabic — switchable at runtime."

**On-screen text overlay:** `Content API: Random verse, Semantic search · Qiraat variants via QuranHub`

---

### 🎬 SCENE 8 — CLOSING (2:40–2:55)

**Visual:** Quick montage of key screens fading in/out. End on the home screen with the gold/green theme.

**Voiceover:**

> "HafizApp is an open-source, offline-first Quran companion built with Flutter. It deeply integrates the Quran Foundation content and user APIs to create a complete ecosystem for reading, understanding, memorizing, and staying connected with the Quran — long after Ramadan ends. Thank you."

**On-screen text overlay:**

```
HafizApp v3.1.0 · Open Source · Flutter
Content APIs: Quran.com v4, QuranHub, Qurani.ai
User APIs: Bookmarks, Goals, Streaks, Sessions, Posts
github.com/abualgait/HafizApp
```

---

## Storyboard — Quick Reference

| Time | Scene | Screen(s) | Key Action | API Highlight |
|------|-------|-----------|------------|---------------|
| 0:00 | Hook | Home → splash → surah grid | App launch | — |
| 0:15 | Mushaf | SurahScreen → MushafScreen | 3 render modes, 4 mushaf types | `verses/by_chapter`, `code_v2` glyphs |
| 0:50 | Tafsir | VerseStudyScreen | Arabic + translation + tafsir tabs | `translations/85`, `tafsirs/169` |
| 1:10 | Audio | AudioPlayerScreen | Word-level sync, Sheikh Coach | `chapter_recitations` + segments |
| 1:35 | Voice | SurahScreen (mic) | Recite → real-time feedback | Qurani.ai QRC WebSocket |
| 1:55 | Cloud Sync | CloudSync, Khatmah, Memorization | OAuth2 login, goals, streaks | 20+ User API endpoints |
| 2:20 | Smart | Home widget, Search | Widget tap, semantic search | Random verse, QF search |
| 2:40 | Close | Montage → home screen | Summary | All APIs listed |

---

## Recording Checklist

- [ ] Build production APK: `flutter build apk --release --flavor production`
- [ ] Install on test device
- [ ] Pre-populate: log into QF, add bookmarks, set khatmah goal, record 1 recitation session
- [ ] Enable touch indicators in Developer Options
- [ ] Record screen at 1080p minimum
- [ ] Record voiceover separately
- [ ] Edit with zoom on key interactions (especially word-level audio sync and voice verification)
- [ ] Add on-screen text overlays at timestamps noted above
- [ ] Export at 1080p, H.264, AAC audio
- [ ] Final review: check that API usage is clearly demonstrated (judging criteria: "Effective Use of APIs" = 15 points)

---

## Judging Criteria Alignment

| Criterion (pts) | How This Video Addresses It |
|-----------------|-----------------------------|
| **Impact on Quran Engagement (30)** | Streaks, khatmah goals, daily verse widget, memorization coaching — all designed for post-Ramadan retention |
| **Product Quality & UX (20)** | Beautiful Material 3 theme, smooth RTL mushaf, 4 mushaf types, bilingual |
| **Technical Execution (20)** | Triple-mode rendering, dual-engine voice verification, offline-first, word-level audio sync |
| **Innovation & Creativity (15)** | Sheikh Audio Coach, QRC WebSocket tajweed feedback, Qiraat variants, home widget deep links |
| **Effective Use of APIs (15)** | 30+ endpoints across Content + User APIs — one of the deepest integrations possible |
