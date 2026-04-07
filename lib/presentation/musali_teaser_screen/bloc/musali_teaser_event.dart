part of 'musali_teaser_bloc.dart';

import 'package:equatable/equatable.dart';

abstract class MusaliTeaserEvent extends Equatable {
  const MusaliTeaserEvent();

  @override
  List<Object?> get props => [];
}

class NextSlidePressed extends MusaliTeaserEvent {}

class SkipPressed extends MusaliTeaserEvent {}

class Dismissed extends MusaliTeaserEvent {}

class AutoAdvanceTick extends MusaliTeaserEvent {
  final bool shouldAdvance;

  const AutoAdvanceTick({required this.shouldAdvance});

  @override
  List<Object?> get props => [shouldAdvance];
}
