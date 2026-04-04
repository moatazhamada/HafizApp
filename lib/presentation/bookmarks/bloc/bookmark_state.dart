part of 'bookmark_bloc.dart';

abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object> get props => [];
}

class BookmarkInitial extends BookmarkState {
  const BookmarkInitial();
}

class BookmarkLoading extends BookmarkState {
  const BookmarkLoading();
}

class BookmarkLoaded extends BookmarkState {
  final List<Bookmark> bookmarks;
  final String? feedbackMessage;

  const BookmarkLoaded(this.bookmarks, {this.feedbackMessage});

  @override
  List<Object> get props => [bookmarks, feedbackMessage ?? ''];
}

class BookmarkError extends BookmarkState {
  final String message;

  const BookmarkError(this.message);

  @override
  List<Object> get props => [message];
}
