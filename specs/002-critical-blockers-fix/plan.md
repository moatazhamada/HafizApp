# Implementation Plan: Critical Blockers & App Store Rejection Fixes

**Branch**: `002-critical-blockers-fix` | **Date**: 2026-04-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-critical-blockers-fix/spec.md`

## Summary

Fix 6 critical/blocker items preventing App Store submission and causing user-facing bugs: remove debug signing fallback, enable R8 minification with ProGuard rules, fix iOS Firebase bundle ID mismatch, decouple NoInternetException from UI, move test deps to dev_dependencies, and fix Verse Study retry bug.

## Technical Context

**Language/Version**: Dart 3.9+ / Flutter (latest stable)
**Primary Dependencies**: flutter_bloc, dio, hive, just_audio, flutter_sound, flutter_appauth, firebase_core
**Storage**: Hive (local), SharedPreferences
**Testing**: flutter_test, mocktail, bloc_test
**Target Platform**: Android (minSdk 24, targetSdk via Flutter) + iOS (15.0+)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Release APK 30%+ smaller via R8 shrinking
**Constraints**: Must not break any existing functionality; all changes touch independent files
**Scale/Scope**: ~165 Dart files, ~19,900 lines

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| 1. Quranic Reverence | ✅ PASS | No changes to Quranic content display |
| 2. Clean Architecture | 🔧 FIXING | NoInternetException currently violates this (TECH-01) — this spec FIXES it |
| 3. Offline-First | ✅ PASS | No changes to offline behavior |
| 4. Accessibility | ✅ PASS | No touch target changes in this spec |
| 5. Performance | ✅ PASS | R8 minification improves performance |

**Gate Verdict**: One architecture violation detected (Principle 2) and this spec is fixing it. Proceeding.

## Project Structure

### Documentation (this feature)

```text
specs/002-critical-blockers-fix/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── tasks.md             # Phase 2 output (via /speckit.tasks)
└── checklists/
    └── requirements.md  # Quality validation
```

### Source Code (repository root)

```text
android/
├── app/
│   ├── build.gradle.kts          # STORE-01: Remove debug signing fallback; STORE-02: Enable R8
│   └── proguard-rules.pro        # STORE-03: Add keep rules for Hive, just_audio, flutter_sound, flutter_appauth
└── build.gradle.kts

ios/
├── Runner.xcodeproj/project.pbxproj  # Verify bundle ID
└── Runner/
    └── GoogleService-Info.plist       # Must match bundle ID

lib/
├── core/errors/
│   └── exceptions.dart               # TECH-01: Remove UI imports from NoInternetException
├── presentation/verse_study/
│   ├── bloc/
│   │   ├── verse_study_bloc.dart     # Already uses event.verseKey
│   │   ├── verse_study_event.dart
│   │   └── verse_study_state.dart    # Add verseKey field to states
│   └── verse_study_screen.dart       # UX-02: Fix retry to use verseKey
├── firebase_options.dart             # STORE-04: Fix iosBundleId
└── main.dart                         # Remove globalMessengerKey

pubspec.yaml                           # TECH-10: Move test deps to dev_dependencies
```

**Structure Decision**: Mobile app with per-feature BLoC modules. Changes span build configuration (Android/iOS), core error handling, presentation layer (Verse Study), and dependency management.

## Complexity Tracking

> No constitution violations requiring justification — the detected violation (Principle 2) is being fixed, not introduced.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
