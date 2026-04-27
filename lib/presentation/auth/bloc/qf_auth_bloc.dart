import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
      emit(QfAuthError(message: 'Failed to check auth status: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLoginRequested(
    QfAuthLoginRequested event,
    Emitter<QfAuthState> emit,
  ) async {
    emit(QfAuthLoading());
    try {
      final success = await _authRemoteDataSource.login();
      if (success) {
        final userId = await _authRemoteDataSource.getUserId();
        emit(QfAuthAuthenticated(userId: userId));
      } else {
        emit(const QfAuthError(message: 'Login was cancelled or failed.'));
      }
    } catch (e) {
      emit(QfAuthError(message: 'Login failed: ${e.toString()}'));
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
      emit(QfAuthError(message: 'Logout failed: ${e.toString()}'));
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
      emit(QfAuthError(message: 'Delete failed: ${e.toString()}'));
    }
  }
}
