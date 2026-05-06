import 'package:equatable/equatable.dart';

abstract class MushafEvent extends Equatable {
  const MushafEvent();

  @override
  List<Object?> get props => [];
}

class LoadPage extends MushafEvent {
  final int pageNumber;

  const LoadPage(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

class NavigateToPage extends MushafEvent {
  final int pageNumber;

  const NavigateToPage(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

class ToggleDualPage extends MushafEvent {
  const ToggleDualPage();
}
