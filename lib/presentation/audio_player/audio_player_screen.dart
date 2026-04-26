import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/audio/audio_player_handler.dart';
import '../../core/quran_index/quran_surah.dart';

class AudioPlayerScreen extends StatefulWidget {
  final int surahId;
  final String surahName;
  final int? startVerse;

  const AudioPlayerScreen({
    super.key,
    required this.surahId,
    required this.surahName,
    this.startVerse,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayerHandler _handler = AudioPlayerHandler();
  bool _isLoading = false;
  double _speed = 1.0;
  String? _errorMessage;
  int _currentVerse = -1;
  StreamSubscription<int>? _verseSub;

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _verseSub = _handler.currentVerseStream.listen((verseIndex) {
      if (mounted) {
        setState(() {
          _currentVerse = verseIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _verseSub?.cancel();
    _handler.stop();
    super.dispose();
  }

  static const Map<int, String> _reciterCdnIds = {
    7: 'ar.alafasy',
    1: 'ar.abdulbasitmurattal',
    2: 'ar.husary',
    3: 'ar.minshawi',
    4: 'ar.abdurrahmaansudais',
    5: 'ar.hudhaify',
    6: 'ar.saaborimuneer',
    8: 'ar.ahmedajamy',
    9: 'ar.alijabir',
  };

  String _getReciterCdnId() {
    final id = PrefUtils().getReciterId();
    return _reciterCdnIds[id] ?? 'ar.alafasy';
  }

  List<String> _buildVerseUrls(int surahId, int verseCount) {
    final reciter = _getReciterCdnId();
    return List.generate(
      verseCount,
      (i) =>
          'https://cdn.islamic.network/quran/audio/128/$reciter/${(surahId * 1000 + i + 1)}.mp3',
    );
  }

  Future<void> _play() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final verseCount = _getVerseCount(widget.surahId);
      final urls = _buildVerseUrls(widget.surahId, verseCount);
      await _handler.playSurah(
        surahId: widget.surahId,
        verseAudioUrls: urls,
        startVerse: (widget.startVerse ?? 1) - 1,
      );
    } catch (e) {
      setState(() => _errorMessage = 'msg_audio_load_error'.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getVerseCount(int surahId) {
    const counts = <int, int>{
      1: 7,
      2: 286,
      3: 200,
      4: 176,
      5: 120,
      6: 165,
      7: 206,
      8: 75,
      9: 129,
      10: 109,
      11: 123,
      12: 111,
      13: 43,
      14: 52,
      15: 99,
      16: 128,
      17: 111,
      18: 110,
      19: 98,
      20: 135,
      21: 112,
      22: 78,
      23: 118,
      24: 64,
      25: 77,
      26: 227,
      27: 93,
      28: 88,
      29: 69,
      30: 60,
      31: 34,
      32: 30,
      33: 73,
      34: 54,
      35: 45,
      36: 83,
      37: 182,
      38: 88,
      39: 75,
      40: 85,
      41: 54,
      42: 53,
      43: 89,
      44: 59,
      45: 37,
      46: 35,
      47: 38,
      48: 29,
      49: 18,
      50: 45,
      51: 60,
      52: 49,
      53: 62,
      54: 55,
      55: 78,
      56: 96,
      57: 29,
      58: 22,
      59: 24,
      60: 13,
      61: 14,
      62: 11,
      63: 11,
      64: 18,
      65: 12,
      66: 12,
      67: 30,
      68: 52,
      69: 52,
      70: 44,
      71: 28,
      72: 28,
      73: 20,
      74: 56,
      75: 40,
      76: 31,
      77: 50,
      78: 40,
      79: 46,
      80: 42,
      81: 29,
      82: 19,
      83: 36,
      84: 25,
      85: 22,
      86: 17,
      87: 19,
      88: 26,
      89: 30,
      90: 20,
      91: 15,
      92: 21,
      93: 11,
      94: 8,
      95: 8,
      96: 19,
      97: 5,
      98: 8,
      99: 8,
      100: 11,
      101: 11,
      102: 8,
      103: 3,
      104: 9,
      105: 5,
      106: 4,
      107: 7,
      108: 3,
      109: 6,
      110: 3,
      111: 5,
      112: 4,
      113: 5,
      114: 6,
    };
    return counts[surahId] ?? 7;
  }

  void _showSleepTimerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'lbl_sleep_timer'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...[15, 30, 45, 60].map(
              (minutes) => ListTile(
                title: Text('$minutes ${'lbl_minutes'.tr}'),
                onTap: () {
                  _handler.setSleepTimer(Duration(minutes: minutes));
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            if (_handler.sleepTimerEnd != null)
              ListTile(
                leading: const Icon(Icons.cancel),
                title: Text('lbl_cancel_timer'.tr),
                onTap: () {
                  _handler.cancelSleepTimer();
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _speedOptions
              .map(
                (speed) => ListTile(
                  title: Text('${speed}x'),
                  trailing: speed == _speed
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    _handler.setSpeed(speed);
                    Navigator.pop(context);
                    setState(() => _speed = speed);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surah = QuranIndex.quranSurahs[widget.surahId - 1];

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            surah.nameArabic,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'NotoNaskhArabic'),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              surah.nameArabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              surah.nameEnglish,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            _buildVerseProgress(theme),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            _buildControls(theme),
            const Spacer(),
            _buildBottomActions(theme),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseProgress(ThemeData theme) {
    final totalVerses = _getVerseCount(widget.surahId);
    final isPlaying =
        _handler.currentSurahId == widget.surahId && _currentVerse >= 0;
    if (!isPlaying) return const SizedBox.shrink();

    final displayVerse = _currentVerse + 1;
    final progress = displayVerse / totalVerses;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${'lbl_verse_num'.tr} $displayVerse / $totalVerses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: 'lbl_rewind_10'.tr,
          child: IconButton(
            icon: const Icon(Icons.replay_10, size: 32),
            tooltip: 'lbl_rewind_10'.tr,
            onPressed: () {
              _handler.seekRelative(const Duration(seconds: -10));
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Semantics(
                  button: true,
                  label: _handler.isPlaying ? 'lbl_pause'.tr : 'lbl_play'.tr,
                  child: IconButton(
                    icon: Icon(
                      _handler.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                    tooltip: _handler.isPlaying
                        ? 'lbl_pause'.tr
                        : 'lbl_play'.tr,
                    onPressed: () {
                      if (_handler.isPlaying) {
                        _handler.pause();
                      } else if (_handler.currentSurahId == widget.surahId) {
                        _handler.resume();
                      } else {
                        _play();
                      }
                      setState(() {});
                    },
                  ),
                ),
        ),
        const SizedBox(width: 24),
        Semantics(
          button: true,
          label: 'lbl_forward_10'.tr,
          child: IconButton(
            icon: const Icon(Icons.forward_10, size: 32),
            tooltip: 'lbl_forward_10'.tr,
            onPressed: () {
              _handler.seekRelative(const Duration(seconds: 10));
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.speed),
          label: Text('${_speed}x'),
          onPressed: _showSpeedDialog,
        ),
        TextButton.icon(
          icon: Icon(
            Icons.timer,
            color: _handler.sleepTimerEnd != null
                ? theme.colorScheme.primary
                : null,
          ),
          label: Text('lbl_sleep_timer'.tr),
          onPressed: _showSleepTimerDialog,
        ),
        TextButton.icon(
          icon: Icon(
            Icons.loop,
            color: _handler.isLooping ? theme.colorScheme.primary : null,
          ),
          label: Text('lbl_loop_verses'.tr),
          onPressed: () {
            if (_handler.isLooping) {
              _handler.clearLoop();
            } else {
              _handler.setLoopRange(0, _getVerseCount(widget.surahId) - 1);
            }
            setState(() {});
          },
        ),
      ],
    );
  }
}
