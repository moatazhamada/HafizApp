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
    _currentSurahId = surahId;
    _verseUrls = verseAudioUrls;
    _currentVerseIndex = startVerse;
    await _playCurrentVerse();
  }

  Future<void> _playCurrentVerse() async {
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
      _currentVerseController.add(_currentVerseIndex);
      await _player.play();

      if (_sleepTimerEnd != null && DateTime.now().isAfter(_sleepTimerEnd!)) {
        await pause();
        _sleepTimerEnd = null;
        return;
      }

      _currentVerseIndex++;
      await _playCurrentVerse();
    } catch (e) {
      _currentVerseController.add(-1);
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSurahId = null;
    _verseUrls = null;
    _currentVerseIndex = 0;
    _currentVerseController.add(-1);
  }

  void setLoopRange(int start, int end) {
    _isLooping = true;
    _loopStart = start;
    _loopEnd = end;
  }

  void clearLoop() {
    _isLooping = false;
    _loopStart = null;
    _loopEnd = null;
  }

  void setSleepTimer(Duration duration) {
    _sleepTimerEnd = DateTime.now().add(duration);
  }

  void cancelSleepTimer() {
    _sleepTimerEnd = null;
    _sleepTimer?.cancel();
  }

  void seekRelative(Duration offset) {
    _player.seek(_player.position + offset);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _currentVerseController.close();
  }
}
