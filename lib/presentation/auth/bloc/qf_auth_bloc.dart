import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';

part 'qf_auth_event.dart';
part 'qf_auth_state.dart';

class QfAuthBloc extends Bloc<QfAuthEvent, QfAuthState> {
  final QfAuthRemoteDataSource _authRemoteDataSource;

  QfAuthBloc({required QfAuthRemoteDataSource authRemoteDataSource})
      : _authRemoteDataSource = authRemoteDataSource,
        super(QfAuthInitial()) {
    on<QfAuthCheckRequested>(_onAuthCheckRequested);
    on<QfAuthLoginRequested>(_onAuthLoginRequested);
    on<QfAuthLogoutRequested>(_onAuthLogoutRequested);
    on<QfAuthDeleteDataRequested>(_onAuthDeleteDataRequested);
  }

  Future<void> _onAuthCheckRequested(
    QfAuthCheckRequested event,
    Emitter<QfAuthState> emit,
  ) async {
    emit(QfAuthLoading());
    try {
      final isAuthenticated = await _authRemoteDataSource.isAuthenticated();
      if (isAuthenticated) {
        final userId = await _authRemoteDataSource.getUserId();
        emit(QfAuthAuthenticated(userId: userId));
      } else {
        emit(QfAuthUnauthenticated());
      }
    } catch (e) {
      emit(const QfAuthError(message: 'msg_connection_error'));
    }
  }

  Future<void> _onAuthLoginRequested(
    QfAuthLoginRequested event,
    Emitter<QfAuthState> emit,
  ) async {
    if (QfApiConfig.clientId.isEmpty) {
      emit(const QfAuthError(message: 'msg_login_not_configured'));
      return;
    }

    emit(QfAuthLoading());
    try {
      final success = await _authRemoteDataSource.login();
      if (success) {
        final userId = await _authRemoteDataSource.getUserId();
        emit(QfAuthAuthenticated(userId: userId));
      } else {
        emit(const QfAuthError(message: 'msg_login_cancelled'));
      }
    } on PlatformException catch (e) {
      final code = e.code;
      if (code.contains('cancelled') || code.contains('cancel')) {
        emit(const QfAuthError(message: 'msg_login_cancelled'));
      } else if (code.contains('network') || code.contains('timeout')) {
        emit(const QfAuthError(message: 'msg_connection_error'));
      } else {
        emit(const QfAuthError(message: 'msg_unexpected_error'));
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('timeout') || msg.contains('connection')) {
        emit(const QfAuthError(message: 'msg_connection_error'));
      } else if (msg.contains('cancelled') || msg.contains('cancel')) {
        emit(const QfAuthError(message: 'msg_login_cancelled'));
      } else {
        emit(const QfAuthError(message: 'msg_unexpected_error'));
      }
    }
  }

  Future<void> _onAuthLogoutRequested(
    QfAuthLogoutRequested event,
    Emitter<QfAuthState> emit,
  ) async {
    emit(QfAuthLoading());
    try {
      await _authRemoteDataSource.logout();
      emit(QfAuthUnauthenticated());
    } catch (e) {
      emit(const QfAuthError(message: 'msg_unexpected_error'));
    }
  }

  Future<void> _onAuthDeleteDataRequested(
    QfAuthDeleteDataRequested event,
    Emitter<QfAuthState> emit,
  ) async {
    emit(QfAuthLoading());
    try {
      await _authRemoteDataSource.revokeAndDeleteData();
      // Clear sync timestamp
      await PrefUtils().setQfLastSyncAt(DateTime(2000));
      emit(QfAuthUnauthenticated());
    } catch (e) {
      emit(const QfAuthError(message: 'msg_unexpected_error'));
    }
  }
}
