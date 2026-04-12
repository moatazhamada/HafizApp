import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/surah.dart';
import 'package:hafiz_app/domain/entities/verse.dart';

/// Repository interface for Surah data access
abstract class SurahRepository {
  /// Retrieves a single Surah by chapter number
  Future<Either<Failure, Surah>> getSurah(int chapterNumber);

  /// Retrieves all Surahs with their metadata and download status
  Future<Either<Failure, List<Surah>>> getAllSurahs();

  /// Retrieves verses for a specific Surah
  Future<Either<Failure, List<Verse>>> getSurahVerses(int chapterNumber);

  /// Initiates download of a Surah's audio file
  Future<Either<Failure, bool>> downloadSurah(int chapterNumber, int reciterId);

  /// Checks if a Surah's audio is downloaded locally
  Future<Either<Failure, bool>> isSurahDownloaded(int chapterNumber);

  /// Removes a downloaded Surah from local storage
  Future<Either<Failure, bool>> deleteDownloadedSurah(int chapterNumber);
}
