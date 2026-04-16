# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/test_file_test.dart

# Run tests with verbose output
flutter test --reporter=expanded

# Analyze code (linting)
flutter analyze

# Build release APK
flutter build apk --release

# Build release iOS
flutter build ios --release
```

## Architecture Overview

This is a Flutter Quran memorization app using **Clean Architecture** with three main layers:

### Layer Structure (`lib/`)

**Domain Layer** (`domain/`) - Business logic, independent of Flutter:
- `entities/` - Core business objects (Verse, Bookmark)
- `repository/` - Abstract repository interfaces
- `usecase/` - Use cases encapsulating business operations (e.g., GetSurah)

**Data Layer** (`data/`) - External data handling:
- `datasource/` - Remote (API) and local (Hive cache, local JSON) data sources
- `model/` - Data models with JSON serialization (map to/from entities)
- `repository/` - Concrete repository implementations using Either<Failure, Success> pattern

**Presentation Layer** (`presentation/`) - UI and state management:
- Each screen has its own folder with `bloc/` subfolder
- Uses BLoC pattern: Event → Bloc → State
- Screen widgets consume BLoC state via BlocBuilder/BlocProvider

**Core** (`core/`) - Shared utilities:
- `errors/` - Failure types (ServerFailure, ConnectionFailure, CacheFailure)
- `network/` - Dio client configuration, network connectivity checks
- `utils/` - Preferences, navigation, logging
- `app_export.dart` - Barrel file for common imports

### Dependency Injection

Uses **GetIt** service locator configured in `injection_container.dart`:
- Access the container via `sl<Type>()` (e.g., `sl<SurahBloc>()`)
- BLoCs are registered as Factory (new instance) or LazySingleton (shared)
- Repositories and data sources are LazySingletons

### State Management

- **BLoC** for feature state (SurahBloc, BookmarkBloc, SearchBloc, etc.)
- **HydratedBloc** for persisted state (ThemeBloc)
- Global blocs provided at app root in `main.dart` via MultiBlocProvider

### Data Flow Pattern

1. UI dispatches Event to BLoC
2. BLoC calls UseCase
3. UseCase calls Repository (abstract interface)
4. Repository implementation fetches from DataSource
5. Returns `Either<Failure, Data>` - left is error, right is success
6. BLoC emits new State based on result

### Quran Text

- Local JSON files in `assets/quran/uthmani/surah_<1-114>.json`
- SurahLocalDataSource reads from assets; remote API is fallback only
- Schema: `{"chapter": [{"chapter": N, "verse": N, "text": "..."}]}`

### Localization

- Supports English (en_US) and Arabic (ar_EG)
- Translation maps in `localization/en_us/` and `localization/ar_eg/`
- Use `.tr` extension on strings: `"lbl_home".tr`
- LocaleController manages runtime locale switching

### Testing

Tests mirror the `lib/` structure under `test/`:
- Uses **mocktail** for mocking
- Uses **bloc_test** for BLoC testing
- Fixture files in `test/fixture/`

Example test pattern:
```dart
class MockRepository extends Mock implements SurahRepository {}

void main() {
  late SurahBloc bloc;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    bloc = SurahBloc(getSurah: GetSurah(surahRepository: mockRepository));
  });

  // tests...
}
```

## Product Flavors

The project uses product flavors. Always use `--flavor production`:
```bash
flutter run --flavor production
flutter build apk --debug --flavor production
flutter build apk --release --flavor production
```

## Features Map

### Navigation Drawer (from Home screen)
| Index | Destination | Route |
|-------|------------|-------|
| 0 | Bookmarks | `/bookmarks` |
| 1 | Practice Verses (Recitation Errors) | `/recitation_errors` |
| 2 | Session History | `/recitation_sessions` |
| 3 | Memorization Tracker | `/memorization` |
| 4 | Khatmah Tracker | `/khatmah` |
| 5 | Statistics | `/statistics` |
| 6 | Mushaf View | `/mushaf_screen` |
| 7 | Settings | `/settings` |
| 8 | About | `/about_screen` |

### Surah Screen Features
- **Audio Player** — Headphones icon in app bar, navigates to `/audio_player` with surah args
- **Auto-scroll** — Play/pause icon, configurable speed (long-press for speed picker)
- **Hifz Mode** — Hides verse text for memorization practice (in overflow menu)
- **Bookmark** — Per-surah bookmark toggle (in overflow menu)
- **Tafsir** — Per-verse bottom sheet from verse context menu
- **Verse Sharing** — Share/copy from verse context menu
- **Voice Verification** — Per-verse recitation check from context menu
- **Surah Navigation** — Previous/next surah buttons at bottom

### Settings
- Language (English/Arabic/System)
- View Mode (Single Line vs Continuous/RichText)
- Theme (Light/Dark/System)
- Quran Font Size slider (16-40)
- Orientation (System/Portrait/Landscape) — wired to SystemChrome
- Default Quran View (Surah/Mushaf) — wired to home screen navigation
- Reading Navigation Mode (Scroll/Page) — saved but not yet consumed
- Cloud Sync
- Recitation Coach settings (Provider, Qiraat edition, Reciter, Whisper model)

### Onboarding Flow
Onboarding → MushafTypeOnboarding (Madani/Egyptian/Indo-Pak/Warsh) → Home

### Key Files
- `lib/routes/app_routes.dart` — All routes
- `lib/injection_container.dart` — DI with GetIt
- `lib/core/utils/pref_utils.dart` — SharedPreferences wrapper (all settings)
- `lib/core/quran_index/quran_surah.dart` — Surah class and QuranIndex
- `lib/core/quran_index/mushaf_page_index.dart` — Page-to-surah mapping (604 pages)
- `lib/core/audio/audio_player_handler.dart` — Singleton audio handler (just_audio)
- `lib/core/theme/app_colors.dart` — AppColors with theme-aware colors

### Known Warnings (Acceptable)
- `unnecessary_non_null_assertion` in `surah_screen.dart` lines ~428/433/455/460 — the `!` is required for compilation, Dart can't promote `Surah?` through indirect boolean guards
- Java "Duplicate root element android" from stale `.kilo/worktrees/` — do not delete these worktrees
