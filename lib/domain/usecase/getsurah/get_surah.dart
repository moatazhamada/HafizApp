import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../entities/verse.dart';

class GetSurah implements UseCase<List<Verse>, ParamsGetSurah> {
  final SurahRepository surahRepository;

  GetSurah({required this.surahRepository});

  @override
  Future<Either<Failure, List<Verse>>> call(ParamsGetSurah params) async {
    return await surahRepository.getSurah(params.surahId);
  }
}

class ParamsGetSurah extends Equatable {
  final String surahId;

  const ParamsGetSurah({required this.surahId});

  @override
  List<Object> get props => [surahId];

  @override
  String toString() {
    return 'ParamsGetSurah{surahId: $surahId}';
  }
}
