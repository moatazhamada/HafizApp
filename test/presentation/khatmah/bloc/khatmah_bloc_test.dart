import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_bloc.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_event.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockKhatmahRepository extends Mock implements KhatmahRepository {}

final testGoal = ReadingGoal(
  dailyVerseTarget: 50,
  startDate: DateTime(2024, 1, 1),
);

final testLog = DailyReadingLog(
  date: DateTime(2024, 1, 1),
  versesRead: 30,
  surahsVisited: 2,
);

void main() {
  late MockKhatmahRepository mockRepo;
  late KhatmahBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockKhatmahRepository();
    bloc = KhatmahBloc(repository: mockRepo);
    when(() => mockRepo.syncPendingActivityDays())
        .thenAnswer((_) async => const Right(0));
  });

  tearDown(() => bloc.close());

  test('initial state is KhatmahInitial', () {
    expect(bloc.state, isA<KhatmahInitial>());
  });

  group('LoadKhatmahDashboard', () {
    blocTest<KhatmahBloc, KhatmahState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => mockRepo.getGoal()).thenAnswer((_) async => Right(testGoal));
        when(() => mockRepo.getTodayLog()).thenAnswer((_) async => Right(testLog));
        when(() => mockRepo.getRecentLogs(30))
            .thenAnswer((_) async => const Right([]));
        when(() => mockRepo.getReconciledStreak())
            .thenAnswer((_) async => const Right(5));
        when(() => mockRepo.getCurrentStreak())
            .thenAnswer((_) async => const Right(3));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadKhatmahDashboard()),
      expect: () => [
        isA<KhatmahLoading>(),
        predicate<KhatmahState>((s) =>
            s is KhatmahDashboardLoaded &&
            s.streak == 5 &&
            s.cloudStreak == 2 &&
            s.localStreak == 3),
      ],
      verify: (_) {
        verify(() => mockRepo.getGoal()).called(1);
        verify(() => mockRepo.getTodayLog()).called(1);
        verify(() => mockRepo.getRecentLogs(30)).called(1);
        verify(() => mockRepo.getReconciledStreak()).called(1);
        verify(() => mockRepo.getCurrentStreak()).called(1);
      },
    );

    blocTest<KhatmahBloc, KhatmahState>(
      'emits [Loading, Error] when all 5 fetches fail',
      build: () {
        when(() => mockRepo.getGoal())
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        when(() => mockRepo.getTodayLog())
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        when(() => mockRepo.getRecentLogs(30))
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        when(() => mockRepo.getReconciledStreak())
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        when(() => mockRepo.getCurrentStreak())
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadKhatmahDashboard()),
      expect: () => [
        isA<KhatmahLoading>(),
        isA<KhatmahError>(),
      ],
    );
  });

  group('SetReadingGoal', () {
    blocTest<KhatmahBloc, KhatmahState>(
      'emits [Loaded] on success',
      build: () {
        when(() => mockRepo.setGoal(50))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepo.getGoal()).thenAnswer((_) async => Right(testGoal));
        when(() => mockRepo.getTodayLog())
            .thenAnswer((_) async => Right(testLog));
        when(() => mockRepo.getRecentLogs(30))
            .thenAnswer((_) async => const Right([]));
        when(() => mockRepo.getReconciledStreak())
            .thenAnswer((_) async => const Right(5));
        when(() => mockRepo.getCurrentStreak())
            .thenAnswer((_) async => const Right(3));
        return bloc;
      },
      act: (bloc) => bloc.add(const SetReadingGoal(50)),
      expect: () => [
        isA<KhatmahLoading>(),
        isA<KhatmahDashboardLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepo.setGoal(50)).called(1);
      },
    );

    blocTest<KhatmahBloc, KhatmahState>(
      'emits [Error] on failure',
      build: () {
        when(() => mockRepo.setGoal(50))
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const SetReadingGoal(50)),
      expect: () => [
        isA<KhatmahError>(),
      ],
    );
  });

  group('RecordReading', () {
    blocTest<KhatmahBloc, KhatmahState>(
      'emits [Loaded] on success',
      build: () {
        when(() => mockRepo.logReading(
              verses: any(named: 'verses'),
              surahs: any(named: 'surahs'),
              durationSeconds: any(named: 'durationSeconds'),
            )).thenAnswer((_) async => const Right(null));
        when(() => mockRepo.getGoal()).thenAnswer((_) async => Right(testGoal));
        when(() => mockRepo.getTodayLog())
            .thenAnswer((_) async => Right(testLog));
        when(() => mockRepo.getRecentLogs(30))
            .thenAnswer((_) async => const Right([]));
        when(() => mockRepo.getReconciledStreak())
            .thenAnswer((_) async => const Right(5));
        when(() => mockRepo.getCurrentStreak())
            .thenAnswer((_) async => const Right(3));
        return bloc;
      },
      act: (bloc) => bloc.add(const RecordReading(verses: 10, surahs: 1)),
      expect: () => [
        isA<KhatmahLoading>(),
        isA<KhatmahDashboardLoaded>(),
      ],
    );

    blocTest<KhatmahBloc, KhatmahState>(
      'emits [Error] on failure',
      build: () {
        when(() => mockRepo.logReading(
              verses: any(named: 'verses'),
              surahs: any(named: 'surahs'),
              durationSeconds: any(named: 'durationSeconds'),
            )).thenAnswer((_) async => const Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const RecordReading(verses: 10, surahs: 1)),
      expect: () => [
        isA<KhatmahError>(),
      ],
    );
  });
}
