part of 'adaptive_home_bloc.dart';

class AdaptiveHomeState extends Equatable {
  final SurfaceType surfaceType;
  final bool showSuggestion;
  final String? suggestedSurface;

  const AdaptiveHomeState({
    required this.surfaceType,
    this.showSuggestion = false,
    this.suggestedSurface,
  });

  factory AdaptiveHomeState.initial() {
    return const AdaptiveHomeState(surfaceType: SurfaceType.reader);
  }

  @override
  List<Object?> get props => [surfaceType, showSuggestion, suggestedSurface];

  AdaptiveHomeState copyWith({
    SurfaceType? surfaceType,
    bool? showSuggestion,
    String? suggestedSurface,
  }) {
    return AdaptiveHomeState(
      surfaceType: surfaceType ?? this.surfaceType,
      showSuggestion: showSuggestion ?? this.showSuggestion,
      suggestedSurface: suggestedSurface ?? this.suggestedSurface,
    );
  }
}
