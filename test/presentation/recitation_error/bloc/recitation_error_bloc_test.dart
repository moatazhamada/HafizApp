import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/domain/repository/recitation_error_repository.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockRecitationErrorRepository extends Mock
    implements RecitationErrorRepository {}

class FakeRecitationErrorModel extends Fake implements RecitationErrorModel {}

void main() {
  late MockRecitationErrorRepository mockRepository;
  late RecitationErrorBloc recitationErrorBloc;

  final testError = RecitationErrorModel(
    surahId: 1,
    surahName: 'Al-Fatiha',
    verseId: 1,
    createdAt: DateTime(2024, 1, 1),
  );

  final testErrors = [testError];

  setUpAll(() {
    registerFallbackValue(FakeRecitationErrorModel());
  });

  setUp(() {
    mockRepository = MockRecitationErrorRepository();
    recitationErrorBloc = RecitationErrorBloc(repository: mockRepository);
  });

  tearDown(() => recitationErrorBloc.close());

  test('initial state is RecitationErrorInitial', () {
    expect(recitationErrorBloc.state, isA<RecitationErrorInitial>());
  });

  group('LoadRecitationErrorsEvent', () {
    blocTest<RecitationErrorBloc, RecitationErrorState>(
      'emits [RecitationErrorLoading, RecitationErrorLoaded] when loading succeeds',
      build: () {
        when(() => mockRepository.getRecitationErrors())
            .thenAnswer((_) async => Right(testErrors));
        return recitationErrorBloc;
      },
      act: (bloc) => bloc.add(const LoadRecitationErrorsEvent()),
      expect: () => [
        isA<RecitationErrorLoading>(),
        isA<RecitationErrorLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepository.getRecitationErrors()).called(1);
      },
    );

    blocTest<RecitationErrorBloc, RecitationErrorState>(
      'emits [RecitationErrorLoading, RecitationErrorLoaded] with feedback message',
      build: () {
        when(() => mockRepository.getRecitationErrors())
            .thenAnswer((_) async => Right(testErrors));
        return recitationErrorBloc;
      },
      act: (bloc) => bloc.add(
          const LoadRecitationErrorsEvent(feedbackMessage: 'Test message')),
      expect: () => [
        isA<RecitationErrorLoading>(),
        predicate<RecitationErrorState>((state) =>
            state is RecitationErrorLoaded &&
            state.feedbackMessage == 'Test message'),
      ],
    );

    blocTest<RecitationErrorBloc, RecitationErrorState>(
      'emits [RecitationErrorLoading, RecitationErrorError] when loading fails',
      build: () {
        when(() => mockRepository.getRecitationErrors())
            .thenAnswer((_) async => const Left(CacheFailure('Cache error')));
        return recitationErrorBloc;
      },
      act: (bloc) => bloc.add(const LoadRecitationErrorsEvent()),
      expect: () => [
        isA<RecitationErrorLoading>(),
        isA<RecitationErrorError>(),
      ],
    );
  });

  group('AddRecitationErrorEvent', () {
    blocTest<RecitationErrorBloc, RecitationErrorState>(
      'emits [RecitationErrorLoading, RecitationErrorLoaded] when adding succeeds',
      build: () {
        when(() => mockRepository.addRecitationError(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.getRecitationErrors())
            .thenAnswer((_) async => Right(testErrors));
        return recitationErrorBloc;
      },
      act: (bloc) => bloc.add(AddRecitationErrorEvent(testError)),
      expect: () => [
        isA<RecitationErrorLoading>(),
        predicate<RecitationErrorState>((state) =>
            state is RecitationErrorLoaded &&
            state.feedbackMessage == 'msg_marked_error'),
      ],
      verify: (_) {
        verify(() => mockRepository.addRecitationError(any())).called(1);
        verify(() => mockRepository.getRecitationErrors()).called(1);
      },
    );

    blocTest<RecitationErrorBloc, RecitationErrorState>(
      'emits [RecitationErrorError] when adding fails',
      build: () {
        when(() => mockRepository.addRecitationError(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Add failed')));
        return recitationErrorBloc;
      },
      act: (bloc) => bloc.add(AddRecitationErrorEvent(testError)),
      expect: () => [
        isA<RecitationErrorError>(),
      ],
    );
  });

  group('RemoveRecitationErrorEvent', () {
    blocTest<RecitationErrorBloc, RecitationErrorState>(
      'emits [RecitationErrorLoading, RecitationErrorLoaded] when removing succeeds',
      build: () {
        when(() => mockRepository.removeRecitationError(any(), any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.getRecitationErrors())
            .thenAnswer((_) async => const Right([]));
        return recitationErrorBloc;
      },
      act: (bloc) => bloc.add(const RemoveRecitationErrorEvent(1, 1)),
      expect: () => [
        isA<RecitationErrorLoading>(),
        predicate<RecitationErrorState>((state) =>
            state is RecitationErrorLoaded &&
            state.feedbackMessage == 'msg_error_removed'),
      ],
      verify: (_) {
        verify(() => mockRepository.removeRecitationError(1, 1)).called(1);
        verify(() => mockRepository.getRecitationErrors()).called(1);
      },
    );

    blocTest<RecitationErrorBloc, RecitationErrorState>(
      'emits [RecitationErrorError] when removing fails',
      build: () {
        when(() => mockRepository.removeRecitationError(any(), any()))
            .thenAnswer((_) async => const Left(CacheFailure('Remove failed')));
        return recitationErrorBloc;
      },
      act: (bloc) => bloc.add(const RemoveRecitationErrorEvent(1, 1)),
      expect: () => [
        isA<RecitationErrorError>(),
      ],
    );
  });
}
