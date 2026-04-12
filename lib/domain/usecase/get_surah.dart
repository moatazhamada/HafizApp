import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/surah.dart';
import 'package:hafiz_app/domain/repository/surah_repository.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecase/usecase.dart';

class GetSurah implements UseCase<Surah, ParamsGetSurah> {
  final SurahRepository surahRepository;

  GetSurah({required this.surahRepository});

  @override
  Future<Either<Failure, Surah>> call(ParamsGetSurah params) async {
    return await surahRepository.getSurah(params.chapterNumber);
  }
}

class ParamsGetSurah extends Equatable {
  final int chapterNumber;

  const ParamsGetSurah({required this.chapterNumber});

  @override
  List<Object> get props => [chapterNumber];

  @override
  String toString() {
    return 'ParamsGetSurah{chapterNumber: $chapterNumber}';
  }
}
