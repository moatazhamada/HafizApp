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

class PrefetchPages extends MushafEvent {
  final List<int> pageNumbers;

  const PrefetchPages(this.pageNumbers);

  @override
  List<Object?> get props => [pageNumbers];
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

class RefreshPage extends MushafEvent {
  final int pageNumber;

  const RefreshPage(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}
