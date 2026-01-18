import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repository/recitation_error_repository.dart';
import '../../datasource/recitation_error/recitation_error_local_data_source.dart';
import '../../model/recitation_error_model.dart';

class RecitationErrorRepositoryImpl implements RecitationErrorRepository {
  final RecitationErrorLocalDataSource localDataSource;

  RecitationErrorRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<RecitationErrorModel>>>
  getRecitationErrors() async {
    try {
      final errors = await localDataSource.getRecitationErrors();
      return Right(errors);
    } on CacheException {
      return Left(CacheFailure('Failed to load recitation errors'));
    }
  }

  @override
  Future<Either<Failure, void>> addRecitationError(
    RecitationErrorModel error,
  ) async {
    try {
      await localDataSource.addRecitationError(error);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure('Failed to save recitation error'));
    }
  }

  @override
  Future<Either<Failure, void>> removeRecitationError(
    int surahId,
    int verseId,
  ) async {
    try {
      await localDataSource.removeRecitationError(surahId, verseId);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure('Failed to remove recitation error'));
    }
  }
}
