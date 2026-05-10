part of 'cloud_sync_bloc.dart';

abstract class CloudSyncState extends Equatable {
  const CloudSyncState();

  @override
  List<Object> get props => [];
}

class CloudSyncInitial extends CloudSyncState {}

class QfSyncLoading extends CloudSyncState {}

class QfSyncSuccess extends CloudSyncState {
  final int pushed;
  final int pulled;

  const QfSyncSuccess({required this.pushed, required this.pulled});

  @override
  List<Object> get props => [pushed, pulled];
}

class QfSyncError extends CloudSyncState {
  final String message;

  const QfSyncError(this.message);

  @override
  List<Object> get props => [message];
}
