# HafizApp - Feature Analysis & Enhancement Plan

## 📱 App Overview
**HafizApp** is currently a clean, focused application for reading the Quran. It features a modern tech stack (Flutter, Bloc, Hive, Firebase) and a streamlined UI (Onboarding -> Home -> Surah Reading).

## 🚀 Recommended New Features
To evolve from a "Reader" to a true "Hafiz" (Memorization) utility, we recommend the following enhancements:

### 1. 🎧 Audio Recitations (Vital for Memorization)
*   **Feature:** Integrated audio player for Surahs/Ayahs.
*   **Details:**
    *   Support for multiple famous reciters (Mishary, Sudais, etc.).
    *   **Ayah-by-Ayah playback** with auto-repeat (Looping) for memorization.
    *   Highlighting the current Ayah during playback.
*   **Tech:** `just_audio` or `audioplayers` package + background service.

### 2. 🧠 Hifz (Memorization) Mode
*   **Feature:** Tools specifically designed to test and aid memory.
*   **Details:**
    *   **"Hide/Blur" Mode:** Toggle visibility of verses to test recall.
    *   **Mistake Log:** Tap words to mark mistakes and track trouble spots.
    *   **Revision Schedule:** Spaced Repetition System (SRS) to remind users when to review specific Surahs.

### 3. 🔍 Smart Search & Bookmarks
*   **Feature:** Comprehensive navigation tools.
*   **Details:**
    *   **Text Search:** Search by Arabic text or translation/transliteration.
    *   **Topic Search:** Find verses about specific topics (e.g., "Patience", "Prayer").
    *   **Advanced Bookmarks:** Multiple customized bookmarks (e.g., "Morning Revision", "Friday Kahf").

### 4. 📚 Tafseer & Translations
*   **Feature:** Deeper understanding of the text.
*   **Details:**
    *   Contextual Tap: Tap an Ayah to see Tafseer (Ibn Kathir, Jalalayn) and translations.
    *   Side-by-side or bottom-sheet view for translations.

### 5. 📊 Progress Tracking
*   **Feature:** Visualizing the user's journey.
*   **Details:**
    *   **Streak Counter:** Daily usage streak.
    *   **Hifz Tracker:** Visual progress bar for each Juz/Surah (e.g., "70% Memorized").

## 🛠️ Technical & UX Enhancements

### 1. ⚡ Performance & Offline First
*   **Current:** Uses Hive for caching.
*   **Enhancement:** Ensure **Full Offline Mode**. Pre-download the entire text database so the app works 100% without internet after first launch. (Currently relies on `surahRemoteDataSource`).

### 2. 🎨 UI/UX Polish
*   **Mushaf Mode:** Option to view as standard "Madani Script" pages (15-line) rather than a continuously scrolling list. This is often preferred by Huffaz for visual memory.
*   **Customization:** Font size sliders, massive variety of Arabic fonts (IndoPak, Uthmani, Kufic).

### 3. ☁️ Cloud Sync (Firebase)
*   Sync bookmarks and progress across devices (e.g., Phone and Tablet).

## 📋 Implementation Roadmap (Draft)

### Phase 1: Reading Experience (Current + Polish)
- [ ] Add Bookmark capability.
- [ ] Add Search capability.

### Phase 2: Audio & Immersion
- [ ] Implement Audio Player with Ayah highlighting.
- [ ] Add "Repeat Ayah" logic.

### Phase 3: The "Hafiz" Update
- [ ] Build Spaced Repetition logic.
- [ ] Add Progress Dashboard.
