part of 'cloud_sync_bloc.dart';

abstract class CloudSyncEvent extends Equatable {
  const CloudSyncEvent();

  @override
  List<Object> get props => [];
}

class SyncWithQfEvent extends CloudSyncEvent {}
