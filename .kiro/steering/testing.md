# Testing Guidelines

## Test Structure

### Test Organization
```
test/
├── core/           # Unit tests for utilities and services
├── domain/         # Unit tests for use cases
├── data/           # Unit tests for repositories and data sources
├── presentation/   # Widget tests for UI components
├── integration/    # End-to-end user flow tests
├── golden/         # Visual regression tests
└── fixture/        # Test data and helpers
```

## BLoC Testing

### Setup with bloc_test
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUseCase extends Mock implements GetSurah {}

void main() {
  late FeatureBloc bloc;
  late MockUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockUseCase();
    bloc = FeatureBloc(useCase: mockUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  blocTest<FeatureBloc, FeatureState>(
    'emits [Loading, Success] when data loads successfully',
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => Right(mockData));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadFeatureEvent()),
    expect: () => [
      LoadingFeatureState(),
      SuccessFeatureState(data: mockData),
    ],
  );
}
```

### Testing State Transitions
- Test initial state
- Test loading states
- Test success states with data
- Test failure states with error messages
- Test edge cases (empty data, null values)

### Testing Events
- Verify events trigger correct state changes
- Test event equality with `props`
- Test multiple events in sequence

## Mocking with Mocktail

### Creating Mocks
```dart
class MockRepository extends Mock implements SurahRepository {}
class MockDataSource extends Mock implements SurahRemoteDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
```

### Stubbing Methods
```dart
// Successful response
when(() => mockRepo.getSurah(any()))
    .thenAnswer((_) async => Right(mockSurah));

// Failure response
when(() => mockRepo.getSurah(any()))
    .thenAnswer((_) async => Left(ServerFailure('Error')));

