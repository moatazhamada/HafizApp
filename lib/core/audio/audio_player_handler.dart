import 'dart:async';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler {
  static final AudioPlayerHandler _instance = AudioPlayerHandler._internal();
  factory AudioPlayerHandler() => _instance;

  AudioPlayerHandler._internal();

  final AudioPlayer _player = AudioPlayer();
  final StreamController<int> _currentVerseController =
      StreamController<int>.broadcast();

  int? _currentSurahId;
  List<String>? _verseUrls;
  int _currentVerseIndex = 0;
  bool _isLooping = false;
  int? _loopStart;
  int? _loopEnd;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;
  bool _isDisposed = false;
  StreamSubscription<ProcessingState>? _completionSub;
  Completer<void>? _verseCompleter;

  AudioPlayer get player => _player;
  Stream<int> get currentVerseStream => _currentVerseController.stream;
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
    _currentSurahId = surahId;
    _verseUrls = verseAudioUrls;
    _currentVerseIndex = startVerse;
    await _playCurrentVerse();
  }

  Future<void> _playCurrentVerse() async {
    if (_isDisposed || _currentSurahId == null) return;

    if (_verseUrls == null || _currentVerseIndex >= _verseUrls!.length) {
      if (_isLooping && _loopStart != null && _loopEnd != null) {
        _currentVerseIndex = _loopStart!;
        await _playCurrentVerse();
        return;
      }
      _currentVerseController.add(-1);
      return;
    }

    try {
      await _player.setUrl(_verseUrls![_currentVerseIndex]);
      if (_isDisposed || _currentSurahId == null) return;
      _currentVerseController.add(_currentVerseIndex);
      await _player.play();
      if (_isDisposed || _currentSurahId == null) return;

      await _waitForCompletion();
      if (_isDisposed || _currentSurahId == null) return;

      if (_sleepTimerEnd != null && DateTime.now().isAfter(_sleepTimerEnd!)) {
        await pause();
        _sleepTimerEnd = null;
        return;
      }

      _currentVerseIndex++;

      // If looping, wrap back to loop start when past loop end
      if (_isLooping && _loopStart != null && _loopEnd != null &&
          _currentVerseIndex > _loopEnd!) {
        _currentVerseIndex = _loopStart!;
      }

      await _playCurrentVerse();
    } catch (e) {
      if (!_isDisposed) {
        _currentVerseController.add(-1);
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
    if (_isDisposed) return;
    _isLooping = true;
    _loopStart = start;
    _loopEnd = end;
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
  }

  void cancelSleepTimer() {
    if (_isDisposed) return;
    _sleepTimerEnd = null;
    _sleepTimer?.cancel();
  }

  void seekRelative(Duration offset) {
    if (_isDisposed) return;
    _player.seek(_player.position + offset);
  }

  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    await _player.setSpeed(speed);
  }

  /// Jump to a specific verse index and start playing from there.
  Future<void> seekToVerse(int verseIndex) async {
    if (_isDisposed || _verseUrls == null) return;
    if (verseIndex < 0 || verseIndex >= _verseUrls!.length) return;
    _currentVerseIndex = verseIndex;
    await _completionSub?.cancel();
    _completionSub = null;
    if (_verseCompleter != null && !_verseCompleter!.isCompleted) {
      _verseCompleter!.complete();
    }
    _verseCompleter = null;
    await _player.stop();
    await _playCurrentVerse();
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
  }
}
