# Feature Specification: Technical Debt Remediation & Performance Optimization

**Feature Branch**: `005-technical-debt-remediation`
**Created**: 2026-04-28
**Status**: Draft
**Input**: Audit report Pillar 3 (H5-H8, TECH-02 through TECH-09) + Pillar 4 Polishing items (P3-P15)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - iOS App Meets Store Submission Requirements (Priority: P1)

As a developer submitting the app to the iOS App Store, the app supports background audio playback (via `UIBackgroundModes: audio`), has proper keychain entitlements for OAuth2 token storage, targets the correct minimum iOS version (15.0+), and presents a branded launch screen instead of the default Flutter placeholder.

**Why this priority**: iOS submission requires `UIBackgroundModes: audio` for background playback (STORE-05), keychain entitlements for secure token storage (STORE-06), minimum iOS 15.0 to match CocoaPods requirements (STORE-07), and a non-default launch screen (STORE-08). Without these, the iOS build is not submittable.

**Independent Test**: Build the iOS app, verify `Info.plist` contains `UIBackgroundModes: audio`, confirm the `.entitlements` file exists with keychain access groups, check `project.pbxproj` has `IPHONEOS_DEPLOYMENT_TARGET = 15.0`, and launch the app to see a branded storyboard instead of the Flutter default.

**Acceptance Scenarios**:

1. **Given** the iOS app is built with audio playback active, **When** the user locks the screen or switches apps, **Then** Quran audio continues playing in the background.
2. **Given** the iOS app launches, **When** the splash screen appears, **Then** a branded launch screen with the app logo and name is displayed (not the default Flutter placeholder).
3. **Given** the iOS project configuration, **When** `pod install` runs, **Then** no deployment target warnings appear (minimum iOS 15.0 consistent across all targets).
4. **Given** the user authenticates via QF OAuth2 on iOS, **When** the app stores tokens, **Then** tokens are saved in the iOS keychain via the `.entitlements` file.

---

### User Story 2 - App Launches Reliably Without Race Conditions (Priority: P2)

As a user opening the app, it launches reliably every time — no crashes from uninitialized preferences, no crashes from disposed audio handlers, and no auth interceptor conflicts causing API failures. The app handles edge cases like rapid reopens, background/foreground transitions, and token expiry gracefully.

**Why this priority**: PrefUtils race condition (TECH-02) and AudioPlayerHandler disposal (TECH-03) are high-severity stability issues that can cause crashes. Competing auth interceptors (TECH-04) can cause silent API failures. These directly impact the "Technical Execution" judging score.

**Independent Test**: Cold launch the app 10 times rapidly. Background and foreground the app while audio is playing. Let a QF token expire and trigger a refresh while multiple API calls are in flight. Verify zero crashes and zero failed API calls due to infrastructure issues.

**Acceptance Scenarios**:

1. **Given** the app cold-starts, **When** `PrefUtils` is initialized, **Then** all preference reads wait for `SharedPreferences` to be fully initialized before returning values — no null pointer crashes.
2. **Given** audio playback is active and the app is backgrounded/foregrounded, **When** the audio handler is accessed, **Then** it works correctly even after lifecycle transitions (no `StateError` from disposed stream controllers).
3. **Given** the user is authenticated, **When** multiple QF API requests are made simultaneously, **Then** each request receives only the appropriate auth header (Bearer for content API, x-auth-token for user API) — no conflicting double-auth headers.
4. **Given** a QF access token has expired, **When** multiple API calls hit 401 simultaneously, **Then** the token is refreshed once and all pending requests are retried with the new token — no requests are silently dropped.

---

### User Story 3 - Core Operations Run Without Noticeable Lag (Priority: P3)

As a user performing daily operations — searching for verses, studying a verse with Arabic/translation/tafsir, and checking my khatmah streak — all operations complete quickly without perceptible delays. Search results appear in under 1 second, verse study loads all three data sources simultaneously, and the streak calculation doesn't cause dashboard jank.

**Why this priority**: Performance bottlenecks (TECH-07, TECH-08, TECH-09) affect daily usage. Search loads 114 JSON files per query, VerseStudy makes 3 sequential API calls, and khatmah streak does 365 individual database reads. These create noticeable lag.

**Independent Test**: Search for "mercy" and measure response time (< 1 second for cached, < 2 seconds for first query). Open Verse Study for any verse and verify Arabic, translation, and tafsir load simultaneously (not sequentially). Open the khatmah dashboard and verify the streak calculation completes in under 100ms.

**Acceptance Scenarios**:

1. **Given** the user performs a search query, **When** results are displayed, **Then** cached searches return in under 500ms and first-time searches in under 2 seconds (previously unbounded due to 114 file loads).
2. **Given** the user opens Verse Study for a verse, **When** the data loads, **Then** Arabic text, translation, and tafsir are fetched concurrently (parallelized), reducing total latency by approximately 66%.
3. **Given** the user opens the khatmah dashboard, **When** the current streak is calculated, **Then** the computation reads a date range in a single batch operation (not 365 individual reads) and completes in under 100ms.
4. **Given** multiple sequential searches are performed, **When** the second search uses previously loaded data, **Then** the cached JSON data is reused without reloading from disk.

---

### User Story 4 - Build Configuration Is Clean and Optimized (Priority: P3)

As a developer building the app, the build configuration is clean — no unnecessary multi-dex support (minSdk 24 makes it redundant), native libraries are not extracted at runtime (reducing APK size), the pubspec description accurately describes the app, and dead code (sleep timer variables, duplicated musali slides) is removed.

**Why this priority**: These are low-effort polishing items (P8, P13, P14, P15) that reduce APK size, improve code clarity, and demonstrate attention to detail for hackathon judges.

