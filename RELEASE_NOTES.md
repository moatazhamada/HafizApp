# Hafiz App — What's New

## 2.0.0 (Build 3)

### New Features
- **Navigation Drawer** — Full side menu replacing the old popup menu, with access to all screens
- **Mushaf View** — 604-page horizontal RTL PageView with actual Quran verse text, jump-to-page dialog, and surah info overlay
- **Audio Player** — Verse-by-verse playback with configurable reciter, speed control (0.5x–2x), sleep timer, loop mode, and verse progress display
- **Auto-scroll** — Continuous scroll in surah view with configurable speed (0.25x–3.0x)
- **Verse Sharing** — Share or copy any verse with attribution via the system share sheet
- **Statistics Screen** — Reading progress overview with bookmark count, practice verse count, and real memorization data
- **Mushaf Type Onboarding** — First-run selector for Madani, Egyptian, Indo-Pak, or Warsh script
- **Settings Enhancements** — Quran font size slider, orientation lock (applies immediately), default Quran view, configurable reciter
- **Cloud Sync** — Firebase-based bookmark and settings synchronization

### RTL & Accessibility
- All Quran/Arabic text now renders with explicit RTL direction regardless of app language setting
- Surah navigation arrows follow RTL reading convention (left = forward, right = backward)
- Voice verification dialog text (spoken, expected, hints) properly renders RTL

### Settings Now Active
- **Default Quran View** — Home screen respects surah vs mushaf preference
- **Orientation Mode** — Controls device orientation, applies immediately without restart
- **Quran Font Size** — Live preview slider (16–40px)

### Onboarding Flow
- New flow: Splash → Onboarding → Mushaf Type Selection → Home
- Musali teaser removed from flow (deferred for redesign)

### Fixes
- Fixed build-breaking syntax error in preferences
- Corrected mushaf page-to-surah mapping data (114 surahs)
- Fixed app bar icon/title overlap by consolidating actions into overflow menu
- Resolved all analyzer warnings and deprecated API usage
- Fixed missing clipboard copy action in verse share sheet
- Theme changes now apply immediately across all screens (no restart needed)
- Audio player now uses the selected reciter from Settings
- Statistics screen shows actual memorization progress instead of hardcoded 0
- Removed hardcoded AppBar colors — theme now controls styling on all screens
- Removed dead "Reading Navigation Mode" setting that had no effect

---

## 1.1.0 (Build 2)

- Performance: Faster startup with a lightweight bootstrap splash while services init in the background.
- State persistence: Pages keep their state (lists remain mounted; scroll positions are restored across navigation and app restarts).
- Offline-friendly: Surah data is cached locally for instant loads and reading without a connection.
- UI improvements: Inline ayah numbers with a refined, theme-aware badge and clear spacing.
- Stability: Updated Kotlin/AGP/Gradle toolchain and fixed connectivity API changes.
- Polish: Resolved analyzer warnings and replaced deprecated APIs for smoother future upgrades.

If you experience any issues, please use in-app feedback or contact support.

