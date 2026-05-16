import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/datasource/bookmark/bookmark_local_data_source.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/data/repository/bookmark/bookmark_repository_impl.dart';
import 'package:hafiz_app/domain/entities/bookmark.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:mocktail/mocktail.dart';

class MockBookmarkLocalDataSource extends Mock
    implements BookmarkLocalDataSource {}

class FakeAnalyticsService extends Fake implements AnalyticsService {
  @override
  Future<void> logBookmarkAdded({required int surahId, required int verseNumber}) async {}

  @override
  Future<void> logBookmarkRemoved({required int surahId, required int verseNumber}) async {}
}

class FakeBookmarkModel extends Fake implements BookmarkModel {}

void main() {
  late BookmarkRepositoryImpl repository;
  late MockBookmarkLocalDataSource mockLocalDataSource;

  final tBookmarkModel = BookmarkModel(
    surahId: 1,
    surahName: 'Al-Fatiha',
    verseNumber: 1,
    createdAt: DateTime(2024, 1, 1),
  );

  final tBookmark = Bookmark(
    surahId: 1,
    surahName: 'Al-Fatiha',
    verseNumber: 1,
    createdAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeBookmarkModel());
    sl.registerSingleton<AnalyticsService>(FakeAnalyticsService());
  });

  tearDownAll(() {
    sl.reset();
  });

  setUp(() {
    mockLocalDataSource = MockBookmarkLocalDataSource();
    repository = BookmarkRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: null,
    );
  });

  group('getBookmarks', () {
    test('should return bookmarks from local data source', () async {
      when(() => mockLocalDataSource.getBookmarks())
          .thenAnswer((_) async => [tBookmarkModel]);

      final result = await repository.getBookmarks();

      expect(result.isRight(), true);
      final bookmarks = result.getOrElse(() => []);
      expect(bookmarks.length, 1);
      expect(bookmarks.first.surahId, 1);
      verify(() => mockLocalDataSource.getBookmarks()).called(1);
    });

    test('should return CacheFailure when local data source throws', () async {
      when(() => mockLocalDataSource.getBookmarks()).thenThrow(Exception('error'));

      final result = await repository.getBookmarks();

      expect(result, Left(CacheFailure('Failed to load bookmarks')));
      verify(() => mockLocalDataSource.getBookmarks()).called(1);
    });
  });

  group('addBookmark', () {
    test('should add bookmark to local data source', () async {
      when(() => mockLocalDataSource.addBookmark(any()))
          .thenAnswer((_) async => true);

      final result = await repository.addBookmark(tBookmark);

      expect(result, const Right(true));
      verify(() => mockLocalDataSource.addBookmark(any())).called(1);
    });

    test('should return CacheFailure when local data source throws', () async {
      when(() => mockLocalDataSource.addBookmark(any()))
          .thenThrow(Exception('error'));

      final result = await repository.addBookmark(tBookmark);

      expect(result, Left(CacheFailure('Failed to add bookmark')));
    });
  });

  group('removeBookmark', () {
    test('should remove bookmark from local data source', () async {
      when(() => mockLocalDataSource.removeBookmark(1, 1))
          .thenAnswer((_) async => true);

      final result = await repository.removeBookmark(1, 1);

      expect(result, const Right(true));
      verify(() => mockLocalDataSource.removeBookmark(1, 1)).called(1);
    });

    test('should return CacheFailure when local data source throws', () async {
      when(() => mockLocalDataSource.removeBookmark(1, 1))
          .thenThrow(Exception('error'));

      final result = await repository.removeBookmark(1, 1);

      expect(result, Left(CacheFailure('Failed to remove bookmark')));
    });
  });

  group('isBookmarked', () {
    test('should return true when bookmark exists', () async {
      when(() => mockLocalDataSource.isBookmarked(1, 1))
          .thenAnswer((_) async => true);

      final result = await repository.isBookmarked(1, 1);

      expect(result, const Right(true));
      verify(() => mockLocalDataSource.isBookmarked(1, 1)).called(1);
    });

    test('should return CacheFailure when local data source throws', () async {
      when(() => mockLocalDataSource.isBookmarked(1, 1))
          .thenThrow(Exception('error'));

      final result = await repository.isBookmarked(1, 1);

      expect(result, Left(CacheFailure('Failed to check bookmark status')));
    });
  });
}
