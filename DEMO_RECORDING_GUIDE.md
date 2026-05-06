# Demo Recording Preparation Guide

## 1. Build the App

```bash
cd /Users/mm/Main/Projects/Android/HafizApp
flutter build apk --release --flavor production
```

Install on your test device:
```bash
adb install build/app/outputs/flutter-apk/app-production-release.apk
```

---

## 2. Pre-Populate App State

Before recording, prepare the app so every feature demo flows smoothly:

### Cloud Sync Setup
- [ ] Open Settings → Cloud Sync → Log in with Quran Foundation OAuth2
- [ ] Verify bookmarks sync completes (green checkmark)

### Bookmarks
- [ ] Bookmark 5–8 verses across different surahs (e.g., Al-Fatiha 1:1, Al-Baqarah 2:255, Ya-Sin 36:1, Ar-Rahman 55:13, Al-Ikhlas 112:1)

### Khatmah / Reading Goal
- [ ] Open Khatmah screen → create a daily reading goal (e.g., 5 pages/day)
- [ ] Verify the streak counter shows at least 1 day

### Audio
- [ ] Open any surah → start audio playback with Al-Afasy
- [ ] Let it buffer briefly so playback starts instantly during recording
- [ ] Pre-cache audio for Surah Al-Fatiha and Al-Baqarah 255

### Voice Verification
- [ ] Record 1–2 recitation sessions beforehand
- [ ] Ensure Recitation Sessions screen has history
- [ ] Ensure Recitation Errors screen has some logged errors

### Memorization
- [ ] Mark a few surahs as partially memorized in the Memorization screen

### Widget
- [ ] Add the HafizApp widget to your Android home screen
- [ ] Verify it shows a random verse

### Theme & Language
- [ ] Set theme to Dark (gold/green looks best on camera)
- [ ] Keep language on English for the demo video

---

## 3. Device Setup

### Developer Options
- [ ] Enable **Show taps** (Settings → Developer Options → Show taps)
  - This makes it clear to viewers where you're touching
- [ ] Set animation speed to 1x (don't speed up/slow down system animations)
- [ ] Disable notification popups (turn on Do Not Disturb)

### Screen Recording
- [ ] Use Android Studio's built-in screen recorder, or:
  ```bash
  adb shell screenrecord /sdcard/hafiz-demo.mp4
  ```
  (Max 3 minutes, 1080p. Press Ctrl+C to stop. Then `adb pull /sdcard/hafiz-demo.mp4`)
- [ ] Alternatively, use a third-party screen recorder with internal audio capture

### Clean Home Screen
- [ ] Move app icon to center of home screen for the opening shot
- [ ] Remove distracting notifications

---

## 4. Recording Flow (3-minute take)

Practice this sequence a few times before the final take:

| Step | Action | Duration |
|------|--------|----------|
| 1 | Home screen with widget → tap widget (deep link) | 5s |
| 2 | Home screen loads → show random verse, surah grid | 5s |
| 3 | Tap Al-Fatiha → scroll verses, show Arabic text | 5s |
| 4 | Tap verse → show bookmark, share, tafsir options | 5s |
| 5 | Tap tafsir → show Ibn Kathir tafsir bottom sheet | 5s |
| 6 | Back → tap mushaf icon → show 604-page view | 5s |
| 7 | Pinch/zoom on mushaf page → show glyph rendering | 5s |
| 8 | Open Audio Player → play with word highlighting | 10s |
| 9 | Show Sheikh Audio Coach → word-level sync | 10s |
| 10 | Go to surah → tap mic → start voice verification | 10s |
| 11 | Show real-time feedback (green/red words) | 5s |
| 12 | Open Recitation Sessions → show history | 5s |
| 13 | Open Recitation Errors → show logged mistakes | 5s |
| 14 | Open Khatmah → show reading goal + streak | 5s |
| 15 | Open Memorization → show per-surah progress | 5s |
| 16 | Open Cloud Sync → show logged-in state, synced data | 5s |
| 17 | Open Search → type "mercy" → show semantic results | 5s |
| 18 | Open Bookmarks → show saved verses | 5s |
| 19 | Open Settings → toggle language to Arabic briefly | 5s |
| 20 | Final shot: home screen → fade out | 3s |

---

## 5. Voiceover Recording Tips

- Record in a quiet room with a decent mic (even AirPods work)
- Read from the script in `DEMO_VIDEO_SCRIPT.md` but keep it natural
- Aim for ~150 words/minute pace
- Pause briefly between scenes
- Record the full voiceover in one take, then sync to video in editing

---

## 6. Post-Production

- **Tool:** CapCut (free), DaVinci Resolve (free), or Premiere Pro
- **Zoom:** Add subtle zoom (120–150%) on key interactions (word sync, voice feedback)
- **Overlays:** Add on-screen text at timestamps noted in DEMO_VIDEO_SCRIPT.md
- **Transitions:** Simple cuts or fade-to-black between scenes (no fancy transitions)
- **Export:** 1080p, H.264, AAC audio, MP4 container
