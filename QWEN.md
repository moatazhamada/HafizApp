# QWEN.md — HafizApp Project Context

## Project Overview

**HafizApp** is a Flutter-based Quran memorization assistant (v3.1.0+15). It provides mushaf reading, audio recitation, voice verification, tafsir, bookmarking, memorization tracking, khatmah (reading goals), and cloud sync via Quran Foundation APIs.

- **Package:** `com.hafiz.app.hafiz_app`
- **Flutter SDK:** >=3.9.0 <4.0.0
- **Dart:** null-safe, JDK 21
- **Platforms:** Android (primary), iOS, with stubs for web/desktop
- **Distribution:** Google Play Store (non-profit, open-source intent)
- **Original source:** https://github.com/abualgait/HafizApp

## Architecture

**Clean Architecture** with three layers under `lib/`:

```
lib/
├── core/           # Shared utilities, errors, network, analytics, audio, theme
├── data/           # Data sources (remote/local), models, repository implementations
├── domain/         # Entities, abstract repository interfaces, use cases
├── presentation/   # Screen widgets + BLoC (Event/State) per feature
├── routes/         # Named route table (AppRoutes)
├── localization/   # en_US, ar_EG translation maps (.tr extension)
├── theme/          # ThemeBloc (HydratedBloc for persistence)
├── widgets/        # Shared UI components
├── injection_container.dart  # GetIt service locator (sl<Type>())
├── main.dart       # Bootstrap: Hive → DI → Firebase → HydratedBloc → runApp
└── firebase_options.dart
```

### Data Flow

```
UI → dispatches Event → BLoC → UseCase → Repository (abstract) → DataSource
                                    ← Either<Failure, Data> ←
```

- `dartz` package provides `Either<Failure, T>` for error handling
- Domain layer has zero Flutter dependencies

### Dependency Injection

GetIt service locator in `injection_container.dart`:
- `sl()` for resolution (e.g., `sl<SurahBloc>()`)
- BLoCs: `Factory` (new per use) or `LazySingleton` (shared state)
- Repositories and data sources: `LazySingleton`

### State Management

- **BLoC** (`flutter_bloc`) for feature state
- **HydratedBloc** for persisted state (ThemeBloc)
- Global blocs provided via `MultiBlocProvider` in `main.dart`

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run app (requires production flavor)
flutter run --flavor production

# Run tests
flutter test

# Run single test file
flutter test test/path/to/test_file_test.dart

# Verbose test output
flutter test --reporter=expanded

# Static analysis / linting
flutter analyze

# Build release APK
flutter build apk --release --flavor production

# Build release iOS
flutter build ios --release

# Generate local Quran assets from Tanzil text
dart run tool/generate_quran_assets.dart /path/to/quran-uthmani.txt assets/quran/uthmani
```

### Build Configuration

- Android uses Kotlin DSL (`build.gradle.kts`) with `production` product flavor
- Release builds require proper signing config (env vars or `keystore.properties`) — **no debug fallback**
- R8 minification + resource shrinking enabled for release
- NDK version: 29.0.13113456
- Firebase: Crashlytics, Analytics, Remote Config, Performance

### CI/CD

- **Fastlane** for Play Store deployments (`android/fastlane/`)
- **GitHub Actions** (`.github/workflows/deploy.yml`) — auto-deploy on push to `feature/sheikh-recitation-coach` (internal) or tag `v*` (production)

## Key APIs & External Services

| Service | Base URL | Auth |
|---------|----------|------|
| Quran.com v4 | `api.quran.com/api/v4` | Public |
| Quran Foundation Content | `api.quran.foundation` | Optional OAuth2 |
| Quran Foundation OAuth2 | `oauth2.quran.foundation` | PKCE flow |
| QuranHub (qiraat) | `api.quranhub.com/v1` | Public |
| Qurani.ai QRC | `wss://api.qurani.ai` | API key |

- API config via `--dart-define` flags (see `lib/core/config/api_config.dart`)
- Dio with interceptors: `QfAuthInterceptor` (OAuth2 token refresh), `QfApiInterceptor` (user API auth)

## App Configuration