**Independent Test**: Build a release APK and verify it doesn't include multi-dex support or native library extraction. Check the APK size is smaller than the current build. Verify no dead code warnings from static analysis.

**Acceptance Scenarios**:

1. **Given** the Android build configuration, **When** the release APK is built, **Then** multi-dex is not enabled (removed as unnecessary for minSdk 24).
2. **Given** the Android manifest, **When** `extractNativeLibs` is set to `false`, **Then** the APK size is reduced compared to the previous build.
3. **Given** `pubspec.yaml`, **When** reviewed, **Then** the description reads a meaningful app description instead of "A new Flutter project."
4. **Given** the musali/onboarding screen code, **When** reviewed, **Then** there are no duplicated slide data structures.

---

### Edge Cases

- What happens if `SharedPreferences` initialization takes longer than expected (e.g., first launch on slow device)? → PrefUtils must block callers until initialization completes, or provide a synchronous default.
- What happens if the audio handler is accessed from an isolate? → AudioHandler should remain on the main isolate; document this constraint.
- What happens if both auth interceptors match the same URL pattern? → The interceptors must be mutually exclusive per endpoint path (content vs. user API paths).
- What happens if the search cache grows too large (many different queries)? → Implement an LRU cache with a reasonable limit (e.g., 50 cached queries).
- What happens if khatmah log data spans more than 365 days? → Read all available data in a single batch operation regardless of date range.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The iOS app MUST declare `UIBackgroundModes: audio` in `Info.plist` to support background audio playback. (H5 / STORE-05)
- **FR-002**: The iOS app MUST include a `.entitlements` file with keychain access groups for secure OAuth2 token storage. (H5 / STORE-06)
- **FR-003**: The iOS deployment target MUST be set to 15.0 across all targets (project and pods). (H5 / STORE-07)
- **FR-004**: The iOS launch screen MUST display a branded storyboard (app logo and name) instead of the default Flutter placeholder. (STORE-08)
- **FR-005**: `PrefUtils` MUST await `SharedPreferences` initialization before any read/write operations are allowed, preventing null pointer crashes. (H6 / TECH-02)
- **FR-006**: `AudioPlayerHandler` MUST handle disposal gracefully — either via a `_isDisposed` guard preventing post-disposal access, or by using dependency-injected lifecycle management instead of a singleton. (H7 / TECH-03)
- **FR-007**: QF API interceptors MUST be mutually exclusive — content API requests receive only Bearer token headers, and user API requests receive only x-auth-token headers. (H8 / TECH-04)
- **FR-008**: The token refresh mechanism MUST implement request queuing so that simultaneous 401 responses trigger only one refresh, and all pending requests are retried after the refresh completes. (TECH-05)
- **FR-009**: The search worker MUST cache decoded surah JSON data across searches, invalidating only on locale change. (TECH-07 / P5)
- **FR-010**: Verse Study MUST fetch Arabic text, translation, and tafsir concurrently (parallelized) instead of sequentially. (TECH-08 / P3)
- **FR-011**: Khatmah streak calculation MUST read a date range in a single batch operation instead of 365 individual database reads. (TECH-09 / P4)
- **FR-012**: Android build MUST remove unnecessary multi-dex support (not needed for minSdk 24). (P13)
- **FR-013**: Android build MUST set `extractNativeLibs` to `false` to reduce APK size. (P14)
- **FR-014**: `pubspec.yaml` description MUST be updated to accurately describe the HafizApp. (P15)
- **FR-015**: Duplicated musali/onboarding slide data MUST be removed. (P8)

### Key Entities

- **PrefUtils**: Preferences utility with guaranteed-async initialization and safe access pattern
- **AudioPlayerHandler**: Audio playback controller with proper lifecycle management (initialization, active, disposed states)
- **AuthInterceptorPair**: Two interceptors with mutually exclusive URL matching rules for content vs. user API endpoints
- **SearchCache**: In-memory cache of decoded surah JSON data with LRU eviction policy
- **BatchDataReader**: Khatmah log reader that queries a date range in one operation instead of per-day reads

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: iOS app plays audio in the background for at least 30 minutes without interruption when the screen is locked.
- **SC-002**: App cold-starts 10 consecutive times with zero crashes related to preferences or audio handler initialization.
- **SC-003**: QF API requests never contain conflicting double-auth headers (verified via network logging).
- **SC-004**: Token refresh handles 5+ simultaneous 401 responses by queuing requests and retrying all after a single refresh.
- **SC-005**: Cached search queries return results in under 500ms (vs. previous unbounded time loading 114 JSON files).
- **SC-006**: Verse Study loads all three data sources (Arabic, translation, tafsir) in the time it takes the slowest single request (vs. 3x sequential latency).
- **SC-007**: Khatmah streak calculation completes in under 100ms regardless of streak length (vs. previous 365 individual reads).
- **SC-008**: Release APK size is reduced by removing multi-dex and disabling native library extraction.

## Assumptions

- iOS keychain entitlements require an Apple Developer provisioning profile with keychain access groups configured.
- The branded iOS launch screen uses a simple storyboard with the existing app logo asset (no new graphic design required).
- The existing `just_audio` package already supports background audio on iOS when `UIBackgroundModes` is declared — no additional code changes needed for background playback.
- `SharedPreferences.getInstance()` is an async operation that completes quickly on modern devices (< 50ms), so awaiting it in `PrefUtils.init()` won't cause noticeable startup delay.
- Separating the Dio instances (content vs. user) or making interceptors mutually exclusive by endpoint pattern are both viable approaches — the plan phase will determine the best option.
- The surah JSON files are static content that doesn't change between searches, making caching safe with locale-based invalidation only.
