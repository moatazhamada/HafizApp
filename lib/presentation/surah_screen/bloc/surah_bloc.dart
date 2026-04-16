import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/usecase/getsurah/get_surah.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/verse.dart';
import '/core/app_export.dart';

part 'surah_event.dart';

part 'surah_state.dart';

class SurahBloc extends Bloc<SurahEvent, SurahState> {
  final GetSurah getSurah;

  SurahBloc({required this.getSurah})
    : super(const SuccessSurahState(chapters: [])) {
    on<SurahEvent>(_mapGetSurahEventToState);
  }

  void _mapGetSurahEventToState(
    SurahEvent event,
    Emitter<SurahState> emit,
  ) async {
    if (event is LoadSurahEvent) {
      emit(LoadingSurahState());
      var response = await getSurah(ParamsGetSurah(surahId: event.surahId));
      emit(
        response.fold((failure) {
          if (failure is ServerFailure) {
            return const FailureSurahState(errorMessage: 'msg_server_error');
          } else if (failure is ConnectionFailure) {
            return const FailureSurahState(
              errorMessage: 'msg_connection_error',
            );
          } else {
            return InitialSurahState();
          }
        }, (data) => SuccessSurahState(chapters: data)),
      );
    }
  }
}
