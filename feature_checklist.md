# HafizApp Feature Checklist

Use this checklist to verify all implemented features before the V2 release.

## 1. General & Onboarding

- [x]  **Splash/Onboarding**:
    - [x]  App launches with an animation/fade-in.
    - [x]  Fix white screen flash before splash. 
    - [x]  "Get Started" button navigates to Home Screen.
    - [x]  Checks for internet connectivity (displays banner/warning if offline).
- [x]  **Localization**:
    - [x]  App supports English and Arabic.
    - [x]  Strings are localized correctly (no hardcoded English).
    - [x]  App Guide page has non-localized English words. 
    - [x]  RTL layout support for Arabic.
- [x]  **Theme**:
    - [x]  Supports Light Mode, Dark Mode, and System Default.
    - [x]  Fix inconsistent mode on first launch. 
    - [x]  Colors contrast is accessible in both modes.
- [x]  **Mushaf Type Onboarding**: First-run selector for Madani/Egyptian/Indo-Pak/Warsh script style

## 2. Home Screen

- [x]  **Navigation Drawer**:
    - [x]  Full side drawer with icons for all screens (replacing old popup menu).
    - [x]  Drawer items: Bookmarks, Practice Verses, Session History, Memorization, Khatmah, Statistics, Mushaf View, Settings, About.
    - [x]  **Theme Toggle**: Sun/Moon icon in app bar toggles the theme instantly.
    - [x]  **Search Icon**: Navigates to Search Screen.
    - [x]  Localize search and use clearer naming.
- [x]  **Last Read Card**:
    - [x]  Appears if a Surah has been visited.
    - [x]  Shows Surah Name (English/Arabic) and Verse Number.
    - [x]  Fix Last Read verse number visibility.
    - [x]  "Continue Reading" button navigates to the exact scroll position in the Surah.
    - [x]  Fix "Continue Reading" button navigation logic. 
    - [x]  Respects Default Quran View setting (navigates to Surah or Mushaf screen).
- [x]  **Surah List**:
    - [x]  Lists all 114 Surahs.
    - [x]  Shows English Name, Arabic Name, and Surah Number.
    - [x]  List items animate in (staggered fade/slide).
    - [x]  Tapping a Surah navigates to SurahScreen.

## 3. Surah Screen (Reading)

- [x]  **Display**:
    - [x]  Shows Surah Name in AppBar (RTL text direction).
    - [x]  Fix AppBar title overlap with icons — consolidated to overflow menu (⋮).
    - [x]  Displays Bismillah at the top (RTL text direction).
    - [x]  **View Mode**:
        - [x]  **Continuous**: Verses flow as a paragraph with end-of-verse badges (RTL).
        - [x]  **Single Line**: Verses are stacked vertically, one per row (RTL).
        - [x]  Mode respects the setting from Settings Screen.
- [x]  **AppBar Actions**:
    - [x]  **Headphones Icon**: Opens Audio Player for current surah.
    - [x]  **Auto-scroll**: Play/pause toggle, configurable speed (long-press for 0.25x–3.0x picker).
    - [x]  **Overflow Menu (⋮)**: Help, Hifz Mode toggle, Bookmark toggle.
- [x]  **Interaction**:
    - [x]  **Tap Verse**: Opens the Verse Action Menu (in Standard Mode).
    - [x]  **Long Press Verse**: Opens the Verse Action Menu (in Hifz Mode).
- [x]  **Verse Action Menu**:
    - [x]  **Bookmark**:
        - [x]  Add Bookmark: Icon changes, toast appears.
        - [x]  Localize bookmark toast messages.
        - [x]  Remove Bookmark: Icon changes, toast appears.
    - [x]  **Practice (Mistakes)**:
        - [x]  Mark for Practice: Adds to Recitation Error list, toast appears.
        - [x]  Localize practice toast messages.
        - [x]  Unmark: Removes from list.
    - [x]  **Share**: Share/copy verse text with attribution.
    - [x]  **Tafsir**: Bottom sheet with Ibn Kathir translation.
    - [x]  **Verify Recitation**: Opens the Voice Verification Dialog.
    - [x]  Fix partial recitation issues (e.g. Alif Lam Mim) and wrong recitation dialog actions.
- [x]  **Navigation**:
    - [x]  RTL-aware prev/next surah buttons at bottom.
    - [x]  Next surah = left arrow (◁), Previous surah = right arrow (▷).
- [x]  **RTL Text Direction**:
    - [x]  All verse text renders RTL regardless of app locale.
    - [x]  Surah names, bismillah, tafsir all use `textDirection: TextDirection.rtl`.

