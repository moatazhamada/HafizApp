# Hafiz App Test Suite

This directory contains comprehensive tests for the Hafiz App V3 major features.

## Test Structure

```
test/
├── core/                          # Core logic unit tests
│   ├── quran_index/
│   │   ├── mushaf_types_test.dart      # Tests for MushafType enum
│   │   └── page_index_test.dart        # Tests for MushafPageIndex
│   ├── deep_link/
│   │   └── deep_link_service_test.dart # Tests for DeepLinkService
│   ├── audio/
│   │   └── audio_player_handler_test.dart # Tests for AudioPlayerHandler
│   ├── network/
│   ├── errors/
│   └── utils/
├── presentation/                  # Widget tests for UI components
│   ├── mushaf_screen/
│   │   └── mushaf_screen_test.dart     # Tests for MushafScreen
│   └── audio_player_screen/
│       └── audio_player_screen_test.dart # Tests for AudioPlayerScreen
├── integration/                   # Integration tests for user flows
│   └── onboarding_mushaf_flow_test.dart # End-to-end user journeys
└── golden/                        # Golden tests for visual regression
    └── mushaf_types_golden_test.dart    # Visual tests for Mushaf types
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test groups
```bash
# Core logic tests
flutter test test/core/

# Widget tests
flutter test test/presentation/

# Integration tests
flutter test test/integration/

# Golden tests
flutter test test/golden/
```

### Run with coverage
```bash
flutter test --coverage
```

## Test Coverage

### Unit Tests

#### Mushaf Types (`test/core/quran_index/mushaf_types_test.dart`)
- Display names (Arabic and English)
- Page counts for all 4 types (Madani: 604, Indo-Pak: 558, etc.)
- Preference keys
- Icon and color uniqueness
- String to enum conversion
- Type descriptions

#### Mushaf Page Index (`test/core/quran_index/page_index_test.dart`)
- Page lookup by number
- Verse to page mapping
- Surah start detection
- Bismillah detection logic
- All 604 pages exist
- Invalid page handling

#### Deep Link Service (`test/core/deep_link/deep_link_service_test.dart`)
- URL parsing for surah links
- URL parsing for verse links
- URL parsing for Mushaf page links
- URL parsing for Juz links
- Invalid URL handling
- Link generation
- All 114 surahs supported
- All 604 pages supported
- All 30 Juz supported

#### Audio Player Handler (`test/core/audio/audio_player_handler_test.dart`)
- Class existence verification
- AudioServiceRepeatMode enum validation

### Widget Tests

#### Mushaf Screen (`test/presentation/mushaf_screen/mushaf_screen_test.dart`)
- Rendering with all 4 Mushaf types
- Mushaf type property validation
- Consistent behavior across types

#### Audio Player Screen (`test/presentation/audio_player_screen/audio_player_screen_test.dart`)
- Screen rendering
- Surah name display
- Playback controls (play, pause, skip)
- Progress slider
- Loop and sleep timer buttons
- Back button handling

### Integration Tests

#### User Flows (`test/integration/onboarding_mushaf_flow_test.dart`)
- App launch
- All Mushaf types availability
- Mushaf type properties
- Type to string conversion

### Golden Tests

#### Mushaf Types Visual (`test/golden/mushaf_types_golden_test.dart`)
- Mushaf type selection cards (all 4 types, selected/unselected)
- Verse share styles (classic, modern, minimal, gradient)

## Key Testing Patterns

### Mocking BLoCs
Widget tests use `mockito` to mock BLoCs:
```dart
final mockSurahBloc = MockSurahBloc();
when(mockSurahBloc.state).thenReturn(InitialSurahState());
when(mockSurahBloc.stream).thenAnswer(
  (_) => Stream.fromIterable([InitialSurahState()]),
);
```

### Test Widget Building
```dart
Widget buildTestableWidget({MushafType type}) {
  return MaterialApp(
    home: BlocProvider<SurahBloc>.value(
      value: mockSurahBloc,
      child: MushafScreen(mushafType: type),
    ),
  );
}
```

### Golden File Testing
```dart
await expectLater(
  find.byType(MushafTypeCard),
  matchesGoldenFile('goldens/mushaf_card_madani.png'),
);
```

## Continuous Integration

Tests are run automatically on:
- Pull request creation
- Push to main branch
- Before deployment

To ensure CI passes:
1. All tests must pass
2. No analyzer warnings
3. Code coverage meets thresholds

## Adding New Tests

When adding new features:
1. Add unit tests for business logic
2. Add widget tests for UI components
3. Add integration tests for user flows (if applicable)
4. Update this README with test documentation
