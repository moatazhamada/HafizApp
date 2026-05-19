import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/surface_type.dart';
import '../../../core/utils/pref_utils.dart';

part 'adaptive_home_event.dart';
part 'adaptive_home_state.dart';

class AdaptiveHomeBloc extends Bloc<AdaptiveHomeEvent, AdaptiveHomeState> {
  AdaptiveHomeBloc() : super(AdaptiveHomeState.initial()) {
    on<AdaptiveHomeLoad>(_onLoad);
    on<AdaptiveHomeChangeSurface>(_onChangeSurface);
    on<AdaptiveHomeDismissSuggestion>(_onDismissSuggestion);
  }

  void _onLoad(AdaptiveHomeLoad event, Emitter<AdaptiveHomeState> emit) {
    final savedSurface = PrefUtils().getSurfaceType();
    final surface = SurfaceType.fromString(savedSurface);
    emit(state.copyWith(surfaceType: surface));
  }

  void _onChangeSurface(
    AdaptiveHomeChangeSurface event,
    Emitter<AdaptiveHomeState> emit,
  ) {
    PrefUtils().setSurfaceType(event.surface.name);
    emit(state.copyWith(surfaceType: event.surface, showSuggestion: false));
  }

  void _onDismissSuggestion(
    AdaptiveHomeDismissSuggestion event,
    Emitter<AdaptiveHomeState> emit,
  ) {
    emit(state.copyWith(showSuggestion: false));
  }
}
