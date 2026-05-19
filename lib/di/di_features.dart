import 'package:hive/hive.dart';

import '../../core/network/network_manager.dart';
import '../../data/datasource/bookmark/bookmark_local_data_source.dart';
import '../../data/datasource/khatmah/khatmah_local_data_source.dart';
import '../../data/datasource/hifz/hifz_local_data_source.dart';
import '../../data/datasource/memorization/memorization_local_data_source.dart';
import '../../data/datasource/qf_activity/qf_activity_remote_data_source.dart';
import '../../data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import '../../data/datasource/qf_search/qf_search_remote_data_source.dart';
import '../../data/datasource/qrc/qrc_remote_datasource.dart';
import '../../data/datasource/recitation_error/recitation_error_local_data_source.dart';
import '../../data/datasource/recitation_session/recitation_session_local_data_source.dart';
import '../../data/datasource/surah/surah_local_data_source.dart';
import '../../data/datasource/surah/surah_remote_data_source.dart';
import '../../data/datasource/tafsir/tafsir_remote_data_source.dart';
import '../../data/repository/bookmark/bookmark_repository_impl.dart';
import '../../data/repository/khatmah/khatmah_repository_impl.dart';
import '../../data/repository/hifz/hifz_repository_impl.dart';
import '../../data/repository/memorization/memorization_repository_impl.dart';
import '../../data/repository/qrc/qrc_repository_impl.dart';
import '../../data/repository/recitation_error/recitation_error_repository_impl.dart';
import '../../data/repository/recitation_session/recitation_session_repository_impl.dart';
import '../../data/repository/surah/surah_repository_impl.dart';
import '../../data/repository/tafsir/tafsir_repository_impl.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/khatmah_repository.dart';
import '../../domain/repository/hifz_repository.dart';
import '../../domain/repository/memorization_repository.dart';
import '../../domain/repository/qrc/qrc_repository.dart';
import '../../domain/repository/recitation_error_repository.dart';
import '../../domain/repository/recitation_session_repository.dart';
import '../../domain/repository/surah/surah_repository.dart';
import '../../domain/repository/tafsir_repository.dart';
import '../../domain/usecase/cloud_sync/sync_with_qf.dart';
import '../../domain/usecase/getsurah/get_surah.dart';
import '../../domain/usecase/bookmark/load_bookmarks.dart';
import '../../domain/usecase/bookmark/toggle_bookmark.dart';
import '../../domain/usecase/goals/get_todays_plan.dart';
import '../../domain/usecase/goals/update_goal.dart';
import '../../domain/usecase/goals/delete_goal.dart';
import '../../domain/usecase/khatmah/log_reading.dart';
import '../../domain/usecase/search/search_verses.dart';
import '../../presentation/bookmarks/bloc/bookmark_bloc.dart';
import '../../presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import '../../presentation/goals/bloc/goals_bloc.dart';
import '../../presentation/khatmah/bloc/khatmah_bloc.dart';
import '../../presentation/hifz/bloc/hifz_bloc.dart';
import '../../presentation/memorization/bloc/memorization_bloc.dart';
import '../../presentation/recitation_error/bloc/recitation_error_bloc.dart';
import '../../presentation/recitation_session/bloc/recitation_session_bloc.dart';
import '../../presentation/search/bloc/search_bloc.dart';
import '../../presentation/surah_screen/bloc/surah_bloc.dart';
import '../../presentation/tajweed_roadmap/bloc/tajweed_roadmap_bloc.dart';
import '../injection_container.dart';

