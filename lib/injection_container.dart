import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/data/datasource/surah/surah_remote_data_source.dart';
import 'package:hafiz_app/data/repository/surah/surah_repository_impl.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:hafiz_app/domain/usecase/getsurah/get_surah.dart';
import 'package:hafiz_app/presentation/home_screen/bloc/home_bloc.dart';
import 'package:hafiz_app/presentation/surah_screen/bloc/surah_bloc.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/presentation/search/bloc/search_bloc.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import 'package:hafiz_app/data/datasource/recitation_session/recitation_session_local_data_source.dart';
import 'package:hafiz_app/data/repository/recitation_session/recitation_session_repository_impl.dart';
import 'package:hafiz_app/domain/repository/recitation_session_repository.dart';
import 'package:hafiz_app/domain/repository/tafsir_repository.dart';
import 'package:hafiz_app/data/datasource/tafsir/tafsir_remote_data_source.dart';
import 'package:hafiz_app/data/repository/tafsir/tafsir_repository_impl.dart';
import 'package:hafiz_app/data/datasource/memorization/memorization_local_data_source.dart';
import 'package:hafiz_app/data/repository/memorization/memorization_repository_impl.dart';
import 'package:hafiz_app/domain/repository/memorization_repository.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_bloc.dart';
import 'package:hafiz_app/data/datasource/khatmah/khatmah_local_data_source.dart';
import 'package:hafiz_app/data/repository/khatmah/khatmah_repository_impl.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_bloc.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_bloc.dart';
import 'package:hafiz_app/data/datasource/surah/surah_local_data_source.dart';
import 'package:hafiz_app/data/datasource/bookmark/bookmark_local_data_source.dart';
import 'package:hafiz_app/data/datasource/recitation_error/recitation_error_local_data_source.dart';
import 'package:hafiz_app/data/repository/bookmark/bookmark_repository_impl.dart';
import 'package:hafiz_app/data/repository/recitation_error/recitation_error_repository_impl.dart';
import 'package:hafiz_app/domain/repository/bookmark_repository.dart';
import 'package:hafiz_app/domain/repository/recitation_error_repository.dart';
import 'package:hafiz_app/data/datasource/qrc/qrc_remote_datasource.dart';
import 'package:hafiz_app/data/repository/qrc/qrc_repository_impl.dart';
import 'package:hafiz_app/domain/repository/qrc/qrc_repository.dart';
import 'package:hafiz_app/data/datasource/tafsir/qf_tafsir_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/mushaf/qf_mushaf_page_data_source.dart';
import 'package:hafiz_app/data/datasource/translation/qf_translation_remote_data_source.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/sync_with_qf.dart';

