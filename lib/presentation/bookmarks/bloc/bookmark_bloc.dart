import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/analytics/analytics_helper.dart';
import '../../../../data/model/bookmark_model.dart';
import '../../../../domain/repository/bookmark_repository.dart';
import '../../../../injection_container.dart';

import '../../../../domain/entities/bookmark.dart';

part 'bookmark_event.dart';
part 'bookmark_state.dart';

class BookmarkBloc extends Bloc<BookmarkEvent, BookmarkState> {
  final BookmarkRepository repository;
  final _analytics = sl<AnalyticsHelper>();

  BookmarkBloc({required this.repository}) : super(BookmarkInitial()) {
    on<LoadBookmarksEvent>(_onLoadBookmarks);
    on<AddBookmarkEvent>(_onAddBookmark);
    on<RemoveBookmarkEvent>(_onRemoveBookmark);
  }

  Future<void> _onLoadBookmarks(
    LoadBookmarksEvent event,
    Emitter<BookmarkState> emit,
  ) async {
    emit(BookmarkLoading());
    final result = await repository.getBookmarks();
    result.fold(
      (failure) => emit(BookmarkError(_mapFailureToMessage(failure))),
      (bookmarks) => emit(
        BookmarkLoaded(bookmarks, feedbackMessage: event.feedbackMessage),
      ),
    );
  }

  Future<void> _onAddBookmark(
    AddBookmarkEvent event,
    Emitter<BookmarkState> emit,
  ) async {
    final result = await repository.addBookmark(event.bookmark);
    await result.fold(
      (failure) async => emit(BookmarkError(_mapFailureToMessage(failure))),
      (_) async {
        // Log analytics
        _analytics.logBookmarkAdded(
          event.bookmark.surahId,
          event.bookmark.verseNumber,
        );
        // Reload bookmarks directly instead of adding event to avoid recursion
        final loadResult = await repository.getBookmarks();
        loadResult.fold(
          (failure) => emit(BookmarkError(_mapFailureToMessage(failure))),
          (bookmarks) => emit(
            BookmarkLoaded(bookmarks, feedbackMessage: 'msg_bookmark_added'),
          ),
        );
      },
    );
  }

  Future<void> _onRemoveBookmark(
    RemoveBookmarkEvent event,
    Emitter<BookmarkState> emit,
  ) async {
    final result = await repository.removeBookmark(
      event.surahId,
      event.verseId,
    );
    await result.fold(
      (failure) async => emit(BookmarkError(_mapFailureToMessage(failure))),
      (_) async {
        // Log analytics
        _analytics.logBookmarkRemoved(event.surahId, event.verseId);
        // Reload bookmarks directly instead of adding event to avoid recursion
        final loadResult = await repository.getBookmarks();
        loadResult.fold(
          (failure) => emit(BookmarkError(_mapFailureToMessage(failure))),
          (bookmarks) => emit(
            BookmarkLoaded(bookmarks, feedbackMessage: 'msg_bookmark_removed'),
          ),
        );
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.errorMessage;
    } else if (failure is CacheFailure) {
      return failure.errorMessage;
    } else if (failure is ConnectionFailure) {
      return failure.errorMessage;
    }
    return 'Unexpected Error';
  }
}
