import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
import 'package:hafiz_app/domain/usecase/khatmah/log_reading.dart';
import 'package:mocktail/mocktail.dart';

class MockKhatmahRepository extends Mock implements KhatmahRepository {}

void main() {
  late LogReading logReading;
  late MockKhatmahRepository mockRepository;

  setUp(() {
    mockRepository = MockKhatmahRepository();
    logReading = LogReading(khatmahRepository: mockRepository);
  });

  const tParams = ParamsLogReading(verses: 10, surahs: 1);

  test('should call logReading on repository with correct params', () async {
    when(() => mockRepository.logReading(verses: 10, surahs: 1, durationSeconds: 0))
        .thenAnswer((_) async => const Right(null));

    final result = await logReading(tParams);

    expect(result, const Right(null));
    verify(() => mockRepository.logReading(verses: 10, surahs: 1, durationSeconds: 0)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(() => mockRepository.logReading(verses: 10, surahs: 1, durationSeconds: 0))
        .thenAnswer((_) async => Left(CacheFailure('error')));

    final result = await logReading(tParams);

    expect(result, Left(CacheFailure('error')));
    verify(() => mockRepository.logReading(verses: 10, surahs: 1, durationSeconds: 0)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
