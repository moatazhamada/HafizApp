import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'package:hafiz_app/domain/usecase/goals/get_todays_plan.dart';
import 'package:mocktail/mocktail.dart';

class MockQfGoalsRemoteDataSource extends Mock
    implements QfGoalsRemoteDataSource {}

void main() {
  late GetTodaysPlan getTodaysPlan;
  late MockQfGoalsRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockQfGoalsRemoteDataSource();
    getTodaysPlan = GetTodaysPlan(goalsRemoteDataSource: mockDataSource);
  });

  final tPlan = <String, dynamic>{'type': 'QURAN', 'amount': 10};

  test('should return today\'s plan from remote data source', () async {
    when(() => mockDataSource.getTodaysPlan(
      type: any(named: 'type'),
      mushafId: any(named: 'mushafId'),
    )).thenAnswer((_) async => tPlan);

    final result = await getTodaysPlan(const GetTodaysPlanParams(type: 'QURAN'));

    expect(result, Right(tPlan));
    verify(() => mockDataSource.getTodaysPlan(
      type: 'QURAN',
      mushafId: 4,
    )).called(1);
    verifyNoMoreInteractions(mockDataSource);
  });

  test('should return null when no plan exists', () async {
    when(() => mockDataSource.getTodaysPlan(
      type: any(named: 'type'),
      mushafId: any(named: 'mushafId'),
    )).thenAnswer((_) async => null);

    final result = await getTodaysPlan(const GetTodaysPlanParams(type: 'QURAN'));

    expect(result, const Right(null));
    verify(() => mockDataSource.getTodaysPlan(
      type: 'QURAN',
      mushafId: 4,
    )).called(1);
    verifyNoMoreInteractions(mockDataSource);
  });

  test('should return InsufficientScopeFailure when scope is insufficient',
      () async {
    when(() => mockDataSource.getTodaysPlan(
      type: any(named: 'type'),
      mushafId: any(named: 'mushafId'),
    )).thenThrow(const InsufficientScopeFailure());

    final result = await getTodaysPlan(const GetTodaysPlanParams(type: 'QURAN'));

    expect(result, const Left(InsufficientScopeFailure()));
    verify(() => mockDataSource.getTodaysPlan(
      type: 'QURAN',
      mushafId: 4,
    )).called(1);
    verifyNoMoreInteractions(mockDataSource);
  });

  test('should return ServerFailure on unexpected error', () async {
    when(() => mockDataSource.getTodaysPlan(
      type: any(named: 'type'),
      mushafId: any(named: 'mushafId'),
    )).thenThrow(Exception('network error'));

    final result = await getTodaysPlan(const GetTodaysPlanParams(type: 'QURAN'));

    expect(result, isA<Left<Failure, Map<String, dynamic>?>>());
    verify(() => mockDataSource.getTodaysPlan(
      type: 'QURAN',
      mushafId: 4,
    )).called(1);
    verifyNoMoreInteractions(mockDataSource);
  });
}
