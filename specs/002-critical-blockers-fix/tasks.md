# Tasks: Critical Blockers & App Store Rejection Fixes

**Input**: Design documents from `/specs/002-critical-blockers-fix/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [ ] T001 Verify current branch is `002-critical-blockers-fix` and working tree is clean
- [ ] T002 Run `flutter analyze` to establish baseline — document any pre-existing warnings

---

## Phase 2: User Story 1 — Release Build Produces Valid Store Artifact (Priority: P1) 🎯 MVP

**Goal**: Android release builds use proper signing (no debug fallback), R8 minification is enabled, ProGuard rules preserve required classes, iOS Firebase bundle IDs are correct.

**Independent Test**: `flutter build apk --release` produces a properly signed, minified APK; `firebase_options.dart` has matching bundle IDs.

### Implementation for User Story 1

- [ ] T003 [US1] Fix signing fallback in `android/app/build.gradle.kts` — remove the `else { signingConfig = signingConfigs.getByName("debug") }` branch in the `release` build type. If signing config is incomplete, the build must fail instead of silently falling back.
- [ ] T004 [US1] Enable R8 minification in `android/app/build.gradle.kts` — add `isMinifyEnabled = true` and `isShrinkResources = true` to the `release` build type block. Add `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`.
- [ ] T005 [P] [US1] Write ProGuard keep rules in `android/app/proguard-rules.pro` — add rules for Hive adapters (`-keep class * extends com.google.gson.TypeAdapter`), just_audio, flutter_sound, flutter_appauth, flutter_bloc, dio interceptors. Keep rules for all model classes with `@HiveType` annotations.
- [ ] T006 [P] [US1] Fix iOS Firebase bundle ID in `lib/firebase_options.dart` — change `iosBundleId: 'com.learn.flutter.learningFlutter'` to `iosBundleId: 'com.hafiz.app.hafizapp'` and `iosBundleId: 'com.learn.flutter.learningFlutter.RunnerTests'` to `iosBundleId: 'com.hafiz.app.hafizapp.RunnerTests'` in the `ios` and `macos` FirebaseOptions.
- [ ] T007 [US1] Remove unnecessary multiDex from `android/app/build.gradle.kts` — remove `multiDexEnabled = true` from `defaultConfig` and remove `implementation("androidx.multidex:multidex:2.0.1")` from dependencies (not needed for minSdk 24+).

**Checkpoint**: Run `cd android && ./gradlew :app:assembleProductionRelease --dry-run` to verify Gradle config is valid. Verify `proguard-rules.pro` is not empty.

---

## Phase 3: User Story 3 — NoInternetException Does Not Manipulate UI (Priority: P2)

**Goal**: `NoInternetException` is a pure data-layer exception with no UI imports or SnackBar logic.

**Independent Test**: `grep -r "import.*material" lib/core/errors/exceptions.dart` returns nothing. App handles network errors via BLoC states.

### Implementation for User Story 3

- [ ] T008 [US3] Refactor `NoInternetException` in `lib/core/errors/exceptions.dart` — remove `import 'package:flutter/material.dart'` and `import 'package:hafiz_app/main.dart'`. Remove the SnackBar logic from the constructor. Keep only `_message` field and `toString()` override. Constructor becomes: `NoInternetException([String message = 'NoInternetException Occurred']) : _message = message;`
- [ ] T009 [P] [US3] Remove `globalMessengerKey` from `lib/main.dart` — delete the `final globalMessengerKey = GlobalKey<ScaffoldMessengerState>()` declaration. Search entire codebase with `grep -r "globalMessengerKey" lib/` and remove/update all references. Remove `scaffoldMessengerKey: globalMessengerKey` from `MaterialApp` if present.

**Checkpoint**: Run `flutter analyze lib/core/errors/exceptions.dart lib/main.dart` — must show zero warnings. Run `grep -r "globalMessengerKey" lib/` — must return no results.

---

## Phase 4: User Story 2 — Verse Study Retry Works Correctly (Priority: P2)

**Goal**: The retry button passes the actual verse key, not `state.toString()`.

**Independent Test**: Open Verse Study for verse "2:255", simulate failure, tap retry, verify correct API call.

### Implementation for User Story 2

- [ ] T010 [US2] Add `verseKey` field to `VerseStudyState` base class in `lib/presentation/verse_study/bloc/verse_study_state.dart` — add `final String? verseKey` field (nullable for initial state). Override `props` to include it. Pass `verseKey` through `VerseStudyLoading`, `VerseStudyError`, and `VerseStudyLoaded` constructors.
- [ ] T011 [US2] Update `VerseStudyBloc` in `lib/presentation/verse_study/bloc/verse_study_bloc.dart` — in `_onLoadVerseStudy`, emit states that carry `verseKey: event.verseKey` (e.g., `VerseStudyLoading(verseKey: event.verseKey)`, `VerseStudyError(message: e.toString(), verseKey: event.verseKey)`).
- [ ] T012 [US2] Fix retry button in `lib/presentation/verse_study/verse_study_screen.dart` — replace `LoadVerseStudy(context.read<VerseStudyBloc>().state.toString())` with `LoadVerseStudy(state.verseKey!)`. Wrap the `FilledButton.icon` in a conditional to disable when state is `VerseStudyLoading`.

**Checkpoint**: Navigate to Verse Study for any verse. Enable airplane mode. Verify error state shows. Tap retry. Disable airplane mode. Verify verse data loads correctly.

---

## Phase 5: User Story 4 — Production Binary Excludes Test Dependencies (Priority: P3)

**Goal**: `mocktail`, `bloc_test`, `pretty_dio_logger`, and `flutter_launcher_icons` are under `dev_dependencies` only.

**Independent Test**: `grep -A5 "^dependencies:" pubspec.yaml` shows no test/dev packages.

### Implementation for User Story 4

- [ ] T013 [US4] Move dev-only packages from `dependencies` to `dev_dependencies` in `pubspec.yaml` — cut `mocktail: ^1.0.2`, `bloc_test: ^10.0.0`, `pretty_dio_logger: ^1.4.0`, and `flutter_launcher_icons: ^0.14.4` from the `dependencies` section and paste them under `dev_dependencies`. Remove the `#testing` comment.
- [ ] T014 [US4] Update `pubspec.yaml` description — change `"A new Flutter project."` to a meaningful description like `"A Quran memorization app with spaced repetition, voice verification, and Quran Foundation API integration."`.
- [ ] T015 [US4] Run `flutter pub get` and verify no dependency resolution errors.

