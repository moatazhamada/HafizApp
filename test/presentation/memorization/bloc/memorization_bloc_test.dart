import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';
import 'package:hafiz_app/domain/repository/memorization_repository.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_bloc.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_event.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_state.dart';
import 'package:mocktail/mocktail.dart';

class MockMemorizationRepository extends Mock
    implements MemorizationRepository {}
class FakeMemorizationProgress extends Fake
    implements MemorizationProgress {}

final testProgress = MemorizationProgress(
  surahId: 1,
  surahName: 'Al-Fatiha',
  status: MemorizationStatus.memorized,
  easeFactor: 2500,
  interval: 30,
  repetition: 5,
  nextReviewDate: DateTime(2024, 1, 31),
  lastReviewDate: DateTime(2024, 1, 1),
  bestScore: 95,
);

final dueProgress = MemorizationProgress(
  surahId: 2,
  surahName: 'Al-Baqarah',
  status: MemorizationStatus.inProgress,
  easeFactor: 2500,
  interval: 1,
  repetition: 1,
  nextReviewDate: DateTime(2024, 1, 1),
  lastReviewDate: DateTime(2023, 12, 31),
  bestScore: 80,
);

void main() {
  late MockMemorizationRepository mockRepo;
  late MemorizationBloc bloc;

  setUpAll(() {
    registerFallbackValue(FakeMemorizationProgress());
  });

  setUp(() {
    mockRepo = MockMemorizationRepository();
    bloc = MemorizationBloc(repository: mockRepo);
  });

  tearDown(() => bloc.close());

  test('initial state is MemorizationInitial', () {
    expect(bloc.state, isA<MemorizationInitial>());
  });

  group('LoadMemorizationProgress', () {
    blocTest<MemorizationBloc, MemorizationState>(
      'emits [Loading, Loaded] with correct counts',
      build: () {
        when(() => mockRepo.getAllProgress())
            .thenAnswer((_) async => Right([testProgress, dueProgress]));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadMemorizationProgress()),
      expect: () => [
        isA<MemorizationLoading>(),
        predicate<MemorizationState>((s) =>
            s is MemorizationLoaded &&
            s.totalMemorized == 1 &&
            s.totalInProgress == 1 &&
            s.totalNotStarted == 112),
      ],
    );

    blocTest<MemorizationBloc, MemorizationState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepo.getAllProgress())
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadMemorizationProgress()),
      expect: () => [
        isA<MemorizationLoading>(),
        isA<MemorizationError>(),
      ],
    );
  });

  group('RecordReview', () {
    blocTest<MemorizationBloc, MemorizationState>(
      'reloads progress on success',
      build: () {
        when(() => mockRepo.recordReview(1, 90))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepo.getAllProgress())
            .thenAnswer((_) async => Right([testProgress]));
        return bloc;
      },
      act: (bloc) => bloc.add(const RecordReview(surahId: 1, score: 90)),
      expect: () => [
        isA<MemorizationLoading>(),
        isA<MemorizationLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepo.recordReview(1, 90)).called(1);
      },
    );

    blocTest<MemorizationBloc, MemorizationState>(
      'emits [Error] on failure',
      build: () {
        when(() => mockRepo.recordReview(1, 90))
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const RecordReview(surahId: 1, score: 90)),
      expect: () => [
        isA<MemorizationError>(),
      ],
    );
  });
}
