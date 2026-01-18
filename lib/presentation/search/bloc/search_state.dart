part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Surah> results;
  final List<Verse> verseResults;

  const SearchLoaded(this.results, {this.verseResults = const []});

  @override
  List<Object> get props => [results, verseResults];
}

class SearchEmpty extends SearchState {
  const SearchEmpty();
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object> get props => [message];
}
