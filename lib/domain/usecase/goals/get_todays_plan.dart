import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';

class GetTodaysPlan implements UseCase<Map<String, dynamic>?, GetTodaysPlanParams> {
  final QfGoalsRemoteDataSource goalsRemoteDataSource;

  GetTodaysPlan({required this.goalsRemoteDataSource});

  @override
  Future<Either<Failure, Map<String, dynamic>?>> call(
    GetTodaysPlanParams params,
  ) async {
    try {
      final result = await goalsRemoteDataSource.getTodaysPlan(
        type: params.type,
        mushafId: params.mushafId,
      );
      return Right(result);
    } on InsufficientScopeFailure {
      return const Left(InsufficientScopeFailure());
    } catch (e) {
      return Left(ServerFailure('$e'));
    }
  }
}

class GetTodaysPlanParams extends Equatable {
  final String? type;
  final int mushafId;

  const GetTodaysPlanParams({this.type, this.mushafId = 4});

  @override
  List<Object?> get props => [type, mushafId];
}
