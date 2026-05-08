import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'mushaf_event.dart';
import 'mushaf_state.dart';

class MushafBloc extends Bloc<MushafEvent, MushafState> {
  bool dualPageEnabled;

  MushafBloc({bool? initialDualPage})
    : dualPageEnabled = initialDualPage ?? PrefUtils().getMushafDualPage(),
      super(const MushafInitial()) {
    on<LoadPage>(_onLoadPage);
    on<NavigateToPage>(_onNavigateToPage);
    on<ToggleDualPage>(_onToggleDualPage);
  }

  void _onLoadPage(LoadPage event, Emitter<MushafState> emit) {
    final type = MushafType.fromString(PrefUtils().getMushafType());
    emit(MushafPageLoaded(pageNumber: event.pageNumber, mushafType: type));
  }

  void _onNavigateToPage(NavigateToPage event, Emitter<MushafState> emit) {
    add(LoadPage(event.pageNumber));
  }

  void _onToggleDualPage(ToggleDualPage event, Emitter<MushafState> emit) {
    dualPageEnabled = !dualPageEnabled;
    PrefUtils().setMushafDualPage(dualPageEnabled);
    emit(MushafDualPageToggled(dualPageEnabled));
  }
}
