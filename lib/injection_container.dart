import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/data/datasource/surah/surah_remote_data_source.dart';
import 'package:hafiz_app/data/repository/surah/surah_repository_impl.dart';
import 'package:hafiz_app/domain/repository/surah/surah_repository.dart';
import 'package:hafiz_app/domain/usecase/getsurah/get_surah.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/cloud_sync_usecase.dart';
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
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_bloc.dart';
import 'package:hafiz_app/data/datasource/surah/surah_local_data_source.dart';
import 'package:hafiz_app/data/datasource/bookmark/bookmark_local_data_source.dart';
import 'package:hafiz_app/data/datasource/recitation_error/recitation_error_local_data_source.dart';
import 'package:hafiz_app/data/datasource/cloud_sync/cloud_sync_remote_data_source.dart';
import 'package:hafiz_app/data/repository/bookmark/bookmark_repository_impl.dart';
import 'package:hafiz_app/data/repository/recitation_error/recitation_error_repository_impl.dart';
import 'package:hafiz_app/data/repository/cloud_sync/cloud_sync_repository_impl.dart';
import 'package:hafiz_app/domain/repository/bookmark_repository.dart';
import 'package:hafiz_app/domain/repository/recitation_error_repository.dart';
import 'package:hafiz_app/domain/repository/cloud_sync_repository.dart';

import 'core/network/network_manager.dart';
import 'core/network/qf_auth.dart';
import 'core/config/api_config.dart';
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
  sl.registerFactory(() => SearchBloc(repository: sl()));
  sl.registerFactory(() => HomeBloc());
  sl.registerLazySingleton(() => RecitationErrorBloc(repository: sl()));
  sl.registerLazySingleton(() => ThemeBloc());
  sl.registerLazySingleton(() => ScrollPositionCubit());
  sl.registerLazySingleton(
    () => CloudSyncBloc(
      performCloudSync: sl(),
      checkCloudSyncAuth: sl(),
      signInCloudSync: sl(),
      signOutCloudSync: sl(),
    ),
  );
  sl.registerLazySingleton(() => RecitationSessionBloc(repository: sl()));
  // Defer Analytics creation until Firebase initializes; resolve inside observer when needed
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => AnalyticsRouteObserver());

  // Use Case
  sl.registerLazySingleton(() => GetSurah(surahRepository: sl()));
  sl.registerLazySingleton(() => PerformCloudSync(repository: sl()));
  sl.registerLazySingleton(() => CheckCloudSyncAuth(repository: sl()));
  sl.registerLazySingleton(() => SignInCloudSync(repository: sl()));
  sl.registerLazySingleton(() => SignOutCloudSync(repository: sl()));

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

  sl.registerLazySingleton<CloudSyncRepository>(
    () => CloudSyncRepositoryImpl(
      remoteDataSource: sl(),
      bookmarkLocalDataSource: sl(),
      recitationErrorLocalDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<RecitationSessionRepository>(
    () => RecitationSessionRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<TafsirRepository>(
    () => TafsirRepositoryImpl(remoteDataSource: sl()),
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

  sl.registerLazySingleton<CloudSyncRemoteDataSource>(
    () => CloudSyncRemoteDataSourceImpl(),
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
    return dio;
  });
}
