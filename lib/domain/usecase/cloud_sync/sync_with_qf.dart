import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/data/datasource/qf_user_api_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/bookmark/bookmark_local_data_source.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';

class QfSyncResult {
  final int pushed;
  final int pulled;
  final int activityDaysUpdated;

  const QfSyncResult({required this.pushed, required this.pulled, this.activityDaysUpdated = 0});
}

class SyncWithQf implements UseCase<QfSyncResult, NoParams> {
  final QfUserApiRemoteDataSource qfUserApi;
  final BookmarkLocalDataSource bookmarkLocalDataSource;
  final KhatmahRepository khatmahRepository;

  SyncWithQf({
    required this.qfUserApi, 
    required this.bookmarkLocalDataSource,
    required this.khatmahRepository,
  });

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
        Logger.warning('QF bookmark collection setup failed: $e', feature: 'CloudSync');
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
      if (defaultCollectionId != null) {
        await Future.wait(
          toPush.map((verseId) async {
            try {
              await qfUserApi.addBookmark(verseId, collectionId: defaultCollectionId);
            } catch (e) {
              Logger.warning(
                'Failed to push bookmark $verseId: $e',
                feature: 'SyncWithQf',
              );
            }
          }),
        );
      } else {
        Logger.warning(
          'Skipping bookmark push: no default collection ID',
          feature: 'SyncWithQf',
        );
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

      int activityDaysUpdated = 0;
      final activityDaysResult = await khatmahRepository.syncActivityDaysFromCloud();
      activityDaysResult.fold(
        (failure) => Logger.warning('Failed to sync activity days from cloud: $failure', feature: 'SyncWithQf'),
        (count) => activityDaysUpdated = count,
      );

      Logger.info(
        'QF sync complete: pushed ${toPush.length}, pulled ${toPull.length}, activity days updated: $activityDaysUpdated',
        feature: 'SyncWithQf',
      );
      return Right(QfSyncResult(pushed: toPush.length, pulled: toPull.length, activityDaysUpdated: activityDaysUpdated));
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
    if (surahId < 1 || surahId > 114) {
      throw ArgumentError('Invalid surahId: $surahId (must be 1-114)');
    }
    final maxVerse = MushafPageIndex.getVerseCount(surahId);
    if (verseNumber < 1 || verseNumber > maxVerse) {
      throw ArgumentError(
        'Invalid verseNumber: $verseNumber for surah $surahId (must be 1-$maxVerse)',
      );
    }
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
    if (absoluteId < 1) {
      throw ArgumentError('Invalid absoluteId: $absoluteId (must be ≥1)');
    }
    int remaining = absoluteId;
    for (int i = 0; i < 114; i++) {
      final count = MushafPageIndex.getVerseCount(i + 1);
      if (remaining <= count) {
        return '${i + 1}:$remaining';
      }
      remaining -= count;
    }
    throw ArgumentError(
      'absoluteId $absoluteId exceeds total Quran verses',
    );
  }
}
