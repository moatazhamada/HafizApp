import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'audio_player_handler.dart';
import '../quran_index/quran_surah.dart';

/// Bridges the existing [AudioPlayerHandler] with the platform media session
/// so that playback controls appear in the notification (Android) and Control
/// Center / lock screen (iOS).
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayerHandler _audioPlayer = AudioPlayerHandler();
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _verseSub;
  StreamSubscription? _durationSub;

  QuranAudioHandler() {
    _init();
  }

  void _init() {
    // Update playback controls & processing state
    _playerStateSub = _audioPlayer.player.playerStateStream.listen((state) {
      _updatePlaybackState(state);
    });

    // Throttled position updates for the notification progress bar
    _positionSub = _audioPlayer.player.positionStream
        .throttleTime(const Duration(seconds: 1))
        .listen((position) {
      _updatePlaybackState(
        _audioPlayer.player.playerState,
        position: position,
      );
    });

    // Update media item when the current verse changes
    _verseSub = _audioPlayer.currentVerseStream.listen((verseIndex) {
      _updateMediaItem(verseIndex);
    });

    // Update duration when the audio file loads
    _durationSub = _audioPlayer.player.durationStream.listen((duration) {
      _updateMediaItem(_audioPlayer.currentVerseIndex, duration: duration);
    });
  }

  void _updatePlaybackState(PlayerState state, {Duration? position}) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        if (state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[state.processingState]!,
      playing: state.playing,
      updatePosition: position ?? _audioPlayer.player.position,
      bufferedPosition: _audioPlayer.player.bufferedPosition,
      speed: _audioPlayer.player.speed,
    ));
  }

  void _updateMediaItem(int verseIndex, {Duration? duration}) {
    final surahId = _audioPlayer.currentSurahId;
    if (surahId == null || verseIndex < 0) {
      mediaItem.add(null);
      return;
    }

    final surah = QuranIndex.quranSurahs.firstWhere(
      (s) => s.id == surahId,
      orElse: () => Surah(surahId, 'Surah $surahId', 'سورة $surahId'),
    );

    mediaItem.add(MediaItem(
      id: '${surah.id}_$verseIndex',
      title: surah.nameArabic,
      artist: 'Verse ${verseIndex + 1}',
      album: 'Quran',
      duration: duration,
    ));
  }

  @override
  Future<void> play() => _audioPlayer.resume();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _audioPlayer.player.seek(position);

  @override
  Future<void> skipToNext() async {
    final nextIndex = _audioPlayer.currentVerseIndex + 1;
    await _audioPlayer.seekToVerse(nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    final prevIndex = _audioPlayer.currentVerseIndex - 1;
    if (prevIndex >= 0) {
      await _audioPlayer.seekToVerse(prevIndex);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await _audioPlayer.stop();
    await super.onTaskRemoved();
  }

  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _verseSub?.cancel();
    await _durationSub?.cancel();
  }
}
