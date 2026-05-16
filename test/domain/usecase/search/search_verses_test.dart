import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:hafiz_app/domain/usecase/search/search_verses.dart';
import 'package:mocktail/mocktail.dart';

class MockSurahRepository extends Mock implements SurahRepository {}

void main() {
  late SearchVerses searchVerses;
  late MockSurahRepository mockRepository;

  setUp(() {
    mockRepository = MockSurahRepository();
    searchVerses = SearchVerses(surahRepository: mockRepository);
  });

  const tQuery = 'الله';
  const tParams = ParamsSearchVerses(query: tQuery);

  final tVerses = [
    const Verse(
      chapterNumber: 2,
      verseNumber: 255,
      arabicText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      audioTimestampMs: 0,
    ),
  ];

  test('should return verse results from repository', () async {
    when(() => mockRepository.searchVerses(tQuery))
        .thenAnswer((_) async => Right(tVerses));

    final result = await searchVerses(tParams);

    expect(result, Right(tVerses));
    verify(() => mockRepository.searchVerses(tQuery)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(() => mockRepository.searchVerses(tQuery))
        .thenAnswer((_) async => Left(ServerFailure('error')));

    final result = await searchVerses(tParams);

    expect(result, Left(ServerFailure('error')));
    verify(() => mockRepository.searchVerses(tQuery)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
