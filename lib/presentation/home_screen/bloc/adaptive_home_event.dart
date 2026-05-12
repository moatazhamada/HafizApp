part of 'adaptive_home_bloc.dart';

abstract class AdaptiveHomeEvent {}

class AdaptiveHomeLoad extends AdaptiveHomeEvent {}

class AdaptiveHomeChangeSurface extends AdaptiveHomeEvent {
  final SurfaceType surface;
  AdaptiveHomeChangeSurface(this.surface);
}

class AdaptiveHomeDismissSuggestion extends AdaptiveHomeEvent {}
