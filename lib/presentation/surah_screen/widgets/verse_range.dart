import 'package:hafiz_app/domain/entities/verse.dart';

class VerseRange {
  final int start;
  final int end;
  final Verse verse;
  final bool isBadge;
  final bool isBookmarked;
  final bool isError;

  const VerseRange({
    required this.start,
    required this.end,
    required this.verse,
    this.isBadge = false,
    this.isBookmarked = false,
    this.isError = false,
  });
}
