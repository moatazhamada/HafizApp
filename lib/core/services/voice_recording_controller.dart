import 'package:hafiz_app/core/utils/logger.dart';

/// Tracks active voice recording sessions and allows stopping them
/// when the app is backgrounded or otherwise interrupted.
class VoiceRecordingController {
  static final Map<String, Future<void> Function()> _sessions = {};
  static final _sessionsLock = Object();

  static void register(String id, Future<void> Function() stop) {
    _sessions[id] = stop;
  }

  static void unregister(String id) {
    _sessions.remove(id);
  }

  /// Returns true if any recording sessions are currently active.
  static bool get isRecording => _sessions.isNotEmpty;

  /// Stops all active recording sessions.
  static Future<void> stopAll() async {
    if (_sessions.isEmpty) return;
    Logger.info(
      'App backgrounded — stopping ${_sessions.length} voice session(s)',
      feature: 'Lifecycle',
    );
    final stops = _sessions.values.map((stop) async {
      try {
        await stop();
      } catch (e) {
        Logger.warning('Failed to stop voice session: $e', feature: 'Lifecycle');
      }
    });
    await Future.wait(stops);
    _sessions.clear();
  }
}
