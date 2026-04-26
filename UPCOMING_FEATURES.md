# HafizApp — Upcoming Features & Enhancements

A living document of planned features, enhancements, and improvements for future releases.

## 🎯 High Priority

### Onboarding Flow for New Users
A guided walkthrough explaining key features (Hifz mode, voice verification, audio player, mushaf view). Shown on first launch with skip option.
- Interactive tutorial cards
- Feature discovery tooltips
- Skip / "Don't show again" preference

### Audio Reciter Download for Offline Playback
Currently audio streams from CDN. Allow users to download reciter audio for offline use.
- Per-surah or full-mushaf download
- Download manager with progress
- Storage usage indicator
- Auto-cleanup of cached audio

### Bookmark Categories / Folders
Organize bookmarks into named collections (e.g., "Review", "Juz 30", "Daily Reading").
- Create / rename / delete folders
- Drag-and-drop reordering
- Bulk move between folders

### Search Within a Specific Surah
Filter search results to a single surah for targeted verse lookup.
- Surah picker in search bar
- "Search in this surah" from surah screen overflow menu

## 🔧 Medium Priority

### Haptic Feedback on Verse Interactions
Add subtle haptic feedback when toggling Hifz blur, bookmarking, and completing voice verification.

### Home Screen Widget (Last Read)
A native homescreen widget showing last read surah/verse with a tap-to-continue action.
- Android: `GlanceWidget` or `HomeWidget`
- iOS: `WidgetKit`

### Configurable Recitation Pass Threshold
Let users adjust the voice verification pass threshold (currently hardcoded at 85%) and minimum word count (currently 3) from Settings.

### QRC Voice Verification — Session Progress
When using QRC provider for multi-verse recitation, show verse progress (e.g., "Verse 3 of 12") and a mini progress bar.

### Whisper Model Management
Allow downloading/removing Whisper models from within the app instead of bundling them.
- Model size indicator
- Download progress
- Auto-select based on available storage

### Dark Theme Color Customization
Allow users to choose accent colors for the dark theme beyond the default teal.

### Tajweed Rules Reference
Add a tajweed rules reference screen accessible from voice verification feedback.
- Visual examples of tajweed rules
- Linked from QRC mistake feedback
- Available offline

## 💡 Low Priority / Nice-to-Have

### Spaced Repetition for Memorization
Enhance the memorization tracker with an SM-2 (or similar) spaced repetition algorithm to optimize review scheduling.

### Khatmah Goals — QF Activity API Integration
Wire local khatmah goals/streaks to the Quran Foundation Activity & Goals API for cross-device sync.

### Community Recitation Leaderboard
Opt-in leaderboard showing weekly memorization progress among app users.

### Import/Export User Data
Allow users to export bookmarks, practice lists, memorization progress, and settings to a JSON file, and import on another device.

### Multi-Profile Support
Support multiple user profiles on a single device (useful for families sharing a tablet).

### Auto-Scroll Speed Per-Surah Memory
Remember the last used auto-scroll speed per surah instead of a global default.

### Verse Annotation / Notes
Allow users to attach personal notes or reflections to individual verses.

### Audio Player — Playlist Mode
Queue multiple surahs for continuous playback with auto-advance.

### Full-Text Search with Arabic Diacritics Tolerance
Enhance search to match Arabic text regardless of diacritics presence/absence.

---

*Last updated: April 2026*
