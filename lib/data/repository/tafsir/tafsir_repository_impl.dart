import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/data/datasource/tafsir/tafsir_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/tafsir/qf_tafsir_remote_data_source.dart';
import 'package:hafiz_app/domain/entities/tafsir_entry.dart';
import 'package:hafiz_app/domain/repository/tafsir_repository.dart';

class TafsirRepositoryImpl implements TafsirRepository {
  final TafsirRemoteDataSource remoteDataSource;
  final QfTafsirRemoteDataSource? qfTafsirRemoteDataSource;

  TafsirRepositoryImpl({
    required this.remoteDataSource,
    this.qfTafsirRemoteDataSource,
  });

  @override
  Future<Either<Failure, TafsirEntry>> getTafsir(
    int surahNumber,
    int verseNumber,
  ) async {
    final verseKey = '$surahNumber:$verseNumber';

    if (qfTafsirRemoteDataSource != null) {
      try {
        final text = await qfTafsirRemoteDataSource!.getTafsirForVerse(
          verseKey,
        );
        return Right(
          TafsirEntry(
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            text: text,
            sourceName: 'QF Ibn Kathir',
          ),
        );
      } catch (e) {
        Logger.info(
          'QF tafsir failed, falling back to Quran.com: $e',
          feature: 'Tafsir',
        );
      }
    }

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
