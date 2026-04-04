import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/domain/repository/cloud_sync_repository.dart';

class PerformCloudSync implements UseCase<void, ParamsCloudSync> {
  final CloudSyncRepository repository;

  PerformCloudSync({required this.repository});

  @override
  Future<Either<Failure, void>> call(ParamsCloudSync params) async {
    final authResult = await repository.isAuthenticated();

    return authResult.fold((failure) => Left(failure), (isAuthenticated) async {
      if (!isAuthenticated) {
        final signInResult = await repository.signInAnonymously();
        return signInResult.fold((failure) => Left(failure), (_) async {
          return repository.performFullSync(
            params.userId ?? 'anonymous',
            direction: params.direction,
          );
        });
      }
      return repository.performFullSync(
        params.userId ?? 'anonymous',
        direction: params.direction,
      );
    });
  }
}

class ParamsCloudSync extends Equatable {
  final String? userId;
  final SyncDirection direction;

  const ParamsCloudSync({
    this.userId,
    this.direction = SyncDirection.bidirectional,
  });

  @override
  List<Object?> get props => [userId, direction];
}

class CheckCloudSyncAuth implements UseCase<bool, NoParams> {
  final CloudSyncRepository repository;

  CheckCloudSyncAuth({required this.repository});

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return repository.isAuthenticated();
  }
}

class SignInCloudSync implements UseCase<void, NoParams> {
  final CloudSyncRepository repository;

  SignInCloudSync({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return repository.signInAnonymously();
  }
}

class SignOutCloudSync implements UseCase<void, NoParams> {
  final CloudSyncRepository repository;

  SignOutCloudSync({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return repository.signOut();
  }
}
