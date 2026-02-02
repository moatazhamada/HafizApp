import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/verse.dart';

abstract class SurahRepository {
  Future<Either<Failure, List<Verse>>> getSurah(String surahId);
  Future<Either<Failure, List<Verse>>> searchVerses(String query);
}
