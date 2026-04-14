import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/localization/app_localization.dart';
import 'package:hafiz_app/domain/repository/cloud_sync_repository.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/cloud_sync_usecase.dart';

part 'cloud_sync_event.dart';
part 'cloud_sync_state.dart';

class CloudSyncBloc extends Bloc<CloudSyncEvent, CloudSyncState> {
  final PerformCloudSync performCloudSync;
  final CheckCloudSyncAuth checkCloudSyncAuth;
  final SignInCloudSync signInCloudSync;
  final SignOutCloudSync signOutCloudSync;

  CloudSyncBloc({
    required this.performCloudSync,
    required this.checkCloudSyncAuth,
    required this.signInCloudSync,
    required this.signOutCloudSync,
  }) : super(CloudSyncInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInEvent>(_onSignIn);
    on<SignOutEvent>(_onSignOut);
    on<SyncToCloudEvent>(_onSyncToCloud);
    on<SyncFromCloudEvent>(_onSyncFromCloud);
    on<SyncBidirectionalEvent>(_onSyncBidirectional);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(CloudSyncLoading());
    final result = await checkCloudSyncAuth(NoParams());
    result.fold(
      (failure) => emit(CloudSyncError(_mapFailureToMessage(failure))),
      (isAuthenticated) => emit(CloudSyncAuthenticated(isAuthenticated)),
    );
  }

  Future<void> _onSignIn(
    SignInEvent event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(CloudSyncLoading());
    final result = await signInCloudSync(NoParams());
    result.fold(
      (failure) => emit(CloudSyncError(_mapFailureToMessage(failure))),
      (_) => emit(const CloudSyncAuthenticated(true)),
    );
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(CloudSyncLoading());
    final result = await signOutCloudSync(NoParams());
    result.fold(
      (failure) => emit(CloudSyncError(_mapFailureToMessage(failure))),
      (_) => emit(const CloudSyncAuthenticated(false)),
    );
  }

  Future<void> _onSyncToCloud(
    SyncToCloudEvent event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(CloudSyncLoading());
    final result = await performCloudSync(
      const ParamsCloudSync(direction: SyncDirection.localToRemote),
    );
    result.fold(
      (failure) => emit(CloudSyncError(_mapFailureToMessage(failure))),
      (_) => emit(CloudSyncSuccess('lbl_cloud_sync'.tr)),
    );
  }

  Future<void> _onSyncFromCloud(
    SyncFromCloudEvent event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(CloudSyncLoading());
    final result = await performCloudSync(
      const ParamsCloudSync(direction: SyncDirection.remoteToLocal),
    );
    result.fold(
      (failure) => emit(CloudSyncError(_mapFailureToMessage(failure))),
      (_) => emit(CloudSyncSuccess('lbl_cloud_sync'.tr)),
    );
  }

  Future<void> _onSyncBidirectional(
    SyncBidirectionalEvent event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(CloudSyncLoading());
    final result = await performCloudSync(
      const ParamsCloudSync(direction: SyncDirection.bidirectional),
    );
    result.fold(
      (failure) => emit(CloudSyncError(_mapFailureToMessage(failure))),
      (_) => emit(CloudSyncSuccess('msg_sync_bidirectional_complete'.tr)),
    );
  }

  String _mapFailureToMessage(Failure _) {
    return 'msg_cloud_sync_error'.tr;
  }
}
