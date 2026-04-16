import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/app_export.dart';

part 'musali_teaser_event.dart';
part 'musali_teaser_state.dart';

class MusaliTeaserBloc extends Bloc<MusaliTeaserEvent, MusaliTeaserState> {
  MusaliTeaserBloc() : super(const MusaliTeaserInitial()) {
    on<NextSlidePressed>(_onNextSlidePressed);
    on<SkipPressed>(_onSkipPressed);
    on<Dismissed>(_onDismissed);
    on<AutoAdvanceTick>(_onAutoAdvanceTick);
  }

  int _currentSlide = 0;
  Timer? _autoSlideTimer;

  void _onNextSlidePressed(
    NextSlidePressed event,
    Emitter<MusaliTeaserState> emit,
  ) {
    if (_currentSlide < 3) {
      _currentSlide++;
      emit(TeaserSlideUpdated(slideIndex: _currentSlide));
      startAutoSlide();
    } else {
      emit(const TeaserCompleted());
    }
  }

  void _onSkipPressed(SkipPressed event, Emitter<MusaliTeaserState> emit) {
    emit(const TeaserCompleted());
  }

  void _onDismissed(Dismissed event, Emitter<MusaliTeaserState> emit) {
    emit(const TeaserCompleted());
  }

  void _onAutoAdvanceTick(
    AutoAdvanceTick event,
    Emitter<MusaliTeaserState> emit,
  ) {
    if (event.shouldAdvance && _currentSlide < 3) {
      _currentSlide++;
      emit(TeaserSlideUpdated(slideIndex: _currentSlide));
    }
  }

  void startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!isClosed) {
        add(const AutoAdvanceTick(shouldAdvance: true));
      }
    });
  }

  @override
  Future<void> close() {
    _autoSlideTimer?.cancel();
    return super.close();
  }
}
