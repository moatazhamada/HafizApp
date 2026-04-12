import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/recitation_repository.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecase/usecase.dart';

class GetSurahVerses implements UseCase<List<Verse>, ParamsGetSurahVerses> {
  final RecitationRepository recitationRepository;

  GetSurahVerses({required this.recitationRepository});

  @override
  Future<Either<Failure, List<Verse>>> call(ParamsGetSurahVerses params) async {
    return await recitationRepository.getSurahVersesWithTimestamps(
      params.chapterNumber,
      params.reciterId,
    );
  }
}

class ParamsGetSurahVerses extends Equatable {
  final int chapterNumber;
  final int reciterId;

  const ParamsGetSurahVerses({
    required this.chapterNumber,
    required this.reciterId,
  });

  @override
  List<Object> get props => [chapterNumber, reciterId];

  @override
  String toString() {
    return 'ParamsGetSurahVerses{chapterNumber: $chapterNumber, reciterId: $reciterId}';
  }
}
