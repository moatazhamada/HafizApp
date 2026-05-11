import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/domain/repository/recitation_session_repository.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_bloc.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_event.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_state.dart';
import 'package:mocktail/mocktail.dart';

class MockRecitationSessionRepository extends Mock
    implements RecitationSessionRepository {}
class FakeRecitationSession extends Fake implements RecitationSession {}

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

void main() {
  late MockRecitationSessionRepository mockRepo;
  late RecitationSessionBloc bloc;

  setUpAll(() {
    registerFallbackValue(FakeRecitationSession());
  });

  setUp(() {
    mockRepo = MockRecitationSessionRepository();
    bloc = RecitationSessionBloc(repository: mockRepo);
  });

  tearDown(() => bloc.close());

  test('initial state is RecitationSessionInitial', () {
    expect(bloc.state, isA<RecitationSessionInitial>());
  });

  group('LoadSessions', () {
    blocTest<RecitationSessionBloc, RecitationSessionState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => mockRepo.getSessions())
            .thenAnswer((_) async => Right([testSession]));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadSessions()),
      expect: () => [
        isA<RecitationSessionLoading>(),
        predicate<RecitationSessionState>(
            (s) => s is RecitationSessionLoaded && s.sessions.length == 1),
      ],
    );

    blocTest<RecitationSessionBloc, RecitationSessionState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepo.getSessions())
            .thenAnswer((_) async => Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadSessions()),
      expect: () => [
        isA<RecitationSessionLoading>(),
        isA<RecitationSessionError>(),
      ],
    );
  });

  group('SaveSession', () {
    blocTest<RecitationSessionBloc, RecitationSessionState>(
      'reloads sessions on success',
      build: () {
        when(() => mockRepo.addSession(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepo.getSessions())
            .thenAnswer((_) async => Right([testSession]));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveSession(testSession)),
      expect: () => [
        isA<RecitationSessionLoading>(),
        isA<RecitationSessionLoaded>(),
      ],
    );

    blocTest<RecitationSessionBloc, RecitationSessionState>(
      'emits [Error] on failure',
      build: () {
        when(() => mockRepo.addSession(any()))
            .thenAnswer((_) async => Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveSession(testSession)),
      expect: () => [
        isA<RecitationSessionError>(),
      ],
    );
  });

  group('ClearAllSessions', () {
    blocTest<RecitationSessionBloc, RecitationSessionState>(
      'reloads sessions on success',
      build: () {
        when(() => mockRepo.clearAll())
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepo.getSessions())
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(ClearAllSessions()),
      expect: () => [
        isA<RecitationSessionLoading>(),
        isA<RecitationSessionLoaded>(),
      ],
    );
  });
}