import 'core/network/network_manager.dart';
import 'core/network/qf_auth.dart';
import 'core/config/api_config.dart';
import 'data/datasource/auth/qf_auth_remote_data_source.dart';
import 'data/datasource/qf_user_api_remote_data_source.dart';
import 'data/datasource/qf_activity/qf_activity_remote_data_source.dart';
import 'data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'data/datasource/qf_search/qf_search_remote_data_source.dart';
import 'presentation/auth/bloc/qf_auth_bloc.dart';
import 'core/network/qf_api_interceptor.dart';
import 'core/scroll/scroll_position_cubit.dart';
import 'core/analytics/analytics_service.dart';
import 'core/analytics/analytics_route_observer.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Local storage for caching is initialized in main() to avoid test issues.
  /**
    * ! Features
    */
  // Bloc
  sl.registerFactory(() => SurahBloc(getSurah: sl()));
  sl.registerLazySingleton(() => BookmarkBloc(repository: sl()));
  sl.registerFactory(
    () => SearchBloc(
      repository: sl(),
      searchRemoteDataSource: sl<QfSearchRemoteDataSource>(),
    ),
  );
  sl.registerFactory(() => HomeBloc());
  sl.registerLazySingleton(() => RecitationErrorBloc(repository: sl()));
  sl.registerLazySingleton(() => ThemeBloc());
  sl.registerLazySingleton(() => QfAuthBloc(authRemoteDataSource: sl()));
  sl.registerLazySingleton(() => ScrollPositionCubit());
  sl.registerFactory(() => CloudSyncBloc(syncWithQf: sl()));
  sl.registerLazySingleton(() => RecitationSessionBloc(repository: sl()));
  sl.registerLazySingleton(() => MemorizationBloc(repository: sl()));
  sl.registerLazySingleton(() => KhatmahBloc(repository: sl()));
  // Defer Analytics creation until Firebase initializes; resolve inside observer when needed
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => AnalyticsRouteObserver());

  // Use Case
  sl.registerLazySingleton(() => GetSurah(surahRepository: sl()));
  sl.registerLazySingleton(
    () => SyncWithQf(qfUserApi: sl(), bookmarkLocalDataSource: sl()),
  );

  // Repository
  sl.registerLazySingleton<SurahRepository>(
    () => SurahRepositoryImpl(
      surahRemoteDataSource: sl(),
      surahLocalDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(localDataSource: sl()),
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

  sl.registerLazySingleton<KhatmahRepository>(
    () => KhatmahRepositoryImpl(
      localDataSource: sl(),
      activityRemoteDataSource: sl<QfActivityRemoteDataSource>(),
      goalsRemoteDataSource: sl<QfGoalsRemoteDataSource>(),
    ),
  );

  // Data Source
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

  sl.registerLazySingleton<QfTafsirRemoteDataSource>(
    () => QfTafsirRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<MemorizationLocalDataSource>(
    () =>
        MemorizationLocalDataSourceImpl(box: Hive.box('memorization_progress')),
  );

  sl.registerLazySingleton<KhatmahLocalDataSource>(
    () => KhatmahLocalDataSourceImpl(
      logBox: Hive.box('reading_logs'),
      goalBox: Hive.box('reading_goal'),
    ),
  );

  sl.registerLazySingleton<QfAuthRemoteDataSource>(
    () => QfAuthRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<QfUserApiRemoteDataSource>(
    () => QfUserApiRemoteDataSourceImpl(dio: sl()),
  );

  // QF Activity & Streak data source
  sl.registerLazySingleton<QfActivityRemoteDataSource>(
    () => QfActivityRemoteDataSourceImpl(dio: sl()),
  );

  // QF Goals & Reading Sessions data source
  sl.registerLazySingleton<QfGoalsRemoteDataSource>(
    () => QfGoalsRemoteDataSourceImpl(dio: sl()),
  );

  // QF Search data source
  sl.registerLazySingleton<QfSearchRemoteDataSource>(
    () => QfSearchRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<QrcRemoteDataSource>(
    () => QrcRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<QfVerseStudyRemoteDataSource>(
    () => QfVerseStudyRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<QfMushafPageDataSource>(
    () => QfMushafPageDataSourceImpl(dio: sl()),
  );

  // Translation data source
  sl.registerSingleton<QfTranslationRemoteDataSource>(
    QfTranslationRemoteDataSource(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<QrcRepository>(
    () => QrcRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => NetworkInfo(Connectivity()));

  /**
   * ! External
   */
  sl.registerLazySingleton(() {
    final dio = Dio();
    // Select base URL
    if (ApiConfig.useQfContent) {
      dio.options.baseUrl = ApiConfig.qfContentBase;
    } else {
      dio.options.baseUrl = 'https://api.quran.com/api/v4';
    }
    dio.options.connectTimeout = const Duration(seconds: 7);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    // Attach Quran.Foundation OAuth2 interceptor if credentials provided
    if (ApiConfig.clientId.isNotEmpty && ApiConfig.clientSecret.isNotEmpty) {
      final auth = QfAuthService();
      dio.interceptors.add(QfAuthInterceptor(auth));
    }

    // Attach QF User APIs interceptor
    dio.interceptors.add(QfApiInterceptor(sl<QfAuthRemoteDataSource>(), dio));

    return dio;
  });
}
