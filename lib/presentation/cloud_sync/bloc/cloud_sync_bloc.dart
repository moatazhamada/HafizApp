import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/sync_with_qf.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

part 'cloud_sync_event.dart';
part 'cloud_sync_state.dart';

class CloudSyncBloc extends Bloc<CloudSyncEvent, CloudSyncState> {
  final SyncWithQf syncWithQf;

  CloudSyncBloc({required this.syncWithQf}) : super(CloudSyncInitial()) {
    on<SyncWithQfEvent>(_onSyncWithQf);
  }

  Future<void> _onSyncWithQf(
    SyncWithQfEvent event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(QfSyncLoading());
    final result = await syncWithQf(NoParams());
    result.fold(
      (failure) => emit(QfSyncError(_mapFailureToMessage(failure))),
      (syncResult) {
        PrefUtils().setQfLastSyncAt(DateTime.now());
        emit(QfSyncSuccess(pushed: syncResult.pushed, pulled: syncResult.pulled));
      },
    );
  }

  String _mapFailureToMessage(Failure _) => 'Failed to sync with Quran.com';
}
