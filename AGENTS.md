# Hafiz — Quran Memorization Assistant

> **Project Type:** Flutter mobile/desktop/web application  
> **Language:** Dart  
> **Current Version:** 3.2.0+19  
> **Flutter SDK:** `>=3.9.0 <4.0.0`  
> **Repository Status:** Private

Hafiz is a non-profit Quran memorization assistant built with Flutter. It supports reading (Mushaf and verse-by-verse), memorization tracking with spaced-repetition scheduling, voice recitation verification using on-device Whisper models, and cloud sync through the Quran Foundation API.

Supported platforms: **Android**, **iOS**, **macOS**, **Linux**, **Windows**, and **Web**.

---

## Technology Stack

| Layer | Packages / Tools |
|-------|------------------|
| **Framework** | Flutter, Dart SDK >=3.9.0 |
| **State Management** | `flutter_bloc`, `hydrated_bloc`, `bloc_test` |
| **Dependency Injection** | `get_it` |
| **Functional Programming** | `dartz` (Either<Failure, Success>) |
| **Networking** | `dio`, `pretty_dio_logger` |
| **Local Persistence** | `hive`, `hive_flutter`, `shared_preferences` |
| **Remote Config / Analytics** | Firebase (Core, Crashlytics, Analytics, Remote Config) |
| **Auth** | `flutter_appauth` (OAuth2/OIDC with PKCE), `jwt_decoder` |
| **Audio** | `just_audio`, `flutter_sound`, `speech_to_text`, `whisper_ggml_plus` |
| **Notifications** | `flutter_local_notifications`, `home_widget` |
| **Image** | `cached_network_image`, `flutter_svg` |
| **Testing** | `flutter_test`, `mocktail`, `bloc_test`, `integration_test` |
| **CI / CD** | GitHub Actions + Fastlane (Ruby) |
| **Build Tools** | Gradle (Kotlin DSL), Java 21, Android NDK 29 |

---

## Project Structure

The codebase follows **Clean Architecture** with four distinct layers:

```
lib/
├── presentation/       # UI screens, BLoCs, widgets
├── domain/             # Entities, repository interfaces, use cases (pure Dart)
├── data/               # Data sources, models, repository implementations
├── core/               # Shared utilities, theme, network, config, errors
├── di/                 # Dependency injection registrations (GetIt)
├── routes/             # Named route definitions
├── theme/              # Theme BLoC (light / dark / system)
├── localization/       # Localization strings (en_us, ar_eg)
├── widgets/            # Reusable global widgets
├── main.dart           # App entry point
└── injection_container.dart   # GetIt initialization orchestrator
```

### Key Directories

- **`lib/core/`** — Network manager, API interceptors, auth utilities, theme constants, error definitions, Quran index data, audio services, notifications, analytics, platform utilities.
- **`lib/data/datasource/`** — One sub-directory per feature. Remote data sources use `dio`; local data sources use `hive` or `shared_preferences`.
- **`lib/data/repository/`** — Repository implementations that coordinate between remote and local data sources.
- **`lib/domain/`** — Entity definitions, repository contracts, and use case classes.
- **`lib/presentation/`** — One sub-directory per screen. Each screen usually contains its own `bloc/` folder with `*_bloc.dart`, `*_event.dart`, and `*_state.dart`.

### Route Definitions

All named routes are defined in `lib/routes/app_routes.dart`. Navigation is performed via `NavigatorService.pushNamed()` (see `lib/core/utils/navigator_service.dart`).

---

## Build and Run Commands

```bash
# Install dependencies
flutter pub get

# Run debug (production flavor)
flutter run --flavor production

# Run debug (prelive flavor)
flutter run --flavor prelive

# Run all unit/widget tests
flutter test

# Run integration tests
flutter test integration_test/

# Run static analysis
flutter analyze

# Build release APK
flutter build apk --release --flavor production

# Build Android App Bundle (AAB)
flutter build appbundle --release --flavor production
```

### Flavors

Two product flavors exist in `android/app/build.gradle.kts`:

| Flavor | Application ID | Redirect Scheme | Purpose |
|--------|---------------|-----------------|---------|
| `production` | `com.hafiz.app.hafiz_app` | `hafizapp` | Production release |
| `prelive` | `com.hafiz.app.hafiz_app.prelive` | `hafizapp-prelive` | Staging / prelive environment |

Dart defines are loaded from `.dart_defines.production.json` and `.dart_defines.prelive.json` respectively.

---

## Code Style Guidelines

Linting is configured in `analysis_options.yaml`. The project includes `package:flutter_lints/flutter.yaml` and enforces the following additional rules:

- `avoid_print: true` — Use the logger utility (`lib/core/utils/logger.dart`) instead of `print()`.
- `prefer_single_quotes: true` — All string literals must use single quotes.
- `prefer_const_constructors: true`
- `prefer_const_literals_to_create_immutables: true`
- `unawaited_futures: true`
- `cancel_subscriptions: true`
- `close_sinks: true`
- `always_declare_return_types: true`
- `annotate_overrides: true`
- `prefer_final_fields: true`

### Architecture Conventions

