import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
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

  SurahRepositoryImpl({
    required this.surahRemoteDataSource,
    this.surahLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Verse>>> getSurah(String surahId) async {
    // Attempt local (bundled) text first
    if (surahLocalDataSource != null) {
      try {
        final local = await surahLocalDataSource!.getSurah(surahId);
        return Right(local.chapters);
      } catch (_) {
        // If not found locally, proceed to cache/network
      }
    }

    // Attempt to serve from cache first
    final box = Hive.isBoxOpen('surah_cache') ? Hive.box('surah_cache') : null;
    final cached = box?.get(surahId);
    if (cached is Map<String, dynamic>) {
      try {
        return Right(ChapterResponse.fromJson(cached).chapters);
      } catch (_) {
        // If decoding fails, fall through to network
      }
    }

    bool isConnected = await networkInfo.isConnected();
    if (!isConnected) {
      // If offline and no cache, return connection failure
      return Left(ConnectionFailure());
    }

    try {
      var response = await surahRemoteDataSource.getSurah(surahId);
      // Write-through cache (surahs are static)
      await box?.put(surahId, _chapterResponseToJson(response));
      return Right(response.chapters);
    } catch (error) {
      // If network fails but cache exists, serve stale cache
      if (cached is Map<String, dynamic>) {
        try {
          return Right(ChapterResponse.fromJson(cached).chapters);
        } catch (_) {}
      }
      if (error is DioException) {
        return Left(ServerFailure(error.message ?? 'Unknown Error'));
      }
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
        return Right(matches);
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
    return const Right([]);
  }
}
