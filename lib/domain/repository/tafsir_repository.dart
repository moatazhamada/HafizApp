import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/tafsir_entry.dart';

abstract class TafsirRepository {
  Future<Either<Failure, TafsirEntry>> getTafsir(
    int surahNumber,
    int verseNumber,
  );
}
