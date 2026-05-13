import 'package:flutter/material.dart';
import 'package:hafiz_app/core/audio/audio_player_handler.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Observes app lifecycle transitions and takes appropriate action:
/// - Pauses audio when the app is backgrounded
/// - Logs lifecycle changes for diagnostics
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onBackgrounded();
        break;
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onBackgrounded() {
    try {
      final handler = AudioPlayerHandler();
      if (handler.isPlaying) {
        handler.pause();
        Logger.info(
          'App backgrounded — audio paused',
          feature: 'Lifecycle',
        );
      }
    } catch (e) {
      Logger.warning('Failed to pause audio on background: $e', feature: 'Lifecycle');
    }
  }

  void _onResumed() {
    Logger.info('App resumed', feature: 'Lifecycle');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
