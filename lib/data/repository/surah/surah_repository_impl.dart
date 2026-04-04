import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/entities/verse.dart';
import '../../../domain/repository/surah/surah_repository.dart';
import '../../datasource/surah/surah_remote_data_source.dart';
import '../../datasource/surah/surah_local_data_source.dart';
import '../../model/surah_response.dart';

class SurahRepositoryImpl implements SurahRepository {
  final SurahRemoteDataSource surahRemoteDataSource;
  final SurahLocalDataSource? surahLocalDataSource;
  final NetworkInfo networkInfo;

  // Request deduplication map
  final Map<String, Future<Either<Failure, List<Verse>>>> _pendingRequests = {};

  SurahRepositoryImpl({
    required this.surahRemoteDataSource,
    this.surahLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Verse>>> getSurah(String surahId) async {
    // Check if request is already pending
    if (_pendingRequests.containsKey(surahId)) {
      Logger.debug(
        'Reusing pending request for surah $surahId',
        feature: 'Surah',
      );
      return _pendingRequests[surahId]!;
    }

    // Create new request
    final request = _getSurahInternal(surahId);
    _pendingRequests[surahId] = request;

    try {
      return await request;
    } finally {
      // Synchronously remove from pending requests map
      // ignore: unawaited_futures
      _pendingRequests.remove(surahId);
    }
  }

  Future<Either<Failure, List<Verse>>> _getSurahInternal(String surahId) async {
    // Attempt local (bundled) text first
    if (surahLocalDataSource != null) {
      try {
        final local = await surahLocalDataSource!.getSurah(surahId);
        return Right(local.chapters);
      } catch (e) {
        Logger.debug(
          'Local surah $surahId not found, trying cache/network',
          feature: 'Surah',
        );
      }
    }

    // Attempt to serve from cache first
    final box = Hive.isBoxOpen('surah_cache') ? Hive.box('surah_cache') : null;
    final cached = box?.get(surahId);
    if (cached is Map<String, dynamic>) {
      try {
        return Right(ChapterResponse.fromJson(cached).chapters);
      } catch (e, stackTrace) {
        Logger.warning(
          'Failed to decode cached surah $surahId: $e',
          feature: 'Surah',
          stackTrace: stackTrace,
        );
      }
    }

    bool isConnected = await networkInfo.isConnected();
    if (!isConnected) {
      Logger.info(
        'No network connection, returning ConnectionFailure for surah $surahId',
        feature: 'Surah',
      );
      return Left(ConnectionFailure());
    }

    try {
      var response = await surahRemoteDataSource.getSurah(surahId);
      // Write-through cache (surahs are static)
      await box?.put(surahId, _chapterResponseToJson(response));
      return Right(response.chapters);
    } catch (error, stackTrace) {
      // If network fails but cache exists, serve stale cache
      if (cached is Map<String, dynamic>) {
        try {
          Logger.warning(
            'Network failed, serving stale cache for surah $surahId',
            feature: 'Surah',
          );
          return Right(ChapterResponse.fromJson(cached).chapters);
        } catch (cacheError) {
          Logger.error(
            'Failed to decode stale cache for surah $surahId',
            feature: 'Surah',
            error: cacheError,
          );
        }
      }

      if (error is DioException) {
        Logger.error(
          'DioException loading surah $surahId: ${error.message}',
          feature: 'Surah',
          error: error,
          stackTrace: stackTrace,
        );
        return Left(ServerFailure(error.message ?? 'Unknown Error'));
      }

      Logger.error(
        'Error loading surah $surahId: $error',
        feature: 'Surah',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(error.toString()));
    }
  }

  Map<String, dynamic> _chapterResponseToJson(ChapterResponse resp) {
    return {
      'chapter': resp.chapters
          .map(
            (c) => {
              'chapter': c.chapterId,
              'verse': c.verseNumber,
              'text': c.text,
            },
          )
          .toList(),
    };
  }

  @override
  Future<Either<Failure, List<Verse>>> searchVerses(String query) async {
    if (surahLocalDataSource != null) {
      try {
        final matches = await surahLocalDataSource!.searchVerses(query);
        if (matches.isNotEmpty) return Right(matches);
      } catch (e) {
        Logger.error(
          'Local search failed for query "$query", trying cache: $e',
          feature: 'Search',
          error: e,
        );
      }
    }

    // Fallback: Search in Cache (Hive)
    try {
      if (Hive.isBoxOpen('surah_cache')) {
        final box = Hive.box('surah_cache');
        final allMatches = <Verse>[];
        // Heuristic: iterating all keys is expensive, but necessary for offline fallback if assets fail
        // Since we only have 114 Surahs, this is acceptable.
        for (var key in box.keys) {
          final data = box.get(key);
          if (data is Map<String, dynamic>) {
            try {
              final response = ChapterResponse.fromJson(data);
              for (final verse in response.chapters) {
                if (verse.text.contains(query)) {
                  allMatches.add(verse);
                }
              }
            } catch (_) {
              // Ignore malformed cache entries
            }
          }
        }
        return Right(allMatches);
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Cache search failed for query "$query": $e',
        feature: 'Search',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure(e.toString()));
    }

    return const Right([]);
  }
}