1. **Layer isolation** — Domain code must be pure Dart (no Flutter imports). Use cases expose a single `Future<Either<Failure, T>> call(P params)` method.
2. **Either<Failure, Success>** — Repositories always return `Either<Failure, T>`. BLoCs map `Left(Failure)` to error states and `Right(Data)` to success states.
3. **BLoC pattern** — Every major screen has its own BLoC. Events are named `*Event`, states are named `*State`. Use `BlocBuilder` / `BlocListener` in widgets.
4. **Dependency Injection** — Register shared dependencies as `registerLazySingleton` and per-screen BLoCs as `registerFactory` in the appropriate `di/di_*.dart` file.
5. **RTL Convention** — All Quran / Arabic text **must** use `textDirection: TextDirection.rtl` regardless of app locale. Surah navigation arrows follow RTL semantics (next = left, previous = right).
6. **Localization keys** — All user-facing strings use translation keys defined in `lib/localization/en_us/en_us_translations.dart` and `lib/localization/ar_eg/ar_eg_translations.dart`.

---

## Testing Instructions

### Unit & Widget Tests

Located in `test/`, mirroring the `lib/` structure.

- Use `mocktail` for mocking dependencies.
- Use `bloc_test` for testing BLoC state transitions.
- Fixtures (JSON test data) are loaded via `test/fixture/fixture_reader.dart`.

Example pattern:

```dart
class MockGetSurah extends Mock implements GetSurah {}

blocTest<SurahBloc, SurahState>(
  'emits [Loading, Success] when LoadSurahEvent is added',
  build: () => surahBloc,
  act: (bloc) => bloc.add(const LoadSurahEvent(surahId: '114')),
  expect: () => [isA<LoadingSurahState>(), isA<SuccessSurahState>()],
);
```

### Integration Tests

Located in `integration_test/`. Run with:

```bash
flutter test integration_test/
```

### Coverage

The CI pipeline runs tests with coverage and filters out generated files:

```bash
flutter test --coverage --reporter=expanded
lcov --remove coverage/lcov.info 'lib/**/*.g.dart' 'lib/**/*.freezed.dart' 'lib/**/generated/**' -o coverage/lcov_filtered.info
```

---

## Security Considerations

- **This is a private repository.**
- **Keystore:** `android/app/upload-keystore.jks` and `android/keystore.properties` are excluded from git via `.gitignore`.
- **Secrets:** Quran Foundation OAuth `client_id` and `client_secret` are injected at build time via `--dart-define-from-file` (`.dart_defines.production.json` / `.dart_defines.prelive.json`). In CI they are sourced from GitHub Secrets.
- **Token Storage:** Access tokens are stored in `flutter_secure_storage`. Token refresh is handled automatically by `QfApiInterceptor`.
- **PKCE:** OAuth2 login uses PKCE via `flutter_appauth`.
- **Confidential vs Public Client:** The app defaults to confidential-client mode (server-side token exchange). Only enable `forcePublicClient` if Quran Foundation explicitly confirms it.

### Required GitHub Secrets (CI/CD)

- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`
- `GOOGLE_PLAY_SERVICE_ACCOUNT`

---

## CI/CD & Deployment

GitHub Actions workflow: `.github/workflows/deploy.yml`

Jobs:
1. **test** — Runs on macOS. Executes `flutter test --coverage`, filters coverage, and runs `flutter analyze`.
2. **build-android** — Runs on Ubuntu. Builds release AAB after tests pass.
3. **deploy-internal** — Deploys to Google Play Internal Testing from `feature/sheikh-recitation-coach` branch via Fastlane.
4. **deploy-production** — Deploys to Google Play Production from version tags (`v*`) via Fastlane.

Fastlane configuration lives in `android/fastlane/`. The `Fastfile` reads the version from `pubspec.yaml` and uses dart-define JSON files for QF credentials.

---

## Key External Integrations

| Service | Purpose |
|---------|---------|
| **Quran Foundation APIs** | Content (v4), Auth (v1), Activity, Goals, Bookmarks, Posts, Search, Mushaf |
| **Firebase** | Crashlytics, Analytics, Remote Config |
| **Qurani.ai QRC** | Voice recitation verification and coaching |
| **QuranHub Qiraat API** | Qiraat (recitation styles) data |
| **Tanzil** | Verified Uthmani Quran text (bundled locally) |
| **Quran.com API v4** | Remote fallback for Quran metadata |

---

## Important Files for Agents

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies, version, assets, fonts |
| `analysis_options.yaml` | Lint rules |
| `lib/injection_container.dart` | GetIt DI root |
| `lib/core/app_export.dart` | Barrel file for commonly imported core utilities |
| `lib/core/errors/failures.dart` | Failure hierarchy (ServerFailure, ConnectionFailure, CacheFailure, InsufficientScopeFailure) |
| `lib/core/errors/exceptions.dart` | Exception hierarchy |
| `lib/routes/app_routes.dart` | All named routes |
| `lib/core/config/qf_api_config.dart` | Quran Foundation API base URLs and client credentials |
| `lib/core/network/network_manager.dart` | Dio configuration |
| `.dart_defines.production.json` / `.dart_defines.prelive.json` | Build-time environment variables |
| `.github/workflows/deploy.yml` | CI/CD pipeline |
| `android/fastlane/Fastfile` | Deployment lanes |
| `ARCHITECTURE.md` | Detailed architecture documentation |
| `README.md` / `README.ar.md` | Human-readable project documentation |
| `SECURITY.md` | Security and keystore handling guidelines |
