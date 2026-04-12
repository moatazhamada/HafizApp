import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';

abstract class RecitationSessionRepository {
  Future<Either<Failure, List<RecitationSession>>> getSessions();
  Future<Either<Failure, void>> addSession(RecitationSession session);
  Future<Either<Failure, void>> clearAll();
}
