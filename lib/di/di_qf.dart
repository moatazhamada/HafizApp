import 'package:dio/dio.dart';

import '../../data/datasource/qf_activity/qf_activity_remote_data_source.dart';
import '../../data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import '../../data/datasource/qf_search/qf_search_remote_data_source.dart';
import '../../data/datasource/qf_user_api_remote_data_source.dart';
import '../../data/datasource/tafsir/qf_tafsir_remote_data_source.dart';
import '../../data/datasource/translation/qf_translation_remote_data_source.dart';
import '../../data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import '../../data/datasource/qf_post/qf_post_remote_data_source.dart';
import '../../data/datasource/random_verse/random_verse_remote_data_source.dart';
import '../../data/datasource/verse_media/verse_media_remote_data_source.dart';
import '../../data/datasource/qf_preference/qf_preference_remote_data_source.dart';
import '../../core/services/preference_sync_service.dart';
import '../injection_container.dart';

void registerQfDataSources() {
  sl.registerLazySingleton<QfUserApiRemoteDataSource>(
    () => QfUserApiRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<QfActivityRemoteDataSource>(
    () => QfActivityRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<QfGoalsRemoteDataSource>(
    () => QfGoalsRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<QfSearchRemoteDataSource>(
    () => QfSearchRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<QfTafsirRemoteDataSource>(
    () => QfTafsirRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<QfVerseStudyRemoteDataSource>(
    () => QfVerseStudyRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerSingleton<QfTranslationRemoteDataSource>(
    QfTranslationRemoteDataSource(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<QfPostRemoteDataSource>(
    () => QfPostRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<RandomVerseRemoteDataSource>(
    () => RandomVerseRemoteDataSource(
      dio: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<VerseMediaRemoteDataSource>(
    () => VerseMediaRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<QfPreferenceRemoteDataSource>(
    () => QfPreferenceRemoteDataSource(dio: sl()),
  );

  sl.registerLazySingleton<PreferenceSyncService>(
    () => PreferenceSyncService(),
  );
}
