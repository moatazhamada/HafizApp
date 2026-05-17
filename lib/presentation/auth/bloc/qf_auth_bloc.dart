import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/auth/qf_backend_proxy.dart';
import 'package:hafiz_app/core/auth/qf_token_validator.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';
import 'package:hafiz_app/domain/entities/qf_user_profile.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/utils/logger.dart';

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
    on<QfAuthReLoginRequested>(_onAuthReLoginRequested);
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
        final profile = await _authRemoteDataSource.getUserProfile();
        emit(QfAuthAuthenticated(userId: userId, profile: profile));
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
        final profile = await _authRemoteDataSource.getUserProfile();
        unawaited(sl<AnalyticsService>().logQfLogin(userId: userId));
        emit(QfAuthAuthenticated(userId: userId, isNewLogin: true, profile: profile));
      } else {
        emit(const QfAuthError(message: 'msg_login_cancelled'));
      }
    } on QfTokenValidationError catch (e) {
      emit(QfAuthError(message: e.message));
    } on QfBackendTokenExchangeException {
      emit(const QfAuthError(message: 'msg_backend_auth_failed'));
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
      return;
    }
    // Best-effort cleanup after successful logout.
    try {
      await PrefUtils().setQfPrefSyncPrompted(false);
    } catch (e) {
      Logger.warning('QF pref sync reset failed: $e', feature: 'Auth');
    }
    try {
      unawaited(sl<AnalyticsService>().logQfLogout());
    } catch (e) {
      Logger.warning('Analytics logout log failed: $e', feature: 'Auth');
    }
  }

  Future<void> _onAuthReLoginRequested(
    QfAuthReLoginRequested event,
    Emitter<QfAuthState> emit,
  ) async {
    Logger.info('Re-login requested due to insufficient scope', feature: 'Auth');
    try {
      await _authRemoteDataSource.logout();
    } catch (_) {}
    emit(QfAuthUnauthenticated());
    add(QfAuthLoginRequested());
  }

  Future<void> _onAuthDeleteDataRequested(
    QfAuthDeleteDataRequested event,
    Emitter<QfAuthState> emit,
  ) async {
    emit(QfAuthLoading());
    try {
      await _authRemoteDataSource.revokeAndDeleteData();
      await PrefUtils().setQfLastSyncAt(DateTime(2000));
      emit(QfAuthUnauthenticated());
    } catch (e) {
      emit(const QfAuthError(message: 'msg_unexpected_error'));
    }
  }
}
