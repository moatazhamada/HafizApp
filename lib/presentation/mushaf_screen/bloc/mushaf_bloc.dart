import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:hafiz_app/data/datasource/mushaf/qf_mushaf_page_data_source.dart';
import 'package:hafiz_app/injection_container.dart';
import 'mushaf_event.dart';
import 'mushaf_state.dart';

class MushafBloc extends Bloc<MushafEvent, MushafState> {
  final QfMushafPageDataSource _dataSource;
  bool dualPageEnabled;

  MushafBloc({
    QfMushafPageDataSource? dataSource,
    bool? initialDualPage,
  }) : _dataSource = dataSource ?? sl<QfMushafPageDataSource>(),
       dualPageEnabled = initialDualPage ?? PrefUtils().getMushafDualPage(),
       super(const MushafInitial()) {
    on<LoadPage>(_onLoadPage);
    on<PrefetchPages>(_onPrefetchPages);
    on<NavigateToPage>(_onNavigateToPage);
    on<ToggleDualPage>(_onToggleDualPage);
    on<RefreshPage>(_onRefreshPage);
  }

  Future<void> _onLoadPage(LoadPage event, Emitter<MushafState> emit) async {
    emit(MushafPageLoading(event.pageNumber));
    try {
      final data = await _dataSource.fetchPage(event.pageNumber);
      if (data != null && data.hasGlyphData) {
        emit(MushafPageLoaded(pageNumber: event.pageNumber, pageData: data));
      } else {
        emit(MushafPageError(
          event.pageNumber,
          'Failed to load page data',
        ));
      }
    } catch (e) {
      emit(MushafPageError(event.pageNumber, e.toString()));
    }
  }

  Future<void> _onPrefetchPages(
    PrefetchPages event,
    Emitter<MushafState> emit,
  ) async {
    final ds = _dataSource;
    await (ds is CachedQfMushafPageDataSource
        ? ds.prefetchPages(event.pageNumbers)
        : Future.value());
  }

  void _onNavigateToPage(NavigateToPage event, Emitter<MushafState> emit) {
    add(LoadPage(event.pageNumber));
  }

  void _onToggleDualPage(ToggleDualPage event, Emitter<MushafState> emit) {
    dualPageEnabled = !dualPageEnabled;
    PrefUtils().setMushafDualPage(dualPageEnabled);
    emit(MushafDualPageToggled(dualPageEnabled));
  }

  Future<void> _onRefreshPage(
    RefreshPage event,
    Emitter<MushafState> emit,
  ) async {
    add(LoadPage(event.pageNumber));
  }
}
