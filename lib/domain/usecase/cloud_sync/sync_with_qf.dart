import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/data/datasource/qf_user_api_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/bookmark/bookmark_local_data_source.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfSyncResult {
  final int pushed;
  final int pulled;

  const QfSyncResult({required this.pushed, required this.pulled});
}

class SyncWithQf implements UseCase<QfSyncResult, NoParams> {
  final QfUserApiRemoteDataSource qfUserApi;
  final BookmarkLocalDataSource bookmarkLocalDataSource;

  SyncWithQf({required this.qfUserApi, required this.bookmarkLocalDataSource});

  @override
  Future<Either<Failure, QfSyncResult>> call(NoParams params) async {
    try {
      final localBookmarks = await bookmarkLocalDataSource.getBookmarks();

      final Set<int> localVerseIds = {};
      for (final b in localBookmarks) {
        final absoluteId = _surahVerseToAbsoluteId(b.surahId, b.verseNumber);
        localVerseIds.add(absoluteId);
      }

      String? defaultCollectionId;
      try {
        final collections = await qfUserApi.getCollections();
        final existing = collections.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['name'] == 'Hafiz Bookmarks',
          orElse: () => null,
        );
        if (existing != null) {
          defaultCollectionId = existing['id']?.toString();
        } else {
          final created = await qfUserApi.createCollection('Hafiz Bookmarks');
          defaultCollectionId = created?['id']?.toString();
        }
      } catch (e) {
        Logger.warning('QF bookmark collection setup failed: \$e', feature: 'CloudSync');
      }

      final qfBookmarks = await qfUserApi.getBookmarks();
      final Set<int> qfVerseIds = {};
      for (final b in qfBookmarks) {
        final vid = b['verse_id'] as int?;
        final verseKey = b['verse_key'] as String?;
        if (vid != null) {
          qfVerseIds.add(vid);
        } else if (verseKey != null) {
          qfVerseIds.add(_verseKeyToAbsoluteId(verseKey));
        }
      }

      final toPush = localVerseIds.difference(qfVerseIds);
      for (final verseId in toPush) {
        try {
          await qfUserApi.addBookmark(verseId, collectionId: defaultCollectionId);
        } catch (e) {
          Logger.warning(
            'Failed to push bookmark $verseId: $e',
            feature: 'SyncWithQf',
          );
        }
      }

      final toPull = qfVerseIds.difference(localVerseIds);
      for (final verseId in toPull) {
        try {
          final key = _absoluteIdToVerseKey(verseId);
          final parts = key.split(':');
          final surahId = int.parse(parts[0]);
          final verseNum = int.parse(parts[1]);
          final surah = QuranIndex.quranSurahs.firstWhere(
            (s) => s.id == surahId,
            orElse: () => Surah(surahId, 'Surah $surahId', 'سورة $surahId'),
          );
          await bookmarkLocalDataSource.addBookmark(
            BookmarkModel(
              surahId: surahId,
              surahName: surah.nameEnglish,
              verseNumber: verseNum,
              createdAt: DateTime.now(),
            ),
          );
        } catch (e) {
          Logger.warning(
            'Failed to pull bookmark $verseId: $e',
            feature: 'SyncWithQf',
          );
        }
      }

      Logger.info(
        'QF sync complete: pushed ${toPush.length}, pulled ${toPull.length}',
        feature: 'SyncWithQf',
      );
      return Right(QfSyncResult(pushed: toPush.length, pulled: toPull.length));
    } on InsufficientScopeFailure {
      Logger.warning(
        'QF sync blocked by insufficient scope',
        feature: 'SyncWithQf',
      );
      return Left(InsufficientScopeFailure());
    } catch (e) {
      Logger.error('QF sync failed: $e', feature: 'SyncWithQf');
      return Left(ServerFailure('Failed to sync with Quran.com: $e'));
    }
  }

  int _surahVerseToAbsoluteId(int surahId, int verseNumber) {
    int offset = 0;
    for (int i = 0; i < surahId - 1; i++) {
      offset += MushafPageIndex.getVerseCount(i + 1);
    }
    return offset + verseNumber;
  }

  int _verseKeyToAbsoluteId(String verseKey) {
    final parts = verseKey.split(':');
    final surahId = int.parse(parts[0]);
    final verseNum = int.parse(parts[1]);
    return _surahVerseToAbsoluteId(surahId, verseNum);
  }

  String _absoluteIdToVerseKey(int absoluteId) {
    int remaining = absoluteId;
    for (int i = 0; i < 114; i++) {
      final count = MushafPageIndex.getVerseCount(i + 1);
      if (remaining <= count) {
        return '${i + 1}:$remaining';
      }
      remaining -= count;
    }
    return '1:1';
  }
}
