# Spec: Audio Player Screen

## Status: PENDING REVIEW

## Branch strategy
- Create branch `feature/audio-player` from latest `master`
- Open PR targeting `master`

## Description
Add a full Quran audio recitation player that plays verse-by-verse with highlighting, sleep timer, loop mode, and speed control. Background playback via `audio_service` package.

## Dependencies to add
- `audio_service: ^0.18.15` (background audio)
- `just_audio` already exists in pubspec

## Files to create
1. `lib/core/audio/audio_player_handler.dart` — BaseAudioHandler implementation for background playback
2. `lib/presentation/audio_player/audio_player_screen.dart` — Full-screen audio player UI
3. `lib/presentation/widgets/inline_audio_player.dart` — Mini player widget for embedding in surah screen

## Files to modify
1. `lib/main.dart` — Initialize AudioService in BootstrapApp._init()
2. `lib/injection_container.dart` — Register AudioPlayerHandler
3. `lib/routes/app_routes.dart` — Add audio player route
4. `lib/localization/en_us/en_us_translations.dart` — Add audio player strings
5. `lib/localization/ar_eg/ar_eg_translations.dart` — Add Arabic translations
6. `android/app/build.gradle.kts` — Enable `isCoreLibraryDesugaringEnabled` and add `desugar_jdk_libs` dependency (required by flutter_local_notifications which audio_service depends on)
7. `lib/presentation/home_screen/home_screen.dart` — Add audio player to NavigationDrawer

## Acceptance criteria
- [ ] Play/pause/stop audio
- [ ] Verse-by-verse playback with highlighting
- [ ] Reciter selection
- [ ] Sleep timer (15, 30, 45, 60 min)
- [ ] Loop mode (current verse, range)
- [ ] Playback speed control (0.5x - 2.0x)
- [ ] Background playback on Android
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter build apk --debug --flavor production` — success

## Notes
- Audio streams from online URLs (no bundled audio)
- Falls back gracefully if AudioService init fails
- AudioService init must be wrapped in try-catch (non-critical)
