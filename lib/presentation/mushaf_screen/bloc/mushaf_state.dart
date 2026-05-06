import 'package:equatable/equatable.dart';
import 'package:hafiz_app/data/datasource/mushaf/qf_mushaf_page_data_source.dart';

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
  final MushafPageData pageData;
  final bool isUsingFallback;

  const MushafPageLoaded({
    required this.pageNumber,
    required this.pageData,
    this.isUsingFallback = false,
  });

  @override
  List<Object?> get props => [pageNumber, pageData, isUsingFallback];
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
