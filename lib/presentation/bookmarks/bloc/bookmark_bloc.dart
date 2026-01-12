import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../data/model/bookmark_model.dart';
import '../../../../domain/repository/bookmark_repository.dart';

part 'bookmark_event.dart';
part 'bookmark_state.dart';

class BookmarkBloc extends Bloc<BookmarkEvent, BookmarkState> {
  final BookmarkRepository repository;

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
    result.fold(
      (failure) => emit(BookmarkError(_mapFailureToMessage(failure))),
      (_) => add(LoadBookmarksEvent(feedbackMessage: "Added to bookmarks")),
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
    result.fold(
      (failure) => emit(BookmarkError(_mapFailureToMessage(failure))),
      (_) => add(LoadBookmarksEvent(feedbackMessage: "Removed from bookmarks")),
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
    return "Unexpected Error";
  }
}
