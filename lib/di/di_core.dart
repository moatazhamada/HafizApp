import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/analytics_route_observer.dart';
import '../../core/auth/qf_backend_proxy.dart';
import '../../core/auth/qf_oidc_config.dart';
import '../../core/config/api_config.dart';
import '../../core/config/qf_api_config.dart';
import '../../core/network/connectivity_cubit.dart';
import '../../core/network/debug_log_interceptor.dart';
import '../../core/network/network_info.dart';
import '../../core/network/qf_api_interceptor.dart';
import '../../core/network/retry_interceptor.dart';
import '../../core/network/qf_auth.dart';
import '../../core/quran/quran_word_service.dart';
import '../../core/scroll/scroll_position_cubit.dart';
import '../../data/datasource/auth/qf_auth_remote_data_source.dart';
import '../../presentation/auth/bloc/qf_auth_bloc.dart';
import '../../presentation/home_screen/bloc/home_bloc.dart';
import '../../theme/bloc/theme_bloc.dart';
import '../../core/services/home_widget_service.dart';
import '../../core/services/deep_link_handler.dart';
import '../injection_container.dart';

void registerCoreDependencies() {
  sl.registerLazySingleton<QfOidcConfig>(
    () => QfOidcConfig.fromQfApiConfig(const QfApiConfig()),
  );

  sl.registerLazySingleton<QfBackendTokenProxy>(() {
    final oidcConfig = sl<QfOidcConfig>();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    if (QfApiConfig.backendExchangeUrl.isNotEmpty) {
      return QfDioBackendTokenProxy(dio: dio, config: oidcConfig);
    }

    if (oidcConfig.isConfidential) {
      dio.options.baseUrl = oidcConfig.endpoints.apiBaseUrl;
      return QfDioBackendTokenProxy(dio: dio, config: oidcConfig);
    }

    return QfNoopBackendTokenProxy();
  });

  sl.registerLazySingleton<QfAuthRemoteDataSource>(
    () => QfAuthRemoteDataSourceImpl(
      oidcConfig: sl<QfOidcConfig>(),
      backendProxy: sl<QfBackendTokenProxy>(),
    ),
  );

  sl.registerLazySingleton<QfAuthService>(() => QfAuthService());

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio();
    if (ApiConfig.useQfContent) {
      dio.options.baseUrl = ApiConfig.qfContentBase;
    } else {
      dio.options.baseUrl = ApiConfig.quranComBase;
    }
    dio.options.connectTimeout = const Duration(seconds: 7);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    if (!kReleaseMode) dio.interceptors.add(DebugLogInterceptor());

    dio.interceptors.add(QfApiInterceptor(sl<QfAuthRemoteDataSource>(), dio));
    dio.interceptors.add(RetryInterceptor(dio));

    if (ApiConfig.clientId.isNotEmpty && ApiConfig.clientSecret.isNotEmpty) {
      dio.interceptors.add(QfAuthInterceptor(sl<QfAuthService>()));
    }

    return dio;
  });

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(Connectivity()));

  sl.registerLazySingleton(
    () => ConnectivityCubit(connectivity: Connectivity(), dio: sl<Dio>()),
  );

  sl.registerLazySingleton(() => ThemeBloc());
  sl.registerLazySingleton(() => QfAuthBloc(authRemoteDataSource: sl()));
  sl.registerLazySingleton(() => ScrollPositionCubit());
  sl.registerFactory(() => HomeBloc());
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => AnalyticsRouteObserver());

  sl.registerLazySingleton<HomeWidgetService>(HomeWidgetService.new);
  sl.registerLazySingleton<DeepLinkHandler>(DeepLinkHandler.new);
  sl.registerLazySingleton<QuranWordService>(QuranWordService.new);
}
