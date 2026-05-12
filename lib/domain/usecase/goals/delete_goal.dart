import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';

class DeleteGoal implements UseCase<void, DeleteGoalParams> {
  final QfGoalsRemoteDataSource goalsRemoteDataSource;

  DeleteGoal({required this.goalsRemoteDataSource});

  @override
  Future<Either<Failure, void>> call(DeleteGoalParams params) async {
    try {
      await goalsRemoteDataSource.deleteGoal(
        params.id,
        category: params.category,
      );
      return const Right(null);
    } on InsufficientScopeFailure {
      return Left(InsufficientScopeFailure());
    } catch (e) {
      return Left(ServerFailure('$e'));
    }
  }
}

class DeleteGoalParams extends Equatable {
  final String id;
  final String? category;

  const DeleteGoalParams({
    required this.id,
    this.category,
  });

  @override
  List<Object?> get props => [id, category];
}
