import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Background audio handler for Quran recitation
/// Provides media controls, notification, and background playback
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  // Store audio sources for playlist management
  List<AudioSource> _audioSources = [];

  // Stream for verse highlighting
  final _currentVerseController = BehaviorSubject<int>.seeded(0);
  Stream<int> get currentVerseStream => _currentVerseController.stream;
  int get currentVerse => _currentVerseController.value;

  // Stream subscriptions - stored to properly cancel them
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  AudioPlayerHandler() {
    _init();
  }

  void _init() {
    // Listen to player state changes
    _playbackEventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    // Listen to position updates for verse highlighting
    _positionSubscription = _player.positionStream.listen((position) {
      _updateCurrentVerse(position);
    });

    // Listen to processing state
    _processingStateSubscription = _player.processingStateStream.listen((
      state,
    ) {
      if (state == ProcessingState.completed) {
        // Move to next item if available
        if (_player.hasNext) {
          skipToNext();
        } else {
          stop();
        }
      }
    });
  }

  /// Load Surah audio with verse-by-verse highlighting
  Future<void> loadSurah({
    required int surahId,
    required String surahName,
    required String reciter,
    required List<String> verseUrls,
    required List<Duration> verseDurations,
    required String artworkUrl,
  }) async {
    await stop();

    // Create media items for each verse
    final mediaItems = <MediaItem>[];
    _audioSources = [];

    for (int i = 0; i < verseUrls.length; i++) {
      final mediaItem = MediaItem(
        id: verseUrls[i],
        title: '$surahName - Verse ${i + 1}',
        album: surahName,
        artist: reciter,
        artUri: Uri.parse(artworkUrl),
        duration: verseDurations[i],
        extras: {'surahId': surahId, 'verseNumber': i + 1},
      );

      mediaItems.add(mediaItem);
      _audioSources.add(
        AudioSource.uri(Uri.parse(verseUrls[i]), tag: mediaItem),
      );
    }

    // Update queue
    queue.add(mediaItems);

    // Set audio sources using the modern API
    await _player.setAudioSources(
      _audioSources,
      initialIndex: 0,
      initialPosition: Duration.zero,
    );

    // Set initial media item
    mediaItem.add(mediaItems.first);
  }

  /// Load full Surah continuous audio
  Future<void> loadSurahContinuous({
    required int surahId,
    required String surahName,
    required String reciter,
    required String audioUrl,
    required Duration duration,
    required List<Duration> verseTimestamps,
    required String artworkUrl,
  }) async {
    await stop();

    final mediaItem = MediaItem(
      id: audioUrl,
      title: surahName,
      album: 'Quran',
      artist: reciter,
      artUri: Uri.parse(artworkUrl),
      duration: duration,
      extras: {
        'surahId': surahId,
        'verseTimestamps': verseTimestamps
            .map((d) => d.inMilliseconds)
            .toList(),
        'isContinuous': true,
      },
    );

    queue.add([mediaItem]);

    final source = AudioSource.uri(Uri.parse(audioUrl), tag: mediaItem);
    _audioSources = [source];

    await _player.setAudioSource(source);

    this.mediaItem.add(mediaItem);

    // Store verse timestamps for highlighting
    _verseTimestamps = verseTimestamps;
  }

  List<Duration> _verseTimestamps = [];

  void _updateCurrentVerse(Duration position) {
    if (_verseTimestamps.isEmpty) {
      final currentIndex = _player.currentIndex;
      if (currentIndex != null &&
          currentIndex != _currentVerseController.value) {
        _currentVerseController.add(currentIndex + 1);
      }
      return;
    }

    // Find current verse based on timestamps.
    // Timestamps are treated as verse end boundaries.
    var verse = _verseTimestamps.length;
    for (int i = 0; i < _verseTimestamps.length; i++) {
      if (position < _verseTimestamps[i]) {
        verse = i + 1;
        break;
      }
    }

    if (verse != _currentVerseController.value) {
      _currentVerseController.add(verse);
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentVerseController.add(0);
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      final index = _player.currentIndex ?? 0;
      mediaItem.add(queue.value[index]);
      _currentVerseController.add(index + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      final index = _player.currentIndex ?? 0;
      mediaItem.add(queue.value[index]);
      _currentVerseController.add(index + 1);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  /// Seek to specific verse
  Future<void> seekToVerse(int verseNumber) async {
    if (_verseTimestamps.isNotEmpty && verseNumber <= _verseTimestamps.length) {
      final position = verseNumber > 1
          ? _verseTimestamps[verseNumber - 2]
          : Duration.zero;
      await seek(position);
      _currentVerseController.add(verseNumber);
    } else {
      // For verse-by-verse mode
      await _player.seek(Duration.zero, index: verseNumber - 1);
      _currentVerseController.add(verseNumber);
    }
  }

  /// Loop specific verse range (for memorization)
  Future<void> setLoopRange(int startVerse, int endVerse) async {
    if (_verseTimestamps.isNotEmpty) {
      // For continuous audio - use clip audio
      final start = startVerse > 1
          ? _verseTimestamps[startVerse - 2]
          : Duration.zero;
      final end = endVerse < _verseTimestamps.length
          ? _verseTimestamps[endVerse - 1]
          : _player.duration;

      // Create clipped audio source
      final currentSource = _player.audioSource;
      if (currentSource is UriAudioSource) {
        final clipped = ClippingAudioSource(
          child: currentSource,
          start: start,
          end: end,
        );
        await _player.setAudioSource(clipped);
        await _player.setLoopMode(LoopMode.one);
      }
    } else if (_audioSources.isNotEmpty) {
      // For verse-by-verse mode - use subset of stored sources
      if (startVerse < 1 ||
          endVerse < startVerse ||
          startVerse > _audioSources.length) {
        return;
      }
      final safeEnd = endVerse.clamp(startVerse, _audioSources.length);
      final rangeSources = _audioSources.sublist(startVerse - 1, safeEnd);
      await _player.setAudioSources(rangeSources);
      await _player.setLoopMode(LoopMode.all);
    }
  }

  /// Set sleep timer
  Timer? _sleepTimer;
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () {
      stop();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }

  /// Download audio for offline
  Future<void> downloadAudio(String url, String savePath) async {
    // Implementation would use dio or http to download
    // and save to local storage
  }

  /// Get current playback speed
  double get speed => _player.speed;

  /// Get duration
  Duration? get duration => _player.duration;

  /// Get current position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Get buffered position
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Get playing state
  bool get isPlaying => _player.playing;

  void _broadcastState() {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _getProcessingState(),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }

  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> dispose() async {
    // Cancel all stream subscriptions
    await _playbackEventSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _processingStateSubscription?.cancel();

    _sleepTimer?.cancel();
    _audioSources.clear();
    await _player.dispose();
    await _currentVerseController.close();

    // Call parent dispose
    await super.stop();
  }
}