// Synchronous return
when(() => mockNetworkInfo.isConnected).thenReturn(true);
```

### Verifying Calls
```dart
verify(() => mockRepo.getSurah(surahId)).called(1);
verifyNever(() => mockRepo.deleteSurah(any()));
```

## Widget Testing

### Basic Widget Test
```dart
testWidgets('should display surah name', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SurahListItem(surah: mockSurah),
    ),
  );

  expect(find.text('Al-Fatiha'), findsOneWidget);
  expect(find.text('الفاتحة'), findsOneWidget);
});
```

### Testing with BLoC
```dart
testWidgets('should show loading indicator', (tester) async {
  final mockBloc = MockSurahBloc();
  
  whenListen(
    mockBloc,
    Stream.fromIterable([LoadingSurahState()]),
    initialState: InitialSurahState(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SurahBloc>.value(
        value: mockBloc,
        child: SurahScreen(),
      ),
    ),
  );

  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### User Interaction Testing
```dart
testWidgets('should navigate on tap', (tester) async {
  await tester.pumpWidget(MaterialApp(home: HomeScreen()));
  
  await tester.tap(find.text('Al-Fatiha'));
  await tester.pumpAndSettle();
  
  expect(find.byType(SurahScreen), findsOneWidget);
});
```

## Golden Tests

### Creating Golden Files
```dart
testWidgets('mushaf card matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MushafTypeCard(
        type: MushafType.madani,
        isSelected: true,
      ),
    ),
  );

  await expectLater(
    find.byType(MushafTypeCard),
    matchesGoldenFile('goldens/mushaf_card_madani.png'),
  );
});
```

### Updating Golden Files
```bash
# Update all golden files
flutter test --update-goldens

# Update specific test
flutter test test/golden/mushaf_types_golden_test.dart --update-goldens
```

### Golden Test Best Practices
- Test different screen sizes
- Test light and dark themes
- Test selected/unselected states
- Keep golden files small (use specific widgets, not full screens)

## Integration Tests

### Setup
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete user flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Test flow
  });
}
```

### Testing User Flows
```dart
testWidgets('onboarding to mushaf flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Tap get started
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();

  // Select mushaf type
  await tester.tap(find.text('Madani (Uthmani)'));
  await tester.pumpAndSettle();

  // Verify home screen
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

## Repository Testing

### Testing with Mocks
```dart
void main() {
  late SurahRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = SurahRepositoryImpl(
      surahRemoteDataSource: mockRemote,
      surahLocalDataSource: mockLocal,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getSurah', () {
    test('should return remote data when online', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);
      when(() => mockRemote.getSurah(any()))
          .thenAnswer((_) async => mockSurahModel);
      when(() => mockLocal.cacheSurah(any()))
          .thenAnswer((_) async => Future.value());

      final result = await repository.getSurah('1');

      verify(() => mockRemote.getSurah('1'));
      verify(() => mockLocal.cacheSurah(mockSurahModel));
      expect(result, Right(mockSurah));
    });

    test('should return cached data when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(false);
      when(() => mockLocal.getCachedSurah(any()))
          .thenAnswer((_) async => mockSurahModel);

      final result = await repository.getSurah('1');

      verifyNever(() => mockRemote.getSurah(any()));
      verify(() => mockLocal.getCachedSurah('1'));
      expect(result, Right(mockSurah));
    });

    test('should return failure when offline and no cache', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(false);
      when(() => mockLocal.getCachedSurah(any()))
          .thenThrow(CacheException());

      final result = await repository.getSurah('1');

      expect(result, Left(CacheFailure('No cached data')));
    });
  });
}
```

## Use Case Testing

### Simple Use Case Test
```dart
void main() {
  late GetSurah useCase;
  late MockSurahRepository mockRepository;

  setUp(() {
    mockRepository = MockSurahRepository();
    useCase = GetSurah(surahRepository: mockRepository);
  });

  test('should get surah from repository', () async {
    when(() => mockRepository.getSurah(any()))
        .thenAnswer((_) async => Right(mockSurah));

    final result = await useCase(ParamsGetSurah(surahId: '1'));

    expect(result, Right(mockSurah));
    verify(() => mockRepository.getSurah('1'));
  });
}
```

## Test Fixtures

### Creating Test Data
```dart
// test/fixture/fixture_reader.dart
import 'dart:io';

String fixture(String name) {
  return File('test/fixture/$name').readAsStringSync();
}

// Usage
final jsonString = fixture('surah_response.json');
final surahModel = SurahModel.fromJson(json.decode(jsonString));
```

### Mock Data
```dart
// test/fixture/mock_data.dart
final mockSurah = Surah(
  id: 1,
  nameEnglish: 'Al-Fatiha',
  nameArabic: 'الفاتحة',
);

final mockVerses = [
  Verse(chapter: 1, verse: 1, text: 'بِسْمِ اللَّهِ...'),
  Verse(chapter: 1, verse: 2, text: 'الْحَمْدُ لِلَّهِ...'),
];
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/core/quran_index/mushaf_types_test.dart
```

### Run Tests by Group
```bash
flutter test test/core/
flutter test test/presentation/
flutter test test/integration/
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Golden Tests
```bash
flutter test test/golden/
flutter test --update-goldens  # Update golden files
```

## Test Coverage Goals

### Minimum Coverage
- BLoCs: 100%
- Use Cases: 100%
- Repositories: 90%
- Data Sources: 80%
- Utilities: 80%
- Widgets: 60%

### What to Prioritize
1. Business logic (use cases, repositories)
2. State management (BLoCs)
3. Critical user flows (integration tests)
4. Complex widgets with logic
5. Error handling paths

## Common Testing Patterns

### Testing Async Operations
```dart
test('should handle async operation', () async {
  when(() => mockRepo.getData())
      .thenAnswer((_) async => Future.delayed(
            Duration(milliseconds: 100),
            () => Right(data),
          ));

  final result = await useCase();
  
  expect(result, Right(data));
});
```

### Testing Streams
```dart
test('should emit multiple states', () async {
  final stream = bloc.stream;
  
  bloc.add(LoadEvent());
  
  await expectLater(
    stream,
    emitsInOrder([
      LoadingState(),
      SuccessState(data),
    ]),
  );
});
```

### Testing Exceptions
```dart
test('should handle exception', () async {
  when(() => mockRepo.getData())
      .thenThrow(ServerException());

  final result = await useCase();

  expect(result, Left(ServerFailure('Server error')));
});
```

## Debugging Tests

### Print Debug Info
```dart
test('debug test', () {
  print('State: ${bloc.state}');
  debugPrint('Debug info');
});
```

### Skip Tests Temporarily
```dart
test('work in progress', () {
  // test code
}, skip: true);
```

### Focus on Single Test
```dart
// Only run this test
testWidgets('focused test', (tester) async {
  // test code
}, skip: false);
```
