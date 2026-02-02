import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
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
    } on CacheException catch (e, stackTrace) {
      Logger.error(
        'Failed to load recitation errors: $e',
        feature: 'RecitationErrors',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to load recitation errors'));
    } catch (e, stackTrace) {
      Logger.error(
        'Unexpected error loading recitation errors: $e',
        feature: 'RecitationErrors',
        error: e,
        stackTrace: stackTrace,
      );
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
    } on CacheException catch (e, stackTrace) {
      Logger.error(
        'Failed to save recitation error: $e',
        feature: 'RecitationErrors',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to save recitation error'));
    } catch (e, stackTrace) {
      Logger.error(
        'Unexpected error saving recitation error: $e',
        feature: 'RecitationErrors',
        error: e,
        stackTrace: stackTrace,
      );
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
    } on CacheException catch (e, stackTrace) {
      Logger.error(
        'Failed to remove recitation error: $e',
        feature: 'RecitationErrors',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to remove recitation error'));
    } catch (e, stackTrace) {
      Logger.error(
        'Unexpected error removing recitation error: $e',
        feature: 'RecitationErrors',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to remove recitation error'));
    }
  }
}