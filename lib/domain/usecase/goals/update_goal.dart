import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';

class UpdateGoal implements UseCase<void, UpdateGoalParams> {
  final QfGoalsRemoteDataSource goalsRemoteDataSource;

  UpdateGoal({required this.goalsRemoteDataSource});

  @override
  Future<Either<Failure, void>> call(UpdateGoalParams params) async {
    try {
      await goalsRemoteDataSource.updateGoal(
        params.id,
        type: params.type,
        amount: params.amount,
        category: params.category,
        duration: params.duration,
        mushafId: params.mushafId,
      );
      return const Right(null);
    } on InsufficientScopeFailure {
      return Left(InsufficientScopeFailure());
    } catch (e) {
      return Left(ServerFailure('$e'));
    }
  }
}

class UpdateGoalParams extends Equatable {
  final String id;
  final String? type;
  final dynamic amount;
  final String? category;
  final int? duration;
  final int? mushafId;

  const UpdateGoalParams({
    required this.id,
    this.type,
    this.amount,
    this.category,
    this.duration,
    this.mushafId,
  });

  @override
  List<Object?> get props => [id, type, amount, category, duration, mushafId];
}
