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
