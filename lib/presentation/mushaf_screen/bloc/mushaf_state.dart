import 'package:equatable/equatable.dart';

abstract class MushafState extends Equatable {
  const MushafState();

  @override
  List<Object?> get props => [];
}

class MushafInitial extends MushafState {
  const MushafInitial();
}

class MushafPageLoading extends MushafState {
  final int pageNumber;

  const MushafPageLoading(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

class MushafPageLoaded extends MushafState {
  final int pageNumber;
  final String mushafType;

  const MushafPageLoaded({
    required this.pageNumber,
    this.mushafType = 'madani',
  });

  @override
  List<Object?> get props => [pageNumber, mushafType];
}

class MushafPageError extends MushafState {
  final int pageNumber;
  final String message;

  const MushafPageError(this.pageNumber, this.message);

  @override
  List<Object?> get props => [pageNumber, message];
}

class MushafDualPageToggled extends MushafState {
  final bool dualPageEnabled;

  const MushafDualPageToggled(this.dualPageEnabled);

  @override
  List<Object?> get props => [dualPageEnabled];
}
