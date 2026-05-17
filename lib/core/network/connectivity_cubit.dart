import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class ConnectivityState extends Equatable {
  final bool isOnline;
  final ConnectivityResult connectionType;

  const ConnectivityState({
    this.isOnline = false,
    this.connectionType = ConnectivityResult.none,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    ConnectivityResult? connectionType,
  }) => ConnectivityState(
    isOnline: isOnline ?? this.isOnline,
    connectionType: connectionType ?? this.connectionType,
  );

  @override
  List<Object?> get props => [isOnline, connectionType];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Dio _dio;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _debounce;

  static const _reachabilityUrl = 'https://clients3.google.com/generate_204';
  static const _timeout = Duration(seconds: 4);

  ConnectivityCubit({required Connectivity connectivity, required Dio dio})
    : _connectivity = connectivity,
      _dio = dio,
      super(const ConnectivityState()) {
    _init();
  }

  Future<void> _init() async {
    final online = await _checkReachability();
    if (isClosed) return;
    emit(state.copyWith(isOnline: online));

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        final hasInterface = results.any((r) => r != ConnectivityResult.none);
        if (!hasInterface) {
          if (!isClosed) {
            emit(
              state.copyWith(
                isOnline: false,
                connectionType: ConnectivityResult.none,
              ),
            );
          }
        } else {
          final online = await _checkReachability();
          if (!isClosed) {
            emit(
              state.copyWith(
                isOnline: online,
                connectionType:
                    results.firstOrNull ?? ConnectivityResult.none,
              ),
            );
          }
        }
      });
    });
  }

  Future<bool> _checkReachability() async {
    try {
      final response = await _dio.head(
        _reachabilityUrl,
        options: Options(sendTimeout: _timeout, receiveTimeout: _timeout),
      );
      return response.statusCode == 204;
    } catch (e) {
      Logger.warning('Reachability check failed: $e', feature: 'Connectivity');
      return false;
    }
  }

  /// Manually re-check connectivity (e.g. pull-to-refresh).
  Future<void> recheck() async {
    final online = await _checkReachability();
    if (!isClosed) {
      emit(state.copyWith(isOnline: online));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
