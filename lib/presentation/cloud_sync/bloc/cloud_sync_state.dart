part of 'cloud_sync_bloc.dart';

abstract class CloudSyncState extends Equatable {
  const CloudSyncState();

  @override
  List<Object> get props => [];
}

class CloudSyncInitial extends CloudSyncState {}

class CloudSyncLoading extends CloudSyncState {}

class CloudSyncAuthenticated extends CloudSyncState {
  final bool isAuthenticated;

  const CloudSyncAuthenticated(this.isAuthenticated);

  @override
  List<Object> get props => [isAuthenticated];
}

class CloudSyncSuccess extends CloudSyncState {
  final String message;

  const CloudSyncSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class CloudSyncError extends CloudSyncState {
  final String message;

  const CloudSyncError(this.message);

  @override
  List<Object> get props => [message];
}

class QfSyncLoading extends CloudSyncState {}

class QfSyncSuccess extends CloudSyncState {
  final int bookmarkCount;

  const QfSyncSuccess(this.bookmarkCount);

  @override
  List<Object> get props => [bookmarkCount];
}

class QfSyncError extends CloudSyncState {
  final String message;

  const QfSyncError(this.message);

  @override
  List<Object> get props => [message];
}
