import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/domain/repository/recitation_error_repository.dart';
import 'package:hafiz_app/domain/repository/recitation_session_repository.dart';
import 'package:hafiz_app/presentation/tajweed_roadmap/bloc/tajweed_roadmap_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockRecitationSessionRepository extends Mock
    implements RecitationSessionRepository {}
class MockRecitationErrorRepository extends Mock
    implements RecitationErrorRepository {}

final testSession = RecitationSession(
  id: '1_1000',
  surahId: 1,
  surahName: 'Al-Fatiha',
  totalVerses: 7,
  correctCount: 5,
  totalCount: 7,
  score: 71.4,
  createdAt: DateTime(2024, 1, 1),
);

final testError = RecitationErrorModel(
  surahId: 1,
  surahName: 'Al-Fatiha',
  verseId: 5,
  createdAt: DateTime(2024, 1, 1),
);

void main() {
  late MockRecitationSessionRepository mockSessionRepo;
  late MockRecitationErrorRepository mockErrorRepo;
  late TajweedRoadmapBloc bloc;

  setUp(() {
    mockSessionRepo = MockRecitationSessionRepository();
    mockErrorRepo = MockRecitationErrorRepository();
    bloc = TajweedRoadmapBloc(
      sessionRepository: mockSessionRepo,
      errorRepository: mockErrorRepo,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is TajweedRoadmapInitial', () {
    expect(bloc.state, isA<TajweedRoadmapInitial>());
  });

  group('LoadTajweedRoadmap', () {
    blocTest<TajweedRoadmapBloc, TajweedRoadmapState>(
      'emits [Loading, Loaded] with progress on success',
      build: () {
        when(() => mockSessionRepo.getSessions())
            .thenAnswer((_) async => Right([testSession]));
        when(() => mockErrorRepo.getRecitationErrors())
            .thenAnswer((_) async => Right([testError]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTajweedRoadmap()),
      expect: () => [
        isA<TajweedRoadmapLoading>(),
        predicate<TajweedRoadmapState>((s) =>
            s is TajweedRoadmapLoaded &&
            s.progress.totalSessions == 1 &&
            s.progress.totalMistakes == 1),
      ],
    );

    blocTest<TajweedRoadmapBloc, TajweedRoadmapState>(
      'emits [Loading, Loaded] with empty data when no sessions/errors',
      build: () {
        when(() => mockSessionRepo.getSessions())
            .thenAnswer((_) async => const Right([]));
        when(() => mockErrorRepo.getRecitationErrors())
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTajweedRoadmap()),
      expect: () => [
        isA<TajweedRoadmapLoading>(),
        predicate<TajweedRoadmapState>(
            (s) => s is TajweedRoadmapLoaded && s.progress.totalSessions == 0),
      ],
    );

    blocTest<TajweedRoadmapBloc, TajweedRoadmapState>(
      'degrades gracefully when session repo fails',
      build: () {
        when(() => mockSessionRepo.getSessions())
            .thenAnswer((_) async => const Left(CacheFailure('fail')));
        when(() => mockErrorRepo.getRecitationErrors())
            .thenAnswer((_) async => Right([testError]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTajweedRoadmap()),
      expect: () => [
        isA<TajweedRoadmapLoading>(),
        predicate<TajweedRoadmapState>(
            (s) => s is TajweedRoadmapLoaded && s.progress.totalSessions == 0),
      ],
    );
  });
}
