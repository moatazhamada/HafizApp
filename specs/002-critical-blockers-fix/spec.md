# Feature Specification: Critical Blockers & App Store Rejection Fixes

**Feature Branch**: `002-critical-blockers-fix`
**Created**: 2026-04-28
**Status**: Draft
**Input**: Audit report Pillar 3 (TECH-01, TECH-10, TECH-02 partial) + Pillar 4 Critical items (C1-C6)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Release Build Produces Valid Store Artifact (Priority: P1)

As a developer, when I build a release APK/IPA, the build must produce a properly signed, minified artifact that passes Google Play and App Store validation — no silent fallback to debug signing, no missing ProGuard rules causing runtime crashes, and no Firebase configuration mismatch on iOS.

**Why this priority**: Without a valid release artifact, the app cannot be submitted to any store. This is an absolute submission blocker affecting both Android and iOS.

**Independent Test**: Run `flutter build apk --release` and `flutter build ios --release` and verify: (a) the APK is signed with the release keystore, (b) R8 shrinking/minification is enabled, (c) ProGuard rules preserve required classes, (d) iOS Firebase bundle IDs match the app bundle identifier.

**Acceptance Scenarios**:

1. **Given** a release build is triggered on Android, **When** the signing config is incomplete or missing, **Then** the build fails with a clear error instead of silently falling back to debug signing.
2. **Given** a release APK is built, **When** analyzed via `apkanalyzer`, **Then** R8 shrinking and minification are confirmed active, and the APK size is at least 30% smaller than an unminified build.
3. **Given** ProGuard/R8 is enabled, **When** the app launches and exercises core flows (surah reading, bookmarks, audio playback, Hive database access), **Then** no ClassNotFoundException or NoSuchMethodException occurs.
4. **Given** the iOS Firebase configuration, **When** the app registers for push notifications or analytics, **Then** the bundle ID in `firebase_options.dart` matches `com.hafiz.app.hafizapp` for both Android and iOS targets.

---

### User Story 2 - Verse Study Retry Works Correctly (Priority: P2)

As a user studying a verse, when the initial API fetch fails and I tap the retry button, the app must re-request the correct verse data using the proper verse key — not a stringified state object.

**Why this priority**: A broken retry button means users are stuck on failed verse study with no recovery path. This is a visible, user-facing bug.

**Independent Test**: Open Verse Study for any verse, simulate a network failure, tap retry, and verify the API request contains the correct verse key parameter.

**Acceptance Scenarios**:

1. **Given** Verse Study fails to load verse data, **When** the user taps the retry button, **Then** the app sends a new API request with the correct verse key (e.g., "1:1"), not `state.toString()`.
2. **Given** Verse Study retry succeeds, **When** the verse data loads, **Then** Arabic text, translation, and tafsir are displayed correctly.

---

### User Story 3 - NoInternetException Does Not Manipulate UI (Priority: P2)

As a developer, when a network exception occurs in the data/core layer, the exception must propagate up to the presentation layer (BLoC/screen) without directly showing UI elements. The exception class must not hold any UI references.

**Why this priority**: Architecture violations where data-layer exceptions directly manipulate UI create maintenance debt, prevent proper testing, and risk null pointer crashes when no scaffold messenger is available.

**Independent Test**: Trigger a network failure (airplane mode), and verify that: (a) no SnackBar is shown by the exception itself, (b) the BLoC handles the error and emits the appropriate state, (c) the screen displays the error UI based on the BLoC state.

**Acceptance Scenarios**:

1. **Given** a network request fails with no connectivity, **When** `NoInternetException` is thrown, **Then** no SnackBar is shown directly by the exception class.
2. **Given** a network error occurs, **When** the exception reaches the BLoC, **Then** the BLoC emits an error state that the UI handles via its standard error widget.
3. **Given** `NoInternetException` class definition, **When** reviewing its imports, **Then** it does not import `main.dart` or any Flutter UI package.

---

### User Story 4 - Production Binary Excludes Test Dependencies (Priority: P3)

As a developer building a release artifact, the production binary must not include test libraries (mocktail, bloc_test) or development-only packages (pretty_dio_logger, flutter_launcher_icons). These belong in dev_dependencies.

