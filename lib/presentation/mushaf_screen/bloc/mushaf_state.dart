import 'package:equatable/equatable.dart';

class AyahEntry extends Equatable {
  final int surahId;
  final int verseNumber;
  final String surahNameArabic;
  final bool isSurahHeader;
  final bool showBismillah;

  const AyahEntry({
    required this.surahId,
    required this.verseNumber,
    required this.surahNameArabic,
    this.isSurahHeader = false,
    this.showBismillah = false,
  });

  @override
  List<Object?> get props =>
      [surahId, verseNumber, surahNameArabic, isSurahHeader, showBismillah];
}

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
  final List<AyahEntry> entries;
  final String mushafType;

  const MushafPageLoaded({
    required this.pageNumber,
    required this.entries,
    this.mushafType = 'madani',
  });

  @override
  List<Object?> get props => [pageNumber, entries, mushafType];
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
