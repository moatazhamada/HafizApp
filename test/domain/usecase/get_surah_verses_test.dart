import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/domain/repository/recitation_repository.dart';
import 'package:hafiz_app/domain/usecase/get_surah_verses.dart';
import 'package:mocktail/mocktail.dart';

class MockRecitationRepository extends Mock implements RecitationRepository {}

void main() {
  late GetSurahVerses getSurahVerses;
  late MockRecitationRepository mockRepository;

  setUp(() {
    mockRepository = MockRecitationRepository();
    getSurahVerses = GetSurahVerses(recitationRepository: mockRepository);
  });

  final testVerses = [
    const Verse(
      chapterNumber: 1,
      verseNumber: 1,
      arabicText: 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
      audioTimestampMs: 0,
    ),
    const Verse(
      chapterNumber: 1,
      verseNumber: 2,
      arabicText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      audioTimestampMs: 1500,
    ),
  ];

  test('should return list of verses on success', () async {
    when(
      () => mockRepository.getSurahVersesWithTimestamps(1, 7),
    ).thenAnswer((_) async => Right(testVerses));

    final result = await getSurahVerses(
      const ParamsGetSurahVerses(chapterNumber: 1, reciterId: 7),
    );

    expect(result, Right(testVerses));
    verify(() => mockRepository.getSurahVersesWithTimestamps(1, 7));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure on failure', () async {
    when(
      () => mockRepository.getSurahVersesWithTimestamps(1, 7),
    ).thenAnswer((_) async => Left(ServerFailure('error')));

    final result = await getSurahVerses(
      const ParamsGetSurahVerses(chapterNumber: 1, reciterId: 7),
    );

    expect(result, Left(ServerFailure('error')));
    verify(() => mockRepository.getSurahVersesWithTimestamps(1, 7));
  });
}
