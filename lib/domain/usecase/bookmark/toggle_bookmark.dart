import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/repository/bookmark_repository.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../entities/bookmark.dart';

class ToggleBookmark implements UseCase<bool, ParamsToggleBookmark> {
  final BookmarkRepository bookmarkRepository;

  ToggleBookmark({required this.bookmarkRepository});

  @override
  Future<Either<Failure, bool>> call(ParamsToggleBookmark params) async {
    final isBookmarked =
        await bookmarkRepository.isBookmarked(params.surahId, params.verseNumber);
    return isBookmarked.fold(
      (failure) => Left(failure),
      (bookmarked) {
        if (bookmarked) {
          return bookmarkRepository.removeBookmark(
            params.surahId,
            params.verseNumber,
          );
        } else {
          return bookmarkRepository.addBookmark(params.bookmark);
        }
      },
    );
  }
}

class ParamsToggleBookmark extends Equatable {
  final int surahId;
  final int verseNumber;
  final Bookmark bookmark;

  const ParamsToggleBookmark({
    required this.surahId,
    required this.verseNumber,
    required this.bookmark,
  });

  @override
  List<Object> get props => [surahId, verseNumber];
}
