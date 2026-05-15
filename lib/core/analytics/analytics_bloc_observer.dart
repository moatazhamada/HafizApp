import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:hafiz_app/core/utils/logger.dart';

import '../../injection_container.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';

/// A global [BlocObserver] that automatically tracks BLoC lifecycle
/// and key state transitions via Firebase Analytics.
///
/// This is the most efficient way to add analytics because it requires
/// zero changes to existing BLoCs. Register it once in `main()`:
///
/// ```dart
/// Bloc.observer = AnalyticsBlocObserver();
/// ```
class AnalyticsBlocObserver extends BlocObserver {
  final Set<String> _trackedBlocs = {};

  /// Blocs whose *error* states should be logged automatically.
  static const Set<String> _errorSensitiveBlocs = {
    'SurahBloc',
    'SearchBloc',
    'CloudSyncBloc',
    'MemorizationBloc',
    'KhatmahBloc',
    'RecitationSessionBloc',
  };

  /// Events whose firing should be logged (high-value interactions).
  static const Set<String> _trackedEvents = {
    'LoadSurahEvent',
    'SearchQueryChanged',
    'RecordReading',
    'RecordReview',
    'LoadMemorizationProgress',
    'StartRecitationSession',
    'CompleteRecitationSession',
    'QfLoginRequested',
    'QfLogoutRequested',
    'LoadBookmarksEvent',
    'AddBookmarkEvent',
    'RemoveBookmarkEvent',
  };

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    final name = bloc.runtimeType.toString();
    _trackedBlocs.add(name);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    final eventName = event.runtimeType.toString();
    if (_trackedEvents.contains(eventName)) {
      _safeLog('bloc_event', parameters: {
        'bloc': bloc.runtimeType.toString(),
        'event': eventName,
      });
    }
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final blocName = bloc.runtimeType.toString();
    final nextState = change.nextState;

    // Auto-log error states for sensitive BLoCs
    if (_errorSensitiveBlocs.contains(blocName)) {
      final stateName = nextState.runtimeType.toString();
      if (stateName.contains('Failure') ||
          stateName.contains('Error') ||
          stateName.contains('Failed')) {
        _safeLog(AnalyticsEvents.unexpectedError, parameters: {
          'source': blocName,
          'state': stateName,
        });
      }
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _safeLog(AnalyticsEvents.unexpectedError, parameters: {
      'source': bloc.runtimeType.toString(),
      'error_type': error.runtimeType.toString(),
    });
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _trackedBlocs.remove(bloc.runtimeType.toString());
  }

  void _safeLog(String name, {Map<String, Object>? parameters}) {
    try {
      if (sl.isRegistered<AnalyticsService>()) {
        unawaited(
          sl<AnalyticsService>().logRawEvent(name, parameters: parameters),
        );
      }
    } catch (e) {
      Logger.warning('AnalyticsBlocObserver log failed: \$e', feature: 'Analytics');
    }
  }
}