- **Theme:** Material 3, seed color `#006754` (light) / `#87D1A4` (dark)
- **Fonts:** Poppins (UI), Amiri + NotoNaskhArabic (Quran text)
- **Localization:** English (`en_US`) and Arabic (`ar_EG`), runtime switchable via `LocaleController`
- **Local storage:** Hive boxes (`surah_cache`, `bookmarks`, `recitation_errors`, `recitation_sessions`, `memorization_progress`, `reading_logs`, `reading_goal`, `qiraat_cache`, `audio_cache`), SharedPreferences for settings
- **Quran text:** Local per-surah JSON under `assets/quran/uthmani/surah_<1-114>.json` (Tanzil Uthmani, CC BY-ND 3.0 — **do not modify**)

## Feature Screens

| Route | Screen | Description |
|-------|--------|-------------|
| `/OnboardingScreen` | Onboarding | First-run intro |
| `/mushaf_type_onboarding` | MushafTypeOnboarding | Select mushaf style (Madani/Egyptian/Indo-Pak/Warsh) |
| `/home_screen` | HomeScreen | Main entry, surah grid |
| `/surah_screen` | SurahScreen | Verse display, auto-scroll, hifz mode, tafsir, sharing, voice verification |
| `/mushaf_screen` | MushafScreen | 604-page horizontal RTL PageView (text/image/glyph rendering) |
| `/audio_player` | AudioPlayer | Verse-by-verse playback, speed control, sleep timer |
| `/bookmarks` | BookmarksScreen | Saved bookmarks |
| `/search_screen` | SearchScreen | Full-text verse search |
| `/verse_study` | VerseStudyScreen | Per-verse translations + tafsir |
| `/memorization` | MemorizationScreen | Per-surah memorization tracking |
| `/khatmah` | KhatmahScreen | Daily reading goals |
| `/recitation_errors` | RecitationErrorScreen | Practice verses |
| `/recitation_sessions` | RecitationSessionScreen | Session history |
| `/statistics` | StatisticsScreen | Usage stats |
| `/settings` | SettingsScreen | All app preferences |
| `/cloud_sync` | CloudSyncScreen | QF OAuth2 bookmark sync, delete data |
| `/about_screen` | AboutScreen | App info, acknowledgements |
| `/changelog` | ChangelogScreen | Version changelog |

## Coding Conventions

### Style
- Single quotes (`'`) over double quotes
- `const` constructors where possible
- Always declare return types
- `prefer_final_fields`
- Lint rules in `analysis_options.yaml` (extends `flutter_lints`)

### Architecture Patterns
- **BLoC per screen**: Each presentation feature has a `bloc/` subfolder with `event.dart`, `state.dart`, `bloc.dart`
- **Either pattern**: Repositories return `Either<Failure, T>` from `dartz`
- **Barrel file**: `core/app_export.dart` for common imports
- **NavigatorService**: Centralized navigation with global key

### RTL Convention
All Quran/Arabic text **must** use `textDirection: TextDirection.rtl`, regardless of app locale. Surah navigation arrows follow RTL semantics (◁ = next, ▷ = previous).

### Testing
- Tests mirror `lib/` structure under `test/`
- **mocktail** for mocking, **bloc_test** for BLoC testing
- Fixture files in `test/fixture/`

```dart
class MockRepository extends Mock implements SurahRepository {}

void main() {
  late SurahBloc bloc;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    bloc = SurahBloc(getSurah: GetSurah(surahRepository: mockRepository));
  });
}
```

## Known Issues & Warnings

- `unnecessary_non_null_assertion` in `surah_screen.dart` (~lines 475/503) — the `!` is required for compilation; Dart can't promote `Surah?` through indirect boolean guards. Do not remove.
- Java "Duplicate root element android" from stale `.kilo/worktrees/` — do not delete these worktrees.

## Security Notes

- API keys and OAuth secrets passed via `--dart-define`, never hardcoded
- Release signing requires env vars (`KEY_ALIAS`, `KEY_PASSWORD`, `KEYSTORE_PASSWORD`) or `keystore.properties`
- OAuth2 tokens stored in `flutter_secure_storage`
- "Delete My Data" feature revokes tokens and clears all local data
- See `SECURITY.md` and `PRIVACY.md` for full details
