part of 'tajweed_roadmap_bloc.dart';

abstract class TajweedRoadmapState {
  const TajweedRoadmapState();
}

class TajweedRoadmapInitial extends TajweedRoadmapState {
  const TajweedRoadmapInitial();
}

class TajweedRoadmapLoading extends TajweedRoadmapState {
  const TajweedRoadmapLoading();
}

class TajweedRoadmapLoaded extends TajweedRoadmapState {
  final TajweedProgress progress;
  final List<TajweedPracticeItem> practiceItems;

  const TajweedRoadmapLoaded({
    required this.progress,
    this.practiceItems = const [],
  });
}

class TajweedRoadmapError extends TajweedRoadmapState {
  final String message;
  const TajweedRoadmapError(this.message);
}