## 4. Memorization Tools (Hifz & Voice)

- [x]  **Hifz Mode (blur)**:
    - [x]  Click Eye Icon in AppBar.
    - [x]  **Behavior**: All verses are blurred/hidden.
    - [x]  **Reveal**: Tapping a blurred verse reveals it. Tapping again hides it.
- [ ]  **Voice Verification**:
    - [x]  **Mic Permission**: Requests permission on first use.
    - [x]  Fix permissions not auto-enabling feature upon acceptance. 
    - [ ]  **Dialog**:
        - [x]  Shows "Tap to Speak".
        - [x]  Enhance dialog localization.
        - [x]  Real-time feedback: Shows recognized text as you speak.
        - [x]  **Stop**: Manual stop or auto-silence detection (if implemented).
        - [x]  Improve detection logic and feedback messaging.
    - [ ]  **Verification Logic**:
        - [x]  **Correct**: Green feedback → Auto-navigates to the **Next Verse**. 
        - [x]  **Incorrect**: Red feedback → Shows "Wrong Recitation" dialog.
            - [x]  "Try Again": Re-opens mic dialog.
            - [x]  "Save for Practice": Adds verse to "Practice List" and moves to next verse.
            - [x]  Fix "Try Again" and "Save for Practice" actions in Wrong Recitation dialog. 

## 5. Search Screen

- [x]  **Search Input**:
    - [x]  Accepts English (e.g., "Fatihay") or Arabic (e.g., "الفاتحة").
- [ ]  **Results**:
    - [x]  **Surahs**: Lists matching Surah names.
    - [x]  **Verses**: Lists matching verses with text highlighting.
    - [x]  **Highlighting**: Matches are highlighted in a contrasting color/bold.
- [ ]  **Navigation**:
    - [x]  Tapping a result opens SurahScreen at the specific verse (scrolls to it).
    - [x]  Search scroll-to and highlight not working. 

## 6. User Data (Bookmarks & Practice)

- [x]  **Bookmarks Screen**:
    - [x]  Lists all saved bookmarks.
    - [x]  Tapping an item navigates to the Surah/Verse.
    - [x]  Bookmark navigation scroll/highlight not working. 
    - [x]  Swipe or Delete icon removes the bookmark.
    - [x]  Empty state shown if no bookmarks exist.
- [x]  **Practice List (Recitation Errors)**:
    - [x]  Lists all verses marked as mistakes.
    - [x]  Visual indicator (warning icon).
    - [x]  Tapping navigates to the verse for review.
    - [x]  Practice list navigation scroll/highlight not working. 
    - [x]  Swipe or Check icon removes the item (marks as mastered).
    - [x]  Empty state shown if no errors exist.

## 7. Settings & Information

- [x]  **Settings Screen**:
    - [x]  **Language**: Switch between English, Arabic, System Default.
    - [x]  **View Mode**: Toggle between Single Line and Continuous text.
    - [ ]  **Theme**: Switch between Light, Dark, System Default.
    - [x]  Fix System Default theme consistency issues. 
- [x]  **About Screen**:
    - [x]  Displays App Version.
    - [x]  Fix App Version not showing in About. 
    - [x]  Links to GitHub/Developer.
    - [x]  **Feedback**: Opens dialog to send feedback (Firestore).
    - [x]  **Integrity Note**: Disclaimer about Quran text sources.
- [x]  **Help Screen**:
    - [x]  Displays static guide for icons/features.
- [x]  **Settings Enhancements**:
    - [x]  **Quran Font Size**: Live preview slider (16–40px) with Bismillah sample.
    - [x]  **Orientation Mode**: System/Portrait/Landscape (wired to SystemChrome).
    - [x]  **Default Quran View**: Surah/Mushaf preference (wired to home screen navigation).
    - [x]  **Reading Navigation Mode**: Scroll/Page toggle (saved, not yet consumed by surah screen).
    - [x]  **Cloud Sync**: Firebase-based sync option.
    - [x]  **Recitation Coach**: Provider, Qiraat edition, Reciter, Whisper model settings.
- [x]  **Additional Screens**:
    - [x]  **Mushaf View**: 604-page horizontal RTL PageView, jump-to-page, surah info overlay.
    - [x]  **Audio Player**: Verse-by-verse playback, speed control, sleep timer, loop.
    - [x]  **Statistics**: Bookmark count, practice verse count, reading progress.
    - [x]  **Memorization Tracker**: Per-surah memorization status.
    - [x]  **Khatmah Tracker**: Daily reading goals and progress tracking.
    - [x]  **Session History**: Past recitation sessions log.