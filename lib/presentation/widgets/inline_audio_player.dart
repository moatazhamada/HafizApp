import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/audio/audio_player_handler.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../injection_container.dart';

/// Inline Audio Player Widget
/// A bottom sheet style player that stays on the current page
/// while playing Quran recitation with verse highlighting
class InlineAudioPlayer extends StatefulWidget {
  final Surah surah;
  final int startVerse;
  final String reciter;
  final List<String> audioUrls;
  final List<Duration> verseTimestamps;
  final Function(int verse)? onVerseChanged;
  final VoidCallback? onClose;

  const InlineAudioPlayer({
    super.key,
    required this.surah,
    required this.startVerse,
    required this.reciter,
    required this.audioUrls,
    required this.verseTimestamps,
    this.onVerseChanged,
    this.onClose,
  });

  @override
  State<InlineAudioPlayer> createState() => InlineAudioPlayerState();
}

class InlineAudioPlayerState extends State<InlineAudioPlayer> {
  AudioPlayerHandler? _audioHandler;
  StreamSubscription<int>? _currentVerseSub;
  StreamSubscription<Duration>? _positionSub;

  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentVerse = 1;
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Expansion state
  bool _isExpanded = false;

  // Scroll controller for the player content
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    try {
      _audioHandler = sl<AudioPlayerHandler>();

      // Load the audio
      if (widget.audioUrls.isNotEmpty) {
        await _audioHandler!.loadSurahContinuous(
          surahId: widget.surah.id,
          surahName: widget.surah.nameEnglish,
          reciter: widget.reciter,
          audioUrl: widget.audioUrls.first,
          duration: widget.verseTimestamps.isNotEmpty
              ? widget.verseTimestamps.last
              : Duration.zero,
          verseTimestamps: widget.verseTimestamps,
          artworkUrl: 'https://hafiz.app/assets/surah_${widget.surah.id}.png',
        );
      }

      // Listen to verse changes
      _currentVerseSub = _audioHandler!.currentVerseStream.listen((verse) {
        if (mounted) {
          setState(() => _currentVerse = verse);
          widget.onVerseChanged?.call(verse);
        }
      });

      // Listen to position
      _positionSub = _audioHandler!.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      // Listen to playback state
      _audioHandler!.playbackState.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _duration = _audioHandler?.duration ?? Duration.zero;
          });
        }
      });

      // Seek to start verse if specified
      if (widget.startVerse > 1 && widget.verseTimestamps.isNotEmpty) {
        await _audioHandler!.seekToVerse(widget.startVerse);
        setState(() => _currentVerse = widget.startVerse);
      }

      // Auto-play
      await _audioHandler!.play();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Logger.error(
        'Error initializing inline audio: $e',
        feature: 'InlineAudioPlayer',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _audioHandler?.stop();
    _currentVerseSub?.cancel();
    _positionSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioHandler?.pause();
    } else {
      _audioHandler?.play();
    }
  }

  void _skipToNext() {
    final nextVerse = _currentVerse + 1;
    final maxVerse = widget.verseTimestamps.length;
    if (nextVerse <= maxVerse) {
      _audioHandler?.seekToVerse(nextVerse);
    }
  }

  void _skipToPrevious() {
    final prevVerse = _currentVerse - 1;
    if (prevVerse >= 1) {
      _audioHandler?.seekToVerse(prevVerse);
    } else {
      _audioHandler?.seekToVerse(1);
    }
  }

  void _seekToVerse(int verse) {
    _audioHandler?.seekToVerse(verse);
  }

  void _changeSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;

    setState(() {
      _playbackSpeed = speeds[nextIndex];
    });
    _audioHandler?.setSpeed(_playbackSpeed);
  }

  void _stop() {
    _audioHandler?.stop();
    widget.onClose?.call();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_isExpanded ? 20 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -200) {
                  setState(() => _isExpanded = true);
                } else if (details.primaryVelocity! > 200) {
                  setState(() => _isExpanded = false);
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            _isExpanded
                ? _buildExpandedPlayer(bottomPadding)
                : _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Play/Pause button
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF006754),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _togglePlayPause,
            ),
          ),
          const SizedBox(width: 12),

          // Verse info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.surah.nameEnglish,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'msg_verse_of'.tr
                      .replaceAll(
                        '{current}',
                        _currentVerse.toLocalizedNumber(context),
                      )
                      .replaceAll(
                        '{total}',
                        widget.verseTimestamps.length.toLocalizedNumber(
                          context,
                        ),
                      ),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Speed indicator
          GestureDetector(
            onTap: _changeSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Close button
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: _stop,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedPlayer(double bottomPadding) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Surah info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.surah.nameEnglish,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final position = Duration(
                      milliseconds: (value * _duration.inMilliseconds).round(),
                    );
                    _audioHandler?.seek(position);
                  },
                  activeColor: const Color(0xFF006754),
                  inactiveColor: Colors.grey[300],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current verse display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF006754).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${'lbl_ayah'.tr} ${_currentVerse.toLocalizedNumber(context)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF006754),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed button
              _buildControlButton(
                icon: Icons.speed,
                label: '${_playbackSpeed}x',
                onTap: _changeSpeed,
              ),

              // Previous verse
              _buildControlButton(
                icon: Icons.skip_previous,
                onTap: _skipToPrevious,
              ),

              // Play/Pause
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF006754),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),

              // Next verse
              _buildControlButton(icon: Icons.skip_next, onTap: _skipToNext),

              // Stop/Close
              _buildControlButton(icon: Icons.stop, onTap: _stop),
            ],
          ),
          const SizedBox(height: 16),

          // Verse quick select
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.verseTimestamps.length,
              itemBuilder: (context, index) {
                final verseNum = index + 1;
                final isCurrentVerse = verseNum == _currentVerse;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _seekToVerse(verseNum),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isCurrentVerse
                            ? const Color(0xFF006754)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        verseNum.toLocalizedNumber(context),
                        style: TextStyle(
                          color: isCurrentVerse ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          if (label != null) Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // Public methods for external control
  void play() => _audioHandler?.play();
  void pause() => _audioHandler?.pause();
  void stop() => _stop();
  int get currentVerse => _currentVerse;
  bool get isPlaying => _isPlaying;
}
