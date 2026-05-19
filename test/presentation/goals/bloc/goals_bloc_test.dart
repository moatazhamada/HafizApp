import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/usecase/goals/get_todays_plan.dart';
import 'package:hafiz_app/domain/usecase/goals/update_goal.dart';
import 'package:hafiz_app/domain/usecase/goals/delete_goal.dart';
import 'package:hafiz_app/presentation/goals/bloc/goals_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTodaysPlan extends Mock implements GetTodaysPlan {}

class MockUpdateGoal extends Mock implements UpdateGoal {}

class MockDeleteGoal extends Mock implements DeleteGoal {}

void main() {
  late MockGetTodaysPlan mockUseCase;
  late MockUpdateGoal mockUpdateGoal;
  late MockDeleteGoal mockDeleteGoal;
  late GoalsBloc bloc;

  setUp(() {
    mockUseCase = MockGetTodaysPlan();
    mockUpdateGoal = MockUpdateGoal();
    mockDeleteGoal = MockDeleteGoal();
    bloc = GoalsBloc(
      getTodaysPlan: mockUseCase,
      updateGoal: mockUpdateGoal,
      deleteGoal: mockDeleteGoal,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is GoalsInitial', () {
    expect(bloc.state, isA<GoalsInitial>());
  });

  group('LoadTodaysPlan', () {
    void mockAllTypes(Right<Failure, Map<String, dynamic>?> result) {
      for (final type in const ['QURAN_TIME', 'QURAN_PAGES', 'QURAN_RANGE']) {
        when(() => mockUseCase(GetTodaysPlanParams(type: type)))
            .thenAnswer((_) async => result);
      }
    }

    void mockAllTypesLeft(Left<Failure, Map<String, dynamic>?> result) {
      for (final type in const ['QURAN_TIME', 'QURAN_PAGES', 'QURAN_RANGE']) {
        when(() => mockUseCase(GetTodaysPlanParams(type: type)))
            .thenAnswer((_) async => result);
      }
    }

    blocTest<GoalsBloc, GoalsState>(
      'emits [Loading, Loaded] on success with parsed items',
      build: () {
        when(() => mockUseCase(const GetTodaysPlanParams(type: 'QURAN_TIME')))
            .thenAnswer((_) async => const Right(null));
        when(() => mockUseCase(const GetTodaysPlanParams(type: 'QURAN_PAGES')))
            .thenAnswer((_) async => const Right({
                  'plan': [
                    {
                      'id': '1',
                      'type': 'QURAN_RANGE',
                      'amount': '1:1-1:7',
                      'category': 'QURAN',
                      'name': 'Al-Fatiha',
                      'progress': 3,
                      'duration': 7,
                    }
                  ]
                }));
        when(() => mockUseCase(const GetTodaysPlanParams(type: 'QURAN_RANGE')))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadTodaysPlan()),
      expect: () => [
        isA<GoalsLoading>(),
        predicate<GoalsState>((s) =>
            s is GoalsLoaded &&
            s.items.length == 1 &&
            s.items.first.id == '1'),
      ],
    );

    blocTest<GoalsBloc, GoalsState>(
      'emits [Loading, Loaded] with empty items for null data',
      build: () {
        mockAllTypes(const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadTodaysPlan()),
      expect: () => [
        isA<GoalsLoading>(),
        predicate<GoalsState>(
            (s) => s is GoalsLoaded && s.items.isEmpty),
      ],
    );

    blocTest<GoalsBloc, GoalsState>(
      'emits [Loading, Error] on InsufficientScopeFailure',
      build: () {
        mockAllTypesLeft(const Left(InsufficientScopeFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadTodaysPlan()),
      expect: () => [
        isA<GoalsLoading>(),
        predicate<GoalsState>(
            (s) => s is GoalsError && s.message == 'msg_re_login_required'),
      ],
    );

    blocTest<GoalsBloc, GoalsState>(
      'emits [Loading, Error] on generic failure',
      build: () {
        mockAllTypesLeft(const Left(ServerFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadTodaysPlan()),
      expect: () => [
        isA<GoalsLoading>(),
        isA<GoalsError>(),
      ],
    );
  });
}
