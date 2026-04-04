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
- `repository/` - Concrete repository implementations using `Either<Failure, Success>` pattern

**Presentation Layer** (`presentation/`) - UI and state management:

- Each feature folder contains `bloc/`, `widgets/`, and `pages/` subfolders
- Uses BLoC pattern: Event → Bloc → State
- Screen widgets consume BLoC state via `BlocBuilder`/`BlocProvider`

**Core** (`core/`) - Shared infrastructure:

- `errors/` - Failure types (ServerFailure, ConnectionFailure, CacheFailure)
- `network/` - Dio client, interceptors, connectivity checks
- `utils/` - Preferences, navigation, logging
- `analytics/` - Analytics service with route observer tracking
- `audio/` - Background audio playback handler (AudioPlayerHandler)
- `deep_link/` - Deep linking and SharePlus integration
- `quran_index/` - QuranIndex and MushafPageIndex for navigation
- `notifications/` - Local notifications setup
- `qiraat/` - Quranic recitation variant support
- `update/` - Force update mechanism via Remote Config
- `app_export.dart` - Barrel file for common imports

### Dependency Injection

Uses **GetIt** service locator configured in `injection_container.dart`:

- Access via `sl<Type>()` (e.g., `sl<SurahBloc>()`)
- **Factory** - BLoCs (new instance per access)
- **LazySingleton** - Repositories, DataSources, UseCases, Services

### State Management

- **BLoC** for feature state (SurahBloc, BookmarkBloc, SearchBloc, etc.)
- **HydratedBloc** for persisted state (ThemeBloc)
- Global blocs provided at app root in `main.dart` via `MultiBlocProvider`
- All BLoC events and states must extend `Equatable`

### Data Flow Pattern

1. UI dispatches Event to BLoC
2. BLoC calls UseCase
3. UseCase calls Repository (abstract interface)
4. Repository fetches from DataSource, returns `Either<Failure, Data>`
5. BLoC emits new State; UI rebuilds via BlocBuilder

### Integration Points

- **Firebase**: Crashlytics (crash reporting), Analytics, Remote Config (feature flags/force update), Firestore (user data sync)
- **Audio**: `audio_service` + `just_audio` for background playback; `AudioPlayerHandler` registered as a service
- **Local Storage**: Hive for offline Quran cache; SharedPreferences for simple key-value (theme, locale)
- **External API**: Quran.Foundation API via Dio with OAuth2 (`QfAuthInterceptor`); falls back to local JSON for Quran text

### App Initialization Order (`main.dart`)

Services initialize sequentially with timeouts to prevent hangs:
Preferences → Hive → GetIt (DI) → AudioService → Firebase (non-blocking)

Background tasks (e.g., MushafPageIndex loading) are started without `await` to keep startup fast. Flutter and platform errors are forwarded to Crashlytics.

### Quran Text

- **CRITICAL RULE FOR ALL AGENTS:** The `quran/*.json` files (and any related json files modeling pure Quran text) located in assets MUST NOT be modified, edited, or touched under ANY circumstances.
- Local JSON files in `assets/quran/uthmani/surah_<1-114>.json`
- SurahLocalDataSource reads from assets; remote API is fallback only
- Schema: `{"chapter": [{"chapter": N, "verse": N, "text": "..."}]}`

### Localization

- Supports English (en_US) and Arabic (ar_EG)
- Translation maps in `localization/en_us/` and `localization/ar_eg/`
- Use `.tr` extension on strings: `"lbl_home".tr`
- LocaleController manages runtime locale switching

### Code Style

- BLoC Events: `PascalCase` suffixed with `Event` (e.g., `FetchSurahEvent`)
- BLoC States: `PascalCase` suffixed with state type (e.g., `SurahLoaded`, `SurahLoading`)
- Prefer `final` over `var`; use `const` constructors for events, states, and stateless widgets
- Never expose raw exceptions in UI — use `Failure` subclasses
- No direct Firebase calls from UI; go through BLoC

### Adding a New Feature

1. **Domain**: Create entity, repository interface, usecase
2. **Data**: Implement repository, data source
3. **Presentation**: Create BLoC (events, states, bloc), pages, widgets
4. **Injection**: Register in `injection_container.dart`
5. **UI**: Wire with `BlocBuilder<MyBloc, MyState>`
6. **Tests**: Mirror structure in `test/`, use `blocTest` patterns
7. **Localization**: Add keys to both locale files

### Testing

Tests mirror the `lib/` structure under `test/`:

- Uses **mocktail** for mocking
- Uses **bloc_test** for BLoC testing
- Fixture files in `test/fixture/`

```dart
class MockSurahRepository extends Mock implements SurahRepository {}

void main() {
  late SurahBloc bloc;
  late MockSurahRepository mockRepository;

  setUp(() {
    mockRepository = MockSurahRepository();
    bloc = SurahBloc(getSurah: GetSurah(surahRepository: mockRepository));
  });

  group('SurahBloc', () {
    blocTest<SurahBloc, SurahState>(
      'emits [SurahLoading, SurahLoaded] when GetSurah succeeds',
      build: () {
        when(() => mockRepository.getSurah(1))
            .thenAnswer((_) async => Right(testVerses));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchSurahEvent(1)),
      expect: () => [SurahLoading(), SurahLoaded(testVerses)],
    );
  });
}
```
