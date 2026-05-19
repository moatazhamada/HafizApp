import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/sync_with_qf.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/auth/bloc/qf_auth_bloc.dart';

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
      (failure) {
        if (failure is InsufficientScopeFailure) {
          try {
            sl<QfAuthBloc>().add(QfAuthReLoginRequested());
          } catch (e) {
            Logger.warning('Failed to dispatch re-login: $e', feature: 'CloudSync');
          }
        }
        emit(QfSyncError(_mapFailureToMessage(failure)));
      },
      (syncResult) {
        PrefUtils().setQfLastSyncAt(DateTime.now());
        unawaited(sl<AnalyticsService>().logCloudSync(
          pushed: syncResult.pushed,
          pulled: syncResult.pulled,
        ));
        emit(QfSyncSuccess(pushed: syncResult.pushed, pulled: syncResult.pulled));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is InsufficientScopeFailure) {
      return failure.errorMessage.tr;
    }
    return 'msg_sync_failed'.tr;
  }
}
