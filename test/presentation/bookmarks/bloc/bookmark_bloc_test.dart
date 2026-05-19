import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/domain/entities/bookmark.dart';
import 'package:hafiz_app/domain/repository/bookmark_repository.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

class FakeBookmark extends Fake implements Bookmark {}

void main() {
  late MockBookmarkRepository mockRepository;
  late BookmarkBloc bookmarkBloc;

  final testBookmark = BookmarkModel(
    surahId: 1,
    surahName: 'Al-Fatiha',
    verseNumber: 1,
    createdAt: DateTime(2024, 1, 1),
  );

  final testBookmarks = [testBookmark];

  setUpAll(() {
    registerFallbackValue(FakeBookmark());
  });

  setUp(() {
    mockRepository = MockBookmarkRepository();
    bookmarkBloc = BookmarkBloc(repository: mockRepository);
  });

  tearDown(() => bookmarkBloc.close());

  test('initial state is BookmarkInitial', () {
    expect(bookmarkBloc.state, isA<BookmarkInitial>());
  });

  group('LoadBookmarksEvent', () {
    blocTest<BookmarkBloc, BookmarkState>(
      'emits [BookmarkLoading, BookmarkLoaded] when loading succeeds',
      build: () {
        when(() => mockRepository.getBookmarks())
            .thenAnswer((_) async => Right(testBookmarks));
        return bookmarkBloc;
      },
      act: (bloc) => bloc.add(const LoadBookmarksEvent()),
      expect: () => [
        isA<BookmarkLoading>(),
        isA<BookmarkLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepository.getBookmarks()).called(1);
      },
    );

    blocTest<BookmarkBloc, BookmarkState>(
      'emits [BookmarkLoading, BookmarkLoaded] with feedback message',
      build: () {
        when(() => mockRepository.getBookmarks())
            .thenAnswer((_) async => Right(testBookmarks));
        return bookmarkBloc;
      },
      act: (bloc) =>
          bloc.add(const LoadBookmarksEvent(feedbackMessage: 'Test message')),
      expect: () => [
        isA<BookmarkLoading>(),
        predicate<BookmarkState>((state) =>
            state is BookmarkLoaded && state.feedbackMessage == 'Test message'),
      ],
    );

    blocTest<BookmarkBloc, BookmarkState>(
      'emits [BookmarkLoading, BookmarkError] when loading fails',
      build: () {
        when(() => mockRepository.getBookmarks())
            .thenAnswer((_) async => const Left(CacheFailure('Cache error')));
        return bookmarkBloc;
      },
      act: (bloc) => bloc.add(const LoadBookmarksEvent()),
      expect: () => [
        isA<BookmarkLoading>(),
        isA<BookmarkError>(),
      ],
    );
  });

  group('AddBookmarkEvent', () {
    blocTest<BookmarkBloc, BookmarkState>(
      'emits [BookmarkLoading, BookmarkLoaded] when adding succeeds',
      build: () {
        when(() => mockRepository.addBookmark(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockRepository.getBookmarks())
            .thenAnswer((_) async => Right(testBookmarks));
        return bookmarkBloc;
      },
      act: (bloc) => bloc.add(AddBookmarkEvent(testBookmark)),
      expect: () => [
        isA<BookmarkLoading>(),
        predicate<BookmarkState>((state) =>
            state is BookmarkLoaded &&
            state.feedbackMessage == 'msg_bookmark_added'),
      ],
      verify: (_) {
        verify(() => mockRepository.addBookmark(any())).called(1);
        verify(() => mockRepository.getBookmarks()).called(1);
      },
    );

    blocTest<BookmarkBloc, BookmarkState>(
      'emits [BookmarkError] when adding fails',
      build: () {
        when(() => mockRepository.addBookmark(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Add failed')));
        return bookmarkBloc;
      },
      act: (bloc) => bloc.add(AddBookmarkEvent(testBookmark)),
      expect: () => [
        isA<BookmarkError>(),
      ],
    );
  });

  group('RemoveBookmarkEvent', () {
    blocTest<BookmarkBloc, BookmarkState>(
      'emits [BookmarkLoading, BookmarkLoaded] when removing succeeds',
      build: () {
        when(() => mockRepository.removeBookmark(any(), any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockRepository.getBookmarks())
            .thenAnswer((_) async => const Right([]));
        return bookmarkBloc;
      },
      act: (bloc) => bloc.add(const RemoveBookmarkEvent(1, 1)),
      expect: () => [
        isA<BookmarkLoading>(),
        predicate<BookmarkState>((state) =>
            state is BookmarkLoaded &&
            state.feedbackMessage == 'msg_bookmark_removed'),
      ],
      verify: (_) {
        verify(() => mockRepository.removeBookmark(1, 1)).called(1);
        verify(() => mockRepository.getBookmarks()).called(1);
      },
    );

    blocTest<BookmarkBloc, BookmarkState>(
      'emits [BookmarkError] when removing fails',
      build: () {
        when(() => mockRepository.removeBookmark(any(), any()))
            .thenAnswer((_) async => const Left(CacheFailure('Remove failed')));
        return bookmarkBloc;
      },
      act: (bloc) => bloc.add(const RemoveBookmarkEvent(1, 1)),
      expect: () => [
        isA<BookmarkError>(),
      ],
    );
  });
}
