import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/audio/audio_player_handler.dart';
import '../../core/quran_index/quran_surah.dart';


/// Full Audio Player Screen for Surah recitation
/// Features: Play/Pause, verse highlighting, speed control, sleep timer
class AudioPlayerScreen extends StatefulWidget {
  final Surah surah;
  final int? startVerse;
  final String reciter;
  final List<String> audioUrls;
  final List<Duration> verseTimestamps;

  const AudioPlayerScreen({
    super.key,
    required this.surah,
    this.startVerse,
    required this.reciter,
    required this.audioUrls,
    required this.verseTimestamps,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  AudioPlayerHandler? _audioHandler;
  bool _isLoading = true;

  // Playback state
  double _playbackSpeed = 1.0;
  bool _isLoopingRange = false;
  int? _loopStartVerse;
  int? _loopEndVerse;

  // Sleep timer
  Timer? _sleepTimer;
  Duration? _remainingSleepTime;

  // Current verse highlighting
  int _currentVerse = 1;
  final ScrollController _verseScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    try {
      // Initialize audio service
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.hafizapp.audio',
          androidNotificationChannelName: 'Quran Recitation',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      // Load surah audio
      await _audioHandler!.loadSurahContinuous(
        surahId: widget.surah.id,
        surahName: widget.surah.nameEnglish,
        reciter: widget.reciter,
        audioUrl: widget.audioUrls.first,
        duration: widget.verseTimestamps.last,
        verseTimestamps: widget.verseTimestamps,
        artworkUrl: 'https://hafiz.app/assets/surah_${widget.surah.id}.png',
      );

      // Listen to current verse
      _audioHandler!.currentVerseStream.listen((verse) {
        if (mounted) {
          setState(() => _currentVerse = verse);
          _scrollToCurrentVerse();
        }
      });

      // Seek to start verse if specified
      if (widget.startVerse != null) {
        await _audioHandler!.seekToVerse(widget.startVerse!);
      }

      setState(() => _isLoading = false);

      // Auto-play
      await _audioHandler!.play();
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToCurrentVerse() {
    if (_verseScrollController.hasClients) {
      final position =
          (_currentVerse - 1) * 56.0; // Approximate verse tile height
      _verseScrollController.animateTo(
        position.clamp(0, _verseScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSleepTimerDialog() {
    final options = [5, 10, 15, 30, 45, 60];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'lbl_sleep_timer'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_remainingSleepTime != null)
              ListTile(
                leading: const Icon(Icons.timer_off, color: Colors.red),
                title: Text('lbl_cancel_timer'.tr),
                onTap: () {
                  _cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ...options.map(
              (minutes) => ListTile(
                leading: const Icon(Icons.timer),
                title: Text('$minutes ${'lbl_minutes'.tr}'),
                onTap: () {
                  _setSleepTimer(Duration(minutes: minutes));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _remainingSleepTime = duration;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSleepTime = _remainingSleepTime! - const Duration(seconds: 1);
        if (_remainingSleepTime!.inSeconds <= 0) {
          _audioHandler?.pause();
          _cancelSleepTimer();
        }
      });
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    setState(() => _remainingSleepTime = null);
  }

  void _showVerseLoopDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'lbl_loop_verses'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'msg_select_verse_range'.tr,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _loopStartVerse ?? 1,
                      decoration: InputDecoration(
                        labelText: 'lbl_from_verse'.tr,
                        border: const OutlineInputBorder(),
                      ),
                      items: List.generate(
                        widget.surah.verseCount,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text((i + 1).toString()),
                        ),
                      ),
                      onChanged: (v) {
                        setModalState(() => _loopStartVerse = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _loopEndVerse ?? widget.surah.verseCount,
                      decoration: InputDecoration(
                        labelText: 'lbl_to_verse'.tr,
                        border: const OutlineInputBorder(),
                      ),
                      items: List.generate(
                        widget.surah.verseCount,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text((i + 1).toString()),
                        ),
                      ),
                      onChanged: (v) {
                        setModalState(() => _loopEndVerse = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: (_loopStartVerse != null && _loopEndVerse != null)
                    ? () {
                        _setLoopRange(_loopStartVerse!, _loopEndVerse!);
                        Navigator.pop(context);
                      }
                    : null,
                icon: const Icon(Icons.repeat),
                label: Text('lbl_start_loop'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setLoopRange(int start, int end) {
    if (start > end) return;

    setState(() {
      _isLoopingRange = true;
      _loopStartVerse = start;
      _loopEndVerse = end;
    });

    _audioHandler?.setLoopRange(start, end);
  }

  void _cancelLoop() {
    setState(() {
      _isLoopingRange = false;
      _loopStartVerse = null;
      _loopEndVerse = null;
    });

    // Reset to normal playback
    _audioHandler?.setRepeatMode(AudioServiceRepeatMode.none);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _verseScrollController.dispose();
    _audioHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // App bar
                  _buildAppBar(isDark),

                  // Album art and surah info
                  _buildAlbumArt(isDark),

                  // Verse list with highlighting
                  Expanded(child: _buildVerseList(isDark)),

                  // Sleep timer indicator
                  if (_remainingSleepTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.amber.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_remainingSleepTime!.inMinutes}:${(_remainingSleepTime!.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.amber),
                          ),
                        ],
                      ),
                    ),

                  // Loop indicator
                  if (_isLoopingRange)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.teal.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.repeat,
                            size: 16,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'msg_looping_verses'.tr
                                .replaceAll(
                                  '{start}',
                                  _loopStartVerse.toString(),
                                )
                                .replaceAll('{end}', _loopEndVerse.toString()),
                            style: const TextStyle(color: Colors.teal),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _cancelLoop,
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Progress bar
                  _buildProgressBar(),

                  // Controls
                  _buildControls(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            widget.reciter,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sleep':
                  _showSleepTimerDialog();
                  break;
                case 'loop':
                  _showVerseLoopDialog();
                  break;
                case 'download':
                  _downloadAudio();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sleep',
                child: Row(
                  children: [
                    const Icon(Icons.timer),
                    const SizedBox(width: 8),
                    Text('lbl_sleep_timer'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'loop',
                child: Row(
                  children: [
                    const Icon(Icons.repeat),
                    const SizedBox(width: 8),
                    Text('lbl_loop_verses'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text('lbl_download_audio'.tr),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Album art placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A35), const Color(0xFF0B2D28)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.surah.nameArabic,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF006754),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.surah.nameEnglish,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.surah.localizedName(context),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.surah.verseCount} ${'lbl_verses'.tr}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseList(bool isDark) {
    return ListView.builder(
      controller: _verseScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.surah.verseCount,
      itemBuilder: (context, index) {
        final verseNumber = index + 1;
        final isCurrentVerse = verseNumber == _currentVerse;

        return ListTile(
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrentVerse
                  ? Colors.teal
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
            ),
            alignment: Alignment.center,
            child: Text(
              verseNumber.toString(),
              style: TextStyle(
                color: isCurrentVerse ? Colors.white : null,
                fontWeight: isCurrentVerse ? FontWeight.bold : null,
              ),
            ),
          ),
          title: Text(
            '${'lbl_verse'.tr} $verseNumber',
            style: TextStyle(
              fontWeight: isCurrentVerse ? FontWeight.bold : null,
              color: isCurrentVerse ? Colors.teal : null,
            ),
          ),
          onTap: () {
            _audioHandler?.seekToVerse(verseNumber);
          },
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _audioHandler?.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _audioHandler?.duration ?? Duration.zero;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _audioHandler?.seek(Duration(milliseconds: value.toInt()));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position)),
                    Text(_formatDuration(duration)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Speed control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              final isSelected = _playbackSpeed == speed;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${speed}x'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _playbackSpeed = speed);
                      _audioHandler?.setSpeed(speed);
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 36),
                onPressed: () => _audioHandler?.skipToPrevious(),
              ),
              StreamBuilder<bool>(
                stream: _audioHandler?.playbackState
                    .map((state) => state.playing)
                    .distinct(),
                builder: (context, snapshot) {
                  final playing = snapshot.data ?? false;
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (playing) {
                          _audioHandler?.pause();
                        } else {
                          _audioHandler?.play();
                        }
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 36),
                onPressed: () => _audioHandler?.skipToNext(),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _downloadAudio() {
    // Show download dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lbl_download_audio'.tr),
        content: Text('msg_download_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lbl_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger download
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('msg_download_started'.tr)),
              );
            },
            child: Text('lbl_download'.tr),
          ),
        ],
      ),
    );
  }
}
