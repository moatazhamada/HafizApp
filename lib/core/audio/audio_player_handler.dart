import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class AudioPlayerHandler {
  static AudioPlayerHandler? _instance;
  factory AudioPlayerHandler() => _instance ??= AudioPlayerHandler._internal();

  AudioPlayerHandler._internal() {
    _configureAudioSession();
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
    } catch (e) {
      Logger.warning('Audio session configuration failed: $e', feature: 'Audio');
    }
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<int> _currentVerseController =
      StreamController<int>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  int? _currentSurahId;
  List<String>? _verseUrls;
  int _currentVerseIndex = 0;
  bool _isLooping = false;
  int? _loopStart;
  int? _loopEnd;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;
  bool _isDisposed = false;
  int _playGeneration = 0;
  StreamSubscription<ProcessingState>? _completionSub;
  Completer<void>? _verseCompleter;

  static const String _prefSurahId = 'audio_last_surah_id';
  static const String _prefVerseIndex = 'audio_last_verse_index';

  AudioPlayer get player => _player;
  Stream<int> get currentVerseStream => _currentVerseController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get playingStateStream =>
      _player.playerStateStream.map((state) => state.playing);
  int get currentVerseIndex => _currentVerseIndex;
  int? get currentSurahId => _currentSurahId;
  bool get isPlaying => _player.playing;
  DateTime? get sleepTimerEnd => _sleepTimerEnd;
  bool get isLooping => _isLooping;

  Future<void> playSurah({
    required int surahId,
    required List<String> verseAudioUrls,
    int startVerse = 0,
  }) async {
    if (_isDisposed) return;
    _playGeneration++;
    await _completionSub?.cancel();
    _completionSub = null;
    if (_verseCompleter != null && !_verseCompleter!.isCompleted) {
      _verseCompleter!.complete();
    }
    _verseCompleter = null;
    await _player.stop();
    _currentSurahId = surahId;
    _verseUrls = verseAudioUrls;
    _currentVerseIndex = startVerse;
    unawaited(_playCurrentVerse());
  }

  Future<void> _playCurrentVerse() async {
    if (_isDisposed || _currentSurahId == null) return;

    final generation = _playGeneration;

    if (_verseUrls == null || _currentVerseIndex >= _verseUrls!.length) {
      if (_isLooping && _loopStart != null && _loopEnd != null) {
        _currentVerseIndex = _loopStart!;
        unawaited(_playCurrentVerse());
        return;
      }
      _currentVerseController.add(-1);
      return;
    }

    try {
      await _player.setUrl(_verseUrls![_currentVerseIndex]);
      if (_isDisposed || generation != _playGeneration) return;
      _currentVerseController.add(_currentVerseIndex);
      unawaited(_saveState());
      await _player.play();
      if (_isDisposed || generation != _playGeneration) return;

      await _waitForCompletion();
      if (_isDisposed || generation != _playGeneration) return;

      if (_sleepTimerEnd != null && DateTime.now().isAfter(_sleepTimerEnd!)) {
        await pause();
        _sleepTimerEnd = null;
        return;
      }

      _currentVerseIndex++;

      // If looping, wrap back to loop start when past loop end
      if (_isLooping &&
          _loopStart != null &&
          _loopEnd != null &&
          _currentVerseIndex > _loopEnd!) {
        _currentVerseIndex = _loopStart!;
      }

      unawaited(_playCurrentVerse());
    } catch (e) {
      if (!_isDisposed && generation == _playGeneration) {
        _currentVerseController.add(-1);
        _errorController.add('msg_audio_playback_error');
      }
    }
  }

  Future<void> _waitForCompletion() async {
    await _completionSub?.cancel();
    _verseCompleter = Completer<void>();
    _completionSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_verseCompleter != null && !_verseCompleter!.isCompleted) {
          _verseCompleter!.complete();
        }
      }
    });
    await _verseCompleter!.future;
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    await _player.pause();
  }

  Future<void> resume() async {
    if (_isDisposed) return;
    await _player.play();
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    await _completionSub?.cancel();
    _completionSub = null;
    _currentSurahId = null;
    _verseUrls = null;
    _currentVerseIndex = 0;
    if (_verseCompleter != null && !_verseCompleter!.isCompleted) {
      _verseCompleter!.complete();
    }
    _verseCompleter = null;
    await _player.stop();
    _currentVerseController.add(-1);
  }

  void setLoopRange(int start, int end) {
    if (_isDisposed || _verseUrls == null || _verseUrls!.isEmpty) return;
    final maxIndex = _verseUrls!.length - 1;
    final validStart = start.clamp(0, maxIndex);
    final validEnd = end.clamp(validStart, maxIndex);
    _isLooping = true;
    _loopStart = validStart;
    _loopEnd = validEnd;
  }

  void clearLoop() {
    if (_isDisposed) return;
    _isLooping = false;
    _loopStart = null;
    _loopEnd = null;
  }

  void setSleepTimer(Duration duration) {
    if (_isDisposed) return;
    _sleepTimerEnd = DateTime.now().add(duration);
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () async {
      if (_sleepTimerEnd != null && DateTime.now().isAfter(_sleepTimerEnd!)) {
        await pause();
        _sleepTimerEnd = null;
      }
    });
  }

  void cancelSleepTimer() {
    if (_isDisposed) return;
    _sleepTimerEnd = null;
    _sleepTimer?.cancel();
  }

  void seekRelative(Duration offset) {
    if (_isDisposed) return;
    final newPosition = _player.position + offset;

    // Cross-verse seek backward
    if (newPosition < Duration.zero && _currentVerseIndex > 0) {
      _seekToVerseIndex(_currentVerseIndex - 1);
      return;
    }

    // Cross-verse seek forward
    final maxDuration = _player.duration;
    if (maxDuration != null &&
        _verseUrls != null &&
        newPosition > maxDuration &&
        _currentVerseIndex < _verseUrls!.length - 1) {
      _seekToVerseIndex(_currentVerseIndex + 1);
      return;
    }

    final clamped = newPosition < Duration.zero
        ? Duration.zero
        : (maxDuration != null && newPosition > maxDuration
            ? maxDuration
            : newPosition);
    _player.seek(clamped);
  }

  void _seekToVerseIndex(int index) {
    _playGeneration++;
    _currentVerseIndex = index;
    unawaited(_completionSub?.cancel());
    _completionSub = null;
    if (_verseCompleter != null && !_verseCompleter!.isCompleted) {
      _verseCompleter!.complete();
    }
    _verseCompleter = null;
    unawaited(_player.stop().then((_) => _playCurrentVerse()));
  }

  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    await _player.setSpeed(speed);
  }

  /// Jump to a specific verse index and start playing from there.
  Future<void> seekToVerse(int verseIndex) async {
    if (_isDisposed || _verseUrls == null) return;
    if (verseIndex < 0 || verseIndex >= _verseUrls!.length) return;
    _playGeneration++;
    _currentVerseIndex = verseIndex;
    await _completionSub?.cancel();
    _completionSub = null;
    if (_verseCompleter != null && !_verseCompleter!.isCompleted) {
      _verseCompleter!.complete();
    }
    _verseCompleter = null;
    await _player.stop();
    unawaited(_playCurrentVerse());
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentSurahId != null) {
        await prefs.setInt(_prefSurahId, _currentSurahId!);
        await prefs.setInt(_prefVerseIndex, _currentVerseIndex);
      }
    } catch (e) {
      // Ignore persistence errors
    }
  }

  Future<Map<String, int>?> getLastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surahId = prefs.getInt(_prefSurahId);
      final verseIndex = prefs.getInt(_prefVerseIndex);
      if (surahId != null && verseIndex != null) {
        return {'surahId': surahId, 'verseIndex': verseIndex};
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _completionSub?.cancel();
    _completionSub = null;
    if (_verseCompleter != null && !_verseCompleter!.isCompleted) {
      _verseCompleter!.complete();
    }
    _verseCompleter = null;
    await _player.dispose();
    await _currentVerseController.close();
    await _errorController.close();
    // Reset the singleton so it can be recreated if needed.
    _instance = null;
  }
}
