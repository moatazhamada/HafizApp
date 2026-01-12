part of 'bookmark_bloc.dart';

abstract class BookmarkEvent extends Equatable {
  const BookmarkEvent();

  @override
  List<Object> get props => [];
}

class LoadBookmarksEvent extends BookmarkEvent {
  final String? feedbackMessage;

  const LoadBookmarksEvent({this.feedbackMessage});

  @override
  List<Object> get props => [feedbackMessage ?? ''];
}

class AddBookmarkEvent extends BookmarkEvent {
  final BookmarkModel bookmark;

  const AddBookmarkEvent(this.bookmark);

  @override
  List<Object> get props => [bookmark];
}

class RemoveBookmarkEvent extends BookmarkEvent {
  final int surahId;
  final int verseId;

  const RemoveBookmarkEvent(this.surahId, this.verseId);

  @override
  List<Object> get props => [surahId, verseId];
}
