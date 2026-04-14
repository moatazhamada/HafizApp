import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/datasource/tafsir/tafsir_remote_data_source.dart';
import 'package:hafiz_app/domain/entities/tafsir_entry.dart';
import 'package:hafiz_app/domain/repository/tafsir_repository.dart';

class TafsirRepositoryImpl implements TafsirRepository {
  final TafsirRemoteDataSource remoteDataSource;

  TafsirRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, TafsirEntry>> getTafsir(
    int surahNumber,
    int verseNumber,
  ) async {
    try {
      final text = await remoteDataSource.getTafsir(surahNumber, verseNumber);
      return Right(
        TafsirEntry(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          text: text,
          sourceName: 'Ibn Kathir',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
