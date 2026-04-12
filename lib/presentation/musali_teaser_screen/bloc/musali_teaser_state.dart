part of 'musali_teaser_bloc.dart';

enum TeaserSlide { initial, slide0, slide1, slide2, slide3, completed }

class MusaliTeaserState extends Equatable {
  final TeaserSlide currentSlide;
  final bool isAnimating;

  const MusaliTeaserState({
    this.currentSlide = TeaserSlide.initial,
    this.isAnimating = false,
  });

  @override
  List<Object?> get props => [currentSlide, isAnimating];
}

class MusaliTeaserInitial extends MusaliTeaserState {
  const MusaliTeaserInitial() : super(currentSlide: TeaserSlide.initial);
}

class TeaserSlideUpdated extends MusaliTeaserState {
  const TeaserSlideUpdated({required this.slideIndex});

  final int slideIndex;

  @override
  List<Object?> get props => [slideIndex];
}

class TeaserCompleted extends MusaliTeaserState {
  const TeaserCompleted() : super(currentSlide: TeaserSlide.completed);
}
