import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/domain/entities/bookmark.dart';
import 'package:hafiz_app/domain/repository/bookmark_repository.dart';
import 'package:hafiz_app/domain/usecase/bookmark/load_bookmarks.dart';
import 'package:mocktail/mocktail.dart';

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

void main() {
  late LoadBookmarks loadBookmarks;
  late MockBookmarkRepository mockRepository;

  final tBookmarks = [
    Bookmark(
      surahId: 1,
      surahName: 'Al-Fatiha',
      verseNumber: 1,
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  setUp(() {
    mockRepository = MockBookmarkRepository();
    loadBookmarks = LoadBookmarks(bookmarkRepository: mockRepository);
  });

  test('should return list of bookmarks from repository', () async {
    when(() => mockRepository.getBookmarks())
        .thenAnswer((_) async => Right(tBookmarks));

    final result = await loadBookmarks(NoParams());

    expect(result, Right(tBookmarks));
    verify(() => mockRepository.getBookmarks()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(() => mockRepository.getBookmarks())
        .thenAnswer((_) async => const Left(CacheFailure('error')));

    final result = await loadBookmarks(NoParams());

    expect(result, const Left(CacheFailure('error')));
    verify(() => mockRepository.getBookmarks()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
