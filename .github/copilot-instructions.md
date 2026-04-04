# Copilot Instructions for HafizApp

AI agents working in this Flutter Quran memorization app should follow these project-specific guidelines.

## Build and Test Commands

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

# Analyze code for style issues
flutter analyze

# Build release APK
flutter build apk --release

# Build release iOS
flutter build ios --release
```

## Architecture

This project uses **Clean Architecture** with three tightly decoupled layers:

### Layer Structure (`lib/`)

- **Domain** (`domain/`) - Pure business logic, framework-independent
  - `entities/` - Core objects (Verse, Bookmark)
  - `repository/` - Abstract repository interfaces (contracts)
  - `usecase/` - Encapsulates business operations (e.g., GetSurah, AddBookmark)

- **Data** (`data/`) - External data sources and mapping
  - `datasource/` - Local (Hive, JSON) and remote (API) sources
  - `model/` - Data models with JSON serialization (map to entities)
  - `repository/` - Concrete implementations using `Either<Failure, Success>` pattern

- **Presentation** (`presentation/`) - UI and state management
  - Each feature has folder structure: `feature_name/bloc/`, `feature_name/widgets/`, `feature_name/pages/`
  - **BLoC pattern**: Event → Bloc → State (one BLoC per feature)
  - **HydratedBloc** for persisted state (ThemeBloc)
  - Widgets consume state via `BlocBuilder` and `BlocProvider`

- **Core** (`core/`) - Shared utilities
  - `errors/` - Custom `Failure` types (ServerFailure, ConnectionFailure, CacheFailure)
  - `network/` - Dio client configuration, connectivity checks
  - `utils/` - Preferences, navigation, logging
  - `app_export.dart` - Barrel file for common imports

### Data Flow

1. UI dispatches `Event` to BLoC
2. BLoC calls `UseCase`
3. UseCase delegates to Repository (abstract interface)
4. Repository implementation calls appropriate DataSource
5. Returns `Either<Failure, Data>` (left = error, right = success)
6. BLoC emits new `State` based on result
7. UI rebuilds via BlocBuilder

### Dependency Injection (GetIt)

Access via `sl<Type>()` (e.g., `sl<SurahBloc>()`). Configured in [injection_container.dart](lib/injection_container.dart):
- **Factory** - BLoCs (new instance per access)
- **LazySingleton** - Repositories, DataSources, UseCases

## Code Style

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes/Enums**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `camelCase` (use `const` keyword)
- **BLoC Events**: `FetchSurahsEvent`, `AddBookmarkEvent` suffix with `Event`
- **BLoC States**: `SurahInitial`, `SurahLoading`, `SurahLoaded` suffix with state type

### Dart/Flutter Patterns

- Use `===` for null checks: `value == null` or `value != null`
- Prefer `final` over `var` for clarity
- Use `const` constructors where possible (BLoC events/states, widgets)
- Avoid mutable state in classes; prefer value objects
- Use `sealed class` for union types (state variants)
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide

### Widget Structure

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key, required this.data}) : super(key: key);

  final String data;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        return state.when(
          initial: () => Container(),
          loading: () => LoadingWidget(),
          loaded: (data) => ContentWidget(data: data),
          error: (message) => ErrorWidget(message: message),
        );
      },
    );
  }
}
```

## Project Conventions

### Error Handling

- Always return `Either` from repository methods:
  ```dart
  Future<Either<Failure, List<Verse>>> getSurah(int surahId)
  ```
- BLoCs wrap UseCase calls in try-catch, emit error states with `Failure.message`
- Never expose raw exceptions in UI—use `Failure` subclasses

### State Management with Equatable

All BLoC events and states must extend `Equatable` for comparison:
```dart
class SurahLoaded extends SurahState {
  final List<Verse> verses;
  
  const SurahLoaded(this.verses);
  
  @override
  List<Object?> get props => [verses];
}
```

### Localization

- Supports **en_US** and **ar_EG**
- Access keys with `.tr`: `"lbl_home".tr`, `"lbl_loading".tr`
- Translation files: `localization/{en_us,ar_eg}/` (language_country.dart)
- LocaleController manages runtime locale switching

### Quran Text Data

**⚠️ CRITICAL:** `quran/*.json` files and any JSON files modeling Quran text MUST NOT be modified, edited, or touched
- Schema: `{"chapter": [{"chapter": N, "verse": N, "text": "..."}]}`
- Local source: `assets/quran/uthmani/surah_<1-114>.json`
- Remote API fallback only
- Handled via SurahLocalDataSource

## Testing

Tests mirror `lib/` structure under `test/`:

- **Mock framework**: mocktail
- **BLoC testing**: bloc_test
- **Fixtures**: `test/fixture/` (JSON data, mock responses)

### Test Pattern

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
            .thenAnswer((_) async => Right(testSurahs));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchSurahEvent(1)),
      expect: () => [SurahLoading(), SurahLoaded(testSurahs)],
    );
  });
}
```

## Integration Points

### Firebase Services

- **Analytics** - Configured in [firebase_options.dart](lib/firebase_options.dart)
- **Crashlytics** - Automatic crash reporting
- **Remote Config** - Feature flags (if applicable)
- **Cloud Firestore** - User bookmarks, progress tracking

### External APIs

- Configured via Dio client in `core/network/`
- Base URL and interceptors in BaseApiConsumer
- Fallback to local JSON for Quran text

### Local Storage

- **Hive** - Offline Quran cache, user preferences
- **SharedPreferences** - Simple key-value data (theme, locale)

## Security

### Sensitive Data

- Never hardcode API keys—use Dart environment variables or Firebase Remote Config
- API base URLs configured via environment (dev, staging, production)
- Firebase credentials handled via `google-services.json` (Android) and config files (iOS)

### Network Security

- All API calls go through Dio with certificate pinning (if available)
- Cached responses use Hive with local encryption
- User bookmarks synced to Firestore with proper authentication

### Code Patterns to Avoid

- ❌ Direct Firebase calls from UI (use BLoC)
- ❌ Hardcoded strings; use localization keys
- ❌ Mutable singletons outside GetIt
- ❌ Modifying `quran/*.json` files under any circumstances

## Example Workflow

Adding a new feature (e.g., "Favorites"):

1. **Domain Layer**: Create `Favorite` entity, `FavoriteRepository` interface, `GetFavorites` usecase
2. **Data Layer**: Implement `FavoriteRepositoryImpl`, `FavoriteLocalDataSource`
3. **Presentation**: Create `FavoriteBloc`, events, states, pages/widgets
4. **Injection**: Register in [injection_container.dart](lib/injection_container.dart)
5. **UI**: Build widgets with `BlocBuilder<FavoriteBloc, FavoriteState>`
6. **Tests**: Mirror structure in `test/presentation/favorites/bloc/`, use blocTest patterns
7. **Localization**: Add keys to `localization/{en_us,ar_eg}/`
