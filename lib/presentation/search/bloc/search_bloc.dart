import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      final query = event.query.toLowerCase();
      final results = QuranIndex.quranSurahs.where((surah) {
        final matchesEnglish = surah.nameEnglish.toLowerCase().contains(query);
        final matchesArabic = surah.nameArabic.contains(query);
        final matchesId = surah.id.toString().contains(query);
        return matchesEnglish || matchesArabic || matchesId;
      }).toList();

      if (results.isEmpty) {
        emit(const SearchEmpty());
      } else {
        emit(SearchLoaded(results));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
