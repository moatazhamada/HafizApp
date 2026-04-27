# Research: Critical Blockers & App Store Rejection Fixes

**Branch**: `002-critical-blockers-fix` | **Date**: 2026-04-28

## STORE-01: Debug Signing Fallback

**File**: `android/app/build.gradle.kts` lines 83-88

**Current behavior**: The `release` build type checks if signing config fields are non-null. If any is null, it falls back to `signingConfigs.getByName("debug")` — silently using debug keys in production.

**Fix**: Remove the `else` branch. If signing config is incomplete, the build must fail rather than use debug keys.

**Risk**: Low. Developers without keystore configured will get a clear build error instead of a silently-insecure APK.

## STORE-02/03: R8 Minification + ProGuard Rules

**File**: `android/app/build.gradle.kts` (release buildType), `android/app/proguard-rules.pro`

**Current behavior**: No `isMinifyEnabled` or `isShrinkResources` in the release build type. `proguard-rules.pro` is empty.

**Libraries needing ProGuard keep rules** (identified from pubspec.yaml):
- `hive` / `hive_flutter` — Uses reflection for `@HiveType` adapters. Generated `.g.dart` files must be preserved.
- `just_audio` — Uses method channels, generally safe with R8 but audio service classes should be kept.
- `flutter_sound` — Uses platform channels and native audio APIs.
- `flutter_appauth` — Uses OAuth2 redirect URLs and custom scheme handling.
- `flutter_bloc` / `hydrated_bloc` — BLoC classes and state serializers.
- `dio` — Interceptors and transformers use reflection.

**Fix**: Add `isMinifyEnabled = true` and `isShrinkResources = true` to the release build type. Write comprehensive ProGuard keep rules.

## STORE-04: iOS Firebase Bundle ID Mismatch

**File**: `lib/firebase_options.dart` lines 70, 79

**Current**: `iosBundleId: 'com.learn.flutter.learningFlutter'` (iOS) and `iosBundleId: 'com.learn.flutter.learningFlutter.RunnerTests'` (macOS).

**Expected**: `com.hafiz.app.hafizapp` to match the Android `applicationId = "com.hafiz.app.hafiz_app"` and the iOS project's actual bundle identifier.

**Note**: The Android `applicationId` uses underscores (`hafiz_app`) while the iOS bundle ID may use dots or hyphens. Need to verify the actual iOS bundle ID from `project.pbxproj` before fixing. The fix should make `firebase_options.dart` consistent with the actual iOS bundle ID.

**Recommended approach**: Re-run `flutterfire configure` to regenerate the file with correct bundle IDs, OR manually update the `iosBundleId` values.

## TECH-01: NoInternetException Shows UI SnackBar

**File**: `lib/core/errors/exceptions.dart` lines 1-19

**Current imports**: `package:flutter/material.dart` and `package:hafiz_app/main.dart`

**Current behavior**: Constructor directly calls `globalMessengerKey.currentState!.showSnackBar(...)` — a data-layer exception showing UI.

**Fix**: Remove both imports. Remove SnackBar logic from constructor. Keep only `_message` field and `toString()`. The constructor becomes a simple assignment: `NoInternetException([String message = 'NoInternetException Occurred']) : _message = message;`

**Downstream impact**: `globalMessengerKey` in `main.dart` must be searched for other references. If only used by `NoInternetException`, it can be removed entirely. Any other code referencing it for SnackBar display needs to switch to `ScaffoldMessenger.of(context)`.

## TECH-10: Test Dependencies in Production

**File**: `pubspec.yaml` lines 57-58

**Packages to move to dev_dependencies**:
- `mocktail: ^1.0.2`
- `bloc_test: ^10.0.0`
- `pretty_dio_logger: ^1.4.0`
- `flutter_launcher_icons: ^0.14.4`

**Also**: Remove `multiDexEnabled = true` from build.gradle.kts and `androidx.multidex:multidex:2.0.1` dependency — not needed for minSdk 24+.

## UX-02: Verse Study Retry Bug

**File**: `lib/presentation/verse_study/verse_study_screen.dart` line ~61

**Bug**: `LoadVerseStudy(context.read<VerseStudyBloc>().state.toString())` — passes `state.toString()` (e.g., "VerseStudyError(message: ...)") instead of the actual verse key.

**Root cause**: `VerseStudyState` doesn't carry the `verseKey` field, so the screen can't extract it from the state.

**Fix chain**:
1. Add `verseKey` field to `VerseStudyState` base class
2. Pass `verseKey` through `VerseStudyLoading`, `VerseStudyError`, `VerseStudyLoaded`
3. In screen, use `state.verseKey` for retry instead of `state.toString()`

**Bonus**: Disable retry button while loading to prevent duplicate calls.
