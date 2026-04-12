import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/verse.dart';

/// Repository interface for audio recitation data
abstract class RecitationRepository {
  /// Retrieves verses with audio timestamps for a Surah
  /// Each verse includes audioTimestampMs for highlighting sync
  Future<Either<Failure, List<Verse>>> getSurahVersesWithTimestamps(
    int chapterNumber,
    int reciterId,
  );

  /// Retrieves the audio URL for a Surah recitation
  Future<Either<Failure, String>> getAudioUrl(int chapterNumber, int reciterId);

  /// Checks if audio is available for a Surah/reciter
  Future<Either<Failure, bool>> isAudioAvailable(
    int chapterNumber,
    int reciterId,
  );
}
