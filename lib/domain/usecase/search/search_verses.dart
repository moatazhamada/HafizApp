import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../entities/verse.dart';

class SearchVerses implements UseCase<List<Verse>, ParamsSearchVerses> {
  final SurahRepository surahRepository;

  SearchVerses({required this.surahRepository});

  @override
  Future<Either<Failure, List<Verse>>> call(ParamsSearchVerses params) async {
    return await surahRepository.searchVerses(params.query);
  }
}

class ParamsSearchVerses extends Equatable {
  final String query;

  const ParamsSearchVerses({required this.query});

  @override
  List<Object> get props => [query];
}
