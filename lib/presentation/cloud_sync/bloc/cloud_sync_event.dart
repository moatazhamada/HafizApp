part of 'cloud_sync_bloc.dart';

abstract class CloudSyncEvent extends Equatable {
  const CloudSyncEvent();

  @override
  List<Object> get props => [];
}

class CheckAuthStatusEvent extends CloudSyncEvent {}

class SignInEvent extends CloudSyncEvent {}

class SignOutEvent extends CloudSyncEvent {}

class SyncToCloudEvent extends CloudSyncEvent {}

class SyncFromCloudEvent extends CloudSyncEvent {}

class SyncBidirectionalEvent extends CloudSyncEvent {}
