part of 'bookmark_bloc.dart';

abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object> get props => [];
}

class BookmarkInitial extends BookmarkState {}

class BookmarkLoading extends BookmarkState {}

class BookmarkLoaded extends BookmarkState {
  final List<BookmarkModel> bookmarks;
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