void registerFeatureDependencies() {
  // BLoCs
  sl.registerFactory(() => SurahBloc(getSurah: sl()));
  sl.registerLazySingleton(() => BookmarkBloc(repository: sl()));
  sl.registerFactory(
    () => SearchBloc(
      repository: sl(),
      searchRemoteDataSource: sl<QfSearchRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton(() => RecitationErrorBloc(repository: sl()));
  sl.registerLazySingleton(() => CloudSyncBloc(syncWithQf: sl()));
  sl.registerLazySingleton(() => RecitationSessionBloc(repository: sl()));
  sl.registerFactory(() => GoalsBloc(
    getTodaysPlan: sl(),
    updateGoal: sl(),
    deleteGoal: sl(),
  ));
  sl.registerLazySingleton(() => UpdateGoal(goalsRemoteDataSource: sl()));
  sl.registerLazySingleton(() => DeleteGoal(goalsRemoteDataSource: sl()));
  sl.registerFactory(() => MemorizationBloc(repository: sl()));
  sl.registerFactory(() => HifzBloc(repository: sl()));
  sl.registerLazySingleton(() => KhatmahBloc(repository: sl()));
  sl.registerFactory(
    () => TajweedRoadmapBloc(sessionRepository: sl(), errorRepository: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetSurah(surahRepository: sl()));
  sl.registerLazySingleton(
    () => SyncWithQf(qfUserApi: sl(), bookmarkLocalDataSource: sl(), khatmahRepository: sl()),
  );

  sl.registerLazySingleton(() => LoadBookmarks(bookmarkRepository: sl()));
  sl.registerLazySingleton(() => ToggleBookmark(bookmarkRepository: sl()));
  sl.registerLazySingleton(() => LogReading(khatmahRepository: sl()));
  sl.registerLazySingleton(() => SearchVerses(surahRepository: sl()));
  sl.registerLazySingleton(
    () => GetTodaysPlan(goalsRemoteDataSource: sl<QfGoalsRemoteDataSource>()),
  );

  // Repositories
  sl.registerLazySingleton<SurahRepository>(
    () => SurahRepositoryImpl(
      surahRemoteDataSource: sl(),
      surahLocalDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<RecitationErrorRepository>(
    () => RecitationErrorRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<RecitationSessionRepository>(
    () => RecitationSessionRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<TafsirRepository>(
    () => TafsirRepositoryImpl(
      remoteDataSource: sl(),
      qfTafsirRemoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<MemorizationRepository>(
    () => MemorizationRepositoryImpl(
      localDataSource: sl(),
      goalsRemoteDataSource: sl<QfGoalsRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<HifzRepository>(
    () => HifzRepositoryImpl(
      hifzLocal: sl(),
      oldLocal: sl(),
    ),
  );

  sl.registerLazySingleton<KhatmahRepository>(
    () => KhatmahRepositoryImpl(
      localDataSource: sl(),
      activityRemoteDataSource: sl<QfActivityRemoteDataSource>(),
      goalsRemoteDataSource: sl<QfGoalsRemoteDataSource>(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<SurahRemoteDataSource>(
    () => SurahRemoteDataSourceImpl(networkManager: NetworkManagerImpl(sl())),
  );
  sl.registerLazySingleton<SurahLocalDataSource>(
    () => SurahLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<BookmarkLocalDataSource>(
    () => BookmarkLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<RecitationErrorLocalDataSource>(
    () =>
        RecitationErrorLocalDataSourceImpl(box: Hive.box('recitation_errors')),
  );

  sl.registerLazySingleton<RecitationSessionLocalDataSource>(
    () => RecitationSessionLocalDataSourceImpl(
      box: Hive.box('recitation_sessions'),
    ),
  );

  sl.registerLazySingleton<TafsirRemoteDataSource>(
    () => TafsirRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<MemorizationLocalDataSource>(
    () =>
        MemorizationLocalDataSourceImpl(box: Hive.box('memorization_progress')),
  );

  sl.registerLazySingleton<HifzLocalDataSource>(
    () => HifzLocalDataSourceImpl(box: Hive.box('hifz_entries')),
  );

  sl.registerLazySingleton<KhatmahLocalDataSource>(
    () => KhatmahLocalDataSourceImpl(
      logBox: Hive.box('reading_logs'),
      goalBox: Hive.box('reading_goal'),
      offlineSessionBox: Hive.box('offline_reading_sessions'),
    ),
  );

  sl.registerLazySingleton<QrcRemoteDataSource>(
    () => QrcRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<QrcRepository>(
    () => QrcRepositoryImpl(remoteDataSource: sl()),
  );
}
