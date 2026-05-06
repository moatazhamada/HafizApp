import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/analytics_route_observer.dart';
import '../../core/config/api_config.dart';
import '../../core/network/network_info.dart';
import '../../core/network/qf_api_interceptor.dart';
import '../../core/network/qf_auth.dart';
import '../../core/scroll/scroll_position_cubit.dart';
import '../../data/datasource/auth/qf_auth_remote_data_source.dart';
import '../../presentation/auth/bloc/qf_auth_bloc.dart';
import '../../presentation/home_screen/bloc/home_bloc.dart';
import '../../theme/bloc/theme_bloc.dart';
import '../../core/services/home_widget_service.dart';
import '../../core/services/deep_link_handler.dart';
import '../injection_container.dart';

void registerCoreDependencies() {
  sl.registerLazySingleton<QfAuthRemoteDataSource>(
    () => QfAuthRemoteDataSourceImpl(),
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

    dio.interceptors.add(QfApiInterceptor(sl<QfAuthRemoteDataSource>(), dio));

    if (ApiConfig.clientId.isNotEmpty && ApiConfig.clientSecret.isNotEmpty) {
      dio.interceptors.add(QfAuthInterceptor(sl<QfAuthService>()));
    }

    return dio;
  });

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(Connectivity()));

  sl.registerLazySingleton(() => ThemeBloc());
  sl.registerLazySingleton(() => QfAuthBloc(authRemoteDataSource: sl()));
  sl.registerLazySingleton(() => ScrollPositionCubit());
  sl.registerFactory(() => HomeBloc());
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => AnalyticsRouteObserver());

  sl.registerLazySingleton<HomeWidgetService>(HomeWidgetService.new);
  sl.registerLazySingleton<DeepLinkHandler>(DeepLinkHandler.new);
}