**Why this priority**: Shipping test libraries in production increases binary size, poses a potential security concern (mock objects in release), and is an App Store review risk.

**Independent Test**: Build a release APK, inspect the Dart compilation units, and verify no references to `mocktail`, `bloc_test`, `pretty_dio_logger`, or `flutter_launcher_icons` exist in the release binary.

**Acceptance Scenarios**:

1. **Given** `pubspec.yaml` is updated, **When** `flutter pub get` runs, **Then** `mocktail`, `bloc_test`, `pretty_dio_logger`, and `flutter_launcher_icons` are listed under `dev_dependencies`.
2. **Given** a release build, **When** the Dart AOT compilation completes, **Then** tree-shaking removes all dev_dependency code from the binary.

---

### Edge Cases

- What happens when the Android signing keystore file is missing entirely? → Build must fail with a descriptive error, not fallback.
- What happens when ProGuard rules are applied but a third-party plugin uses reflection (e.g., Hive)? → ProGuard keep rules must preserve all Hive-generated adapters and model classes.
- What happens if the iOS Firebase `google-services.plist` has a different bundle ID than the one in `firebase_options.dart`? → Both must be regenerated together via `flutterfire configure`.
- What happens when Verse Study retry is tapped rapidly multiple times? → Debounce or disable the button during the retry request to prevent duplicate calls.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Android release builds MUST fail explicitly when the signing configuration is incomplete, removing the silent fallback to debug signing. (C1 / STORE-01)
- **FR-002**: Android release builds MUST enable R8 minification (`isMinifyEnabled = true`) and resource shrinking (`isShrinkResources = true`). (C2 / STORE-02)
- **FR-003**: ProGuard rules MUST preserve all classes required by Hive, just_audio, flutter_sound, flutter_appauth, and any other reflection-dependent dependencies. (C2 / STORE-03)
- **FR-004**: iOS Firebase bundle ID in `firebase_options.dart` MUST match `com.hafiz.app.hafizapp` for both iOS and Android platforms. (C3 / STORE-04)
- **FR-005**: `NoInternetException` MUST NOT import any Flutter UI packages or directly show SnackBars. Error display MUST be handled by the BLoC/presentation layer. (C4 / TECH-01)
- **FR-006**: Test libraries (`mocktail`, `bloc_test`) and dev-only packages (`pretty_dio_logger`, `flutter_launcher_icons`) MUST be declared under `dev_dependencies` in `pubspec.yaml`. (C5 / TECH-10)
- **FR-007**: Verse Study retry MUST pass the actual verse key parameter to the API, not `state.toString()`. (C6 / UX-02)

### Key Entities

- **BuildConfiguration**: Android signing config (keystore path, key alias, passwords), R8/ProGuard settings, iOS bundle identifiers and Firebase configuration
- **ExceptionHierarchy**: `NoInternetException` as a pure data-layer exception with message only, no UI coupling
- **VerseStudyState**: BLoC state containing the verse key as a typed field, separate from any string representation

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `flutter build apk --release` produces a signed APK that passes `apksigner verify` and is at least 30% smaller than the current unminified build.
- **SC-002**: The release APK runs without any ClassNotFoundException or crash on core user flows (surah reading, bookmarks, audio, Hive data access).
- **SC-003**: iOS and Android Firebase configurations report the same bundle identifier (`com.hafiz.app.hafizapp`).
- **SC-004**: No Flutter UI imports exist in `lib/core/errors/exceptions.dart`.
- **SC-005**: `pubspec.yaml` has zero test/dev-only packages under `dependencies` (all moved to `dev_dependencies`).
- **SC-006**: Verse Study retry button successfully re-fetches verse data in under 3 seconds on a stable connection.

## Assumptions

- The Android release keystore and credentials exist (or will be provided by the developer) — this spec addresses the build config, not keystore creation.
- iOS Firebase project can be reconfigured via `flutterfire configure` without data loss.
- Hive adapters are already annotated with `@HiveType` — ProGuard rules need to preserve the generated `.g.dart` adapter classes.
- The developer has access to the Firebase console for bundle ID verification.
- Existing error handling in BLoCs already catches `NoInternetException` and will display appropriate UI once the SnackBar is removed from the exception itself.
