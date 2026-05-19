import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecase/usecase.dart';

class LogReading implements UseCase<void, ParamsLogReading> {
  final KhatmahRepository khatmahRepository;

  LogReading({required this.khatmahRepository});

  @override
  Future<Either<Failure, void>> call(ParamsLogReading params) async {
    return await khatmahRepository.logReading(
      verses: params.verses,
      surahs: params.surahs,
      durationSeconds: params.durationSeconds,
    );
  }
}

class ParamsLogReading extends Equatable {
  final int verses;
  final int surahs;
  final int durationSeconds;

  const ParamsLogReading({required this.verses, this.surahs = 0, this.durationSeconds = 0});

  @override
  List<Object> get props => [verses, surahs, durationSeconds];
}
