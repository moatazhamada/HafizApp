# Code Conventions & Best Practices

## BLoC Patterns

### Event Naming
- Format: `<Action><Feature>Event`
- Examples: `LoadSurahEvent`, `AddBookmarkEvent`, `DeleteBookmarkEvent`
- Events are immutable and extend `Equatable`
- Always override `props` for equality comparison

### State Naming
- Format: `<Status><Feature>State`
- Examples: `LoadingSurahState`, `SuccessSurahState`, `FailureSurahState`
- Common states: `Initial`, `Loading`, `Success`, `Failure`
- States are immutable and extend `Equatable`
- Include data in success states, error messages in failure states

### BLoC Structure
```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final UseCase useCase;
  
  FeatureBloc({required this.useCase}) : super(InitialFeatureState()) {
    on<FeatureEvent>(_mapEventToState);
  }
  
  void _mapEventToState(FeatureEvent event, Emitter<FeatureState> emit) async {
    if (event is LoadFeatureEvent) {
      emit(LoadingFeatureState());
      final result = await useCase(params);
      emit(result.fold(
        (failure) => FailureFeatureState(errorMessage: failure.errorMessage),
        (data) => SuccessFeatureState(data: data),
      ));
    }
  }
}
```

### Cubit vs Bloc
- Use **Cubit** for simple state changes (theme toggle, scroll position)
- Use **Bloc** for complex flows with multiple events (data fetching, user actions)

## Error Handling

### Using Either<Failure, Success>
- All repository methods return `Either<Failure, T>` from `dartz`
- Left side: `Failure` (error case)
- Right side: Success data
- Use `.fold()` to handle both cases

### Failure Types
```dart
ServerFailure(errorMessage)    // API errors, 4xx/5xx responses
ConnectionFailure()            // No internet connection
CacheFailure(errorMessage)     // Local storage errors
```

### Error Handling Pattern
```dart
final result = await repository.getData();
result.fold(
  (failure) {
    if (failure is ServerFailure) {
      // Handle server error
    } else if (failure is ConnectionFailure) {
      // Handle offline
    }
  },
  (data) {
    // Handle success
  },
);
```

## Widget Composition

### Const Constructors
- **Always** use `const` for widgets with no mutable state
- Improves performance by reusing widget instances
- Lint rule `prefer_const_constructors` enforces this

### Widget Organization
- Extract complex widgets into separate files
- Keep widget files under 300 lines
- Screen-specific widgets go in `presentation/<feature>/widgets/`
- Reusable widgets go in `lib/widgets/`

### BuildContext Safety
- Never store `BuildContext` in class fields
- Pass context as parameter when needed
- Use `mounted` check before async operations that use context

## Localization

### Adding New Strings
1. Add to `lib/localization/en_us/en_us_translations.dart`
2. Add to `lib/localization/ar_eg/ar_eg_translations.dart`
3. Use in code: `'key'.tr` (requires `app_export.dart` import)

### String Key Naming
- Prefix with category: `lbl_` (label), `msg_` (message), `err_` (error)
- Use snake_case: `lbl_surah_list`, `msg_bookmark_added`
- Keep keys descriptive but concise

### RTL Support
- Arabic text automatically flows RTL
- Use `Directionality` widget when needed
- Test both LTR and RTL layouts

## Analytics

### Event Naming
- Use snake_case: `surah_opened`, `bookmark_added`, `audio_played`
- Be specific but concise
- Include context: `screen_name`, `feature_name`

### Logging Events
```dart
AnalyticsService().logEvent(
  name: 'surah_opened',
  parameters: {
    'surah_id': surahId,
    'surah_name': surahName,
  },
);
```

## Logging

### Logger Usage
- **Never** use `print()` - use `Logger` class instead
- Debug info: `Logger.debug('message', feature: 'FeatureName')`
- General info: `Logger.info('message', feature: 'FeatureName')`
- Warnings: `Logger.warning('message', feature: 'FeatureName')`
- Errors: `Logger.error('message', feature: 'FeatureName', error: e, stackTrace: st)`

### Log Levels
- `LogMode.debug` - All logs printed to console
- `LogMode.live` - Only errors sent to Crashlytics

### Error Reporting
```dart
try {
  // risky operation
} catch (e, stackTrace) {
  Logger.error(
    'Failed to load data',
    feature: 'DataLoader',
    error: e,
    stackTrace: stackTrace,
    fatal: false, // true for critical errors
  );
}
```

## Code Style

### Imports
- Group imports: Flutter SDK → Third-party → Project
- Use relative imports within same layer
- Use `package:hafiz_app/` for cross-layer imports
- Use `core/app_export.dart` for common imports

### Formatting
- Run `dart format` before committing
- Max line length: 80 characters (enforced by formatter)
- Use trailing commas for better formatting

### Comments
- Use `//` for single-line comments
- Use `///` for documentation comments
- Document public APIs and complex logic
- Avoid obvious comments

### Null Safety
- Use `?` for nullable types
- Use `!` sparingly, only when certain
- Prefer `?.` and `??` operators
- Use `late` for deferred initialization

## Asset Management

### Adding Assets
1. Place file in appropriate `assets/` subdirectory
2. Add to `pubspec.yaml` under `flutter.assets`
3. Reference in code: `'assets/images/icon.svg'`

### Image Loading
- Use `CustomImageView` for network images (includes caching)
- Use `SvgPicture.asset()` for SVG files
- Use `Image.asset()` for PNG/JPG files

## Performance

### Build Optimization
- Use `const` constructors everywhere possible
- Avoid rebuilding entire trees - use `BlocBuilder` with `buildWhen`
- Extract static widgets to separate const widgets

### List Performance
- Use `ListView.builder` for long lists
- Use `scrollable_positioned_list` for jump-to functionality
- Implement proper `key` properties for list items

### Async Operations
- Use `async`/`await` for readability
- Handle errors with try-catch
- Show loading states during operations
- Cancel subscriptions in `dispose()`

## Testing Requirements

### What Needs Tests
- All BLoCs (events, states, transitions)
- All use cases
- All repositories
- Complex utility functions
- Critical business logic

### What Doesn't Need Tests
- Simple widgets without logic
- Models with only getters/setters
- Trivial utility functions
- UI-only components

### Test File Location
- Mirror the `lib/` structure in `test/`
- Example: `lib/domain/usecase/get_surah.dart` → `test/domain/usecase/get_surah_test.dart`
