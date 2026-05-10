import 'package:dartz/dartz.dart';
import 'package:hafiz_app/domain/repository/bookmark_repository.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../entities/bookmark.dart';

class LoadBookmarks implements UseCase<List<Bookmark>, NoParams> {
  final BookmarkRepository bookmarkRepository;

  LoadBookmarks({required this.bookmarkRepository});

  @override
  Future<Either<Failure, List<Bookmark>>> call(NoParams params) async {
    return await bookmarkRepository.getBookmarks();
  }
}
