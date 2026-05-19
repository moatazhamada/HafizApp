import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'voice_recording_controller.dart';

/// Observes app lifecycle transitions and takes appropriate action:
/// - Stops voice recording when the app is backgrounded
/// - Logs lifecycle changes for diagnostics
///
/// Audio playback is intentionally NOT paused on backgrounding — users expect
/// Quran recitation to continue while the app is in the background.
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
      unawaited(VoiceRecordingController.stopAll());
    } catch (e) {
      Logger.warning(
        'Failed to stop voice recording on background: $e',
        feature: 'Lifecycle',
      );
    }
  }

  void _onResumed() {
    Logger.info('App resumed', feature: 'Lifecycle');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
