/// Playback states for audio player
enum AudioPlaybackState {
  initial,
  loading,
  ready,
  paused,
  playing,
  error,
  downloading,
}

/// Playback speed presets
enum PlaybackSpeed {
  slow0_5(0.5, '0.5x'),
  slow0_75(0.75, '0.75x'),
  normal1_0(1.0, '1x'),
  fast1_25(1.25, '1.25x'),
  fast1_5(1.5, '1.5x');

  final double value;
  final String label;

  const PlaybackSpeed(this.value, this.label);

  static PlaybackSpeed fromValue(double value) {
    return PlaybackSpeed.values.firstWhere(
      (speed) => speed.value == value,
      orElse: () => PlaybackSpeed.normal1_0,
    );
  }

  static List<double> get presets {
    return PlaybackSpeed.values.map((s) => s.value).toList();
  }
}
