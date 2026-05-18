import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/bookmark.dart';
import 'package:hafiz_app/domain/repository/bookmark_repository.dart';
import 'package:hafiz_app/domain/usecase/bookmark/toggle_bookmark.dart';
import 'package:mocktail/mocktail.dart';

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

void main() {
  late ToggleBookmark toggleBookmark;
  late MockBookmarkRepository mockRepository;

  final tBookmark = Bookmark(
    surahId: 1,
    surahName: 'Al-Fatiha',
    verseNumber: 1,
    createdAt: DateTime(2024, 1, 1),
  );

  final tParams = ParamsToggleBookmark(
    surahId: 1,
    verseNumber: 1,
    bookmark: tBookmark,
  );

  setUp(() {
    mockRepository = MockBookmarkRepository();
    toggleBookmark = ToggleBookmark(bookmarkRepository: mockRepository);
  });

  test('should remove bookmark when already bookmarked', () async {
    when(() => mockRepository.isBookmarked(1, 1))
        .thenAnswer((_) async => const Right(true));
    when(() => mockRepository.removeBookmark(1, 1))
        .thenAnswer((_) async => const Right(true));

    final result = await toggleBookmark(tParams);

    expect(result, const Right(true));
    verify(() => mockRepository.isBookmarked(1, 1)).called(1);
    verify(() => mockRepository.removeBookmark(1, 1)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should add bookmark when not bookmarked', () async {
    when(() => mockRepository.isBookmarked(1, 1))
        .thenAnswer((_) async => const Right(false));
    when(() => mockRepository.addBookmark(tBookmark))
        .thenAnswer((_) async => const Right(true));

    final result = await toggleBookmark(tParams);

    expect(result, const Right(true));
    verify(() => mockRepository.isBookmarked(1, 1)).called(1);
    verify(() => mockRepository.addBookmark(tBookmark)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when isBookmarked fails', () async {
    when(() => mockRepository.isBookmarked(1, 1))
        .thenAnswer((_) async => const Left(CacheFailure('error')));

    final result = await toggleBookmark(tParams);

    expect(result, const Left(CacheFailure('error')));
    verify(() => mockRepository.isBookmarked(1, 1)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
