import 'package:equatable/equatable.dart';

/// Represents current audio playback state
class PlaybackState extends Equatable {
  final int? currentSurahNumber;
  final int? currentVerseNumber;
  final double playbackPositionMs;
  final double playbackSpeed;
  final bool isPaused;
  final bool isOffline;
  final String? errorMessage;

  const PlaybackState({
    this.currentSurahNumber,
    this.currentVerseNumber,
    this.playbackPositionMs = 0.0,
    this.playbackSpeed = 1.0,
    this.isPaused = true,
    this.isOffline = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    currentSurahNumber,
    currentVerseNumber,
    playbackPositionMs,
    playbackSpeed,
    isPaused,
    isOffline,
    errorMessage,
  ];

  PlaybackState copyWith({
    int? currentSurahNumber,
    int? currentVerseNumber,
    double? playbackPositionMs,
    double? playbackSpeed,
    bool? isPaused,
    bool? isOffline,
    String? errorMessage,
  }) {
    return PlaybackState(
      currentSurahNumber: currentSurahNumber ?? this.currentSurahNumber,
      currentVerseNumber: currentVerseNumber ?? this.currentVerseNumber,
      playbackPositionMs: playbackPositionMs ?? this.playbackPositionMs,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isPaused: isPaused ?? this.isPaused,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
    );
  }
}
