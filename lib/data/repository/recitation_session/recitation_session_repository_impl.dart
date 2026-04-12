import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/datasource/recitation_session/recitation_session_local_data_source.dart';
import 'package:hafiz_app/data/model/recitation_session_model.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/domain/repository/recitation_session_repository.dart';

class RecitationSessionRepositoryImpl implements RecitationSessionRepository {
  final RecitationSessionLocalDataSource localDataSource;

  RecitationSessionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<RecitationSession>>> getSessions() async {
    try {
      final sessions = await localDataSource.getSessions();
      return Right(sessions);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addSession(RecitationSession session) async {
    try {
      final model = RecitationSessionModel(
        id: session.id,
        surahId: session.surahId,
        surahName: session.surahName,
        totalVerses: session.totalVerses,
        correctCount: session.correctCount,
        totalCount: session.totalCount,
        score: session.score,
        createdAt: session.createdAt,
      );
      await localDataSource.addSession(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await localDataSource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
