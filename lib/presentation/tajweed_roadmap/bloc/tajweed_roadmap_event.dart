part of 'tajweed_roadmap_bloc.dart';

abstract class TajweedRoadmapEvent {
  const TajweedRoadmapEvent();
}

class LoadTajweedRoadmap extends TajweedRoadmapEvent {
  const LoadTajweedRoadmap();
}