**Checkpoint**: `grep -E "(mocktail|bloc_test|pretty_dio_logger|flutter_launcher_icons)" pubspec.yaml` should only match lines under `dev_dependencies`. `flutter pub get` succeeds.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate all user stories work together; ensure no regressions

- [ ] T016 Run `flutter analyze` across entire project — fix any warnings or errors introduced by the changes
- [ ] T017 [P] Fix any test failures (particularly any tests that reference `globalMessengerKey` or depend on `NoInternetException` showing a SnackBar)
- [ ] T018 [P] Review all changed files with `git diff` — verify no unintended changes, no leftover debug code
- [ ] T019 Commit all changes with a descriptive message and verify `flutter analyze` passes clean

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **User Stories (Phases 2–5)**: All depend on Setup but are **fully independent of each other**
  - US1 touches: `build.gradle.kts`, `proguard-rules.pro`, `firebase_options.dart`
  - US2 touches: `verse_study_state.dart`, `verse_study_bloc.dart`, `verse_study_screen.dart`
  - US3 touches: `exceptions.dart`, `main.dart`
  - US4 touches: `pubspec.yaml`
  - No file overlap → all stories can run in parallel
- **Polish (Phase 6)**: Depends on all user stories being complete

### Within Each User Story

- US1: T003 → T004 (sequential, same file), T005 || T006 || T007 (parallel, different files)
- US2: T010 → T011 → T012 (sequential chain)
- US3: T008 || T009 (parallel, different files)
- US4: T013 → T014 → T015 (sequential)

### Recommended Execution Order

US1 (T003→T004→T005→T006→T007) → US3 (T008→T009) → US2 (T010→T011→T012) → US4 (T013→T014→T015) → Polish

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: User Story 1 (T003–T007)
3. **STOP and VALIDATE**: Build a release APK, verify signing + R8 + ProGuard
4. This alone unblocks App Store submission

### Incremental Delivery

1. Setup → Foundation ready
2. Add US1 → Valid release artifact (MVP!)
3. Add US3 → Clean architecture (no UI in exceptions)
4. Add US2 → Working retry for verse study
5. Add US4 → Lean production binary
6. Polish → All changes validated together

---

## Notes

- All 4 user stories touch completely independent files — zero merge conflicts possible
- US1 is the only true submission blocker; US2–US4 are quality/security fixes
- ProGuard rules (T005) may need iteration — if the release APK crashes on a specific flow, add targeted keep rules for that library
- `firebase_options.dart` fix (T006) may require re-running `flutterfire configure` if the Firebase project's iOS app is registered under a different bundle ID
- The `globalMessengerKey` removal (T009) must be searched project-wide — any widget that references it for SnackBar display needs to switch to `ScaffoldMessenger.of(context)`
