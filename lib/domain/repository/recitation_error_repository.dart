import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/model/recitation_error_model.dart';

abstract class RecitationErrorRepository {
  Future<Either<Failure, List<RecitationErrorModel>>> getRecitationErrors();
  Future<Either<Failure, void>> addRecitationError(RecitationErrorModel error);
  Future<Either<Failure, void>> removeRecitationError(int surahId, int verseId);
}
