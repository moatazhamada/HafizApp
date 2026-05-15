import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/app_export.dart';
import '../../core/audio/audio_player_handler.dart';
import '../../core/quran_index/mushaf_page_index.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../core/quran_index/quran_verse_utils.dart';
import '../../core/utils/rtl_utils.dart';
import '../../domain/repository/khatmah_repository.dart';
import '../khatmah/bloc/khatmah_bloc.dart';
import '../khatmah/bloc/khatmah_event.dart';
import '../../injection_container.dart';
import '../../core/services/reading_session_tracker.dart';

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

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with WidgetsBindingObserver {
  final AudioPlayerHandler _handler = AudioPlayerHandler();
  final ReadingSessionTracker _sessionTracker = ReadingSessionTracker();
  bool _isLoading = false;
  double _speed = 1.0;
  String? _errorMessage;
  int _currentVerse = -1;
  StreamSubscription<int>? _verseSub;
  int? _resumeFromVerse;

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  /// Reciter CDN ID mapping — kept in sync with SurahScreen.
  static const Map<int, String> _reciterCdnIds = {
    7: 'ar.alafasy',
    1: 'ar.abdulbasitmurattal',
    5: 'ar.husary',
    9: 'ar.abdurrahmaansudais',
    17: 'ar.minshawi',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    
    _sessionTracker.startSession(
      surahId: widget.surahId,
      startVerse: widget.startVerse ?? 1,
    );

    _verseSub = _handler.currentVerseStream.listen((verseIndex) {
      if (mounted && _currentVerse != verseIndex) {
        setState(() => _currentVerse = verseIndex);
        // Persist last played verse for resume functionality
        if (verseIndex >= 0) {
          PrefUtils().setLastAudioVerse(widget.surahId, verseIndex);
          _sessionTracker.updateProgress(verseIndex + 1);
        }
      }
    });
    // Check if we have a saved position to resume from
    final saved = PrefUtils().getLastAudioVerse(widget.surahId);
    if (saved != null &&
        saved > 0 &&
        saved < _getVerseCount(widget.surahId) - 1) {
      _resumeFromVerse = saved;
    }
    // Auto-play if a startVerse was explicitly provided
    if (widget.startVerse != null) {
      _play(startVerse: (widget.startVerse!) - 1);
    }
  }

  @override
  void dispose() {
    _finalizeCurrentSession();
    WidgetsBinding.instance.removeObserver(this);
    _verseSub?.cancel();
    _handler.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _finalizeCurrentSession();
    } else if (state == AppLifecycleState.resumed) {
      _sessionTracker.startSession(
        surahId: widget.surahId,
        startVerse: _currentVerse >= 0 ? _currentVerse + 1 : (widget.startVerse ?? 1),
      );
    }
  }

  void _finalizeCurrentSession() {
    final sessions = _sessionTracker.endSession();
    for (final session in sessions) {
      if (session.endVerse >= session.startVerse) {
        final totalVerses = session.endVerse - session.startVerse + 1;
        
        sl<KhatmahBloc>().add(RecordReading(verses: totalVerses));
        unawaited(sl<KhatmahRepository>().reportReadingSession(session));
        
        Logger.info(
          'Audio session finalized: ${session.surahId}:${session.startVerse}-${session.endVerse}',
          feature: 'ReadingSessions',
        );
      }
    }
  }

  String _getReciterCdnId() {
    final id = PrefUtils().getReciterId();
    return _reciterCdnIds[id] ?? 'ar.alafasy';
  }

  List<String> _buildVerseUrls(int surahId, int verseCount) {
    final reciter = _getReciterCdnId();
    return List.generate(verseCount, (i) {
      final absolute = absoluteVerseNumber(surahId, i + 1);
      return 'https://cdn.islamic.network/quran/audio/128/$reciter/$absolute.mp3';
    });
  }

  Future<void> _play({int? startVerse}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resumeFromVerse = null;
    });
    try {
      final verseCount = _getVerseCount(widget.surahId);
      final urls = _buildVerseUrls(widget.surahId, verseCount);
      await _handler.playSurah(
        surahId: widget.surahId,
        verseAudioUrls: urls,
        startVerse: startVerse ?? 0,
      );
    } catch (e) {
      setState(() => _errorMessage = 'msg_audio_load_error'.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resumeFromSaved() async {
    if (_resumeFromVerse == null) return;
    await _play(startVerse: _resumeFromVerse);
  }

  int _getVerseCount(int surahId) {
    return MushafPageIndex.getVerseCount(surahId);
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
                  title: Text('lbl_speed_x'.tr.replaceAll('{speed}', '$speed')),
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

  void _showVersePicker() {
    final totalVerses = _getVerseCount(widget.surahId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (_, scrollController) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'lbl_select_verse'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: totalVerses,
                  itemBuilder: (context, index) {
                    final isCurrent = _currentVerse == index;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? Theme.of(ctx).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                      ),
                      title: Text(
                        '${'lbl_verse_num'.tr} ${index + 1}',
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(
                              Icons.volume_up,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _handler.seekToVerse(index);
                      },
                      selected: isCurrent,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previousVerse() {
    if (_currentVerse > 0) {
      _handler.seekToVerse(_currentVerse - 1);
    }
  }

  void _nextVerse() {
    final total = _getVerseCount(widget.surahId);
    if (_currentVerse < total - 1) {
      _handler.seekToVerse(_currentVerse + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surah = QuranIndex.quranSurahs[widget.surahId - 1];
    final totalVerses = _getVerseCount(widget.surahId);
    final isPlaying =
        _handler.currentSurahId == widget.surahId && _currentVerse >= 0;

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
        actions: [
          if (totalVerses > 1)
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'lbl_select_verse'.tr,
              onPressed: _showVersePicker,
            ),
        ],
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
            const SizedBox(height: 16),

            // Resume prompt
            if (_resumeFromVerse != null && !isPlaying)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: InkWell(
                    onTap: _resumeFromSaved,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'msg_resume_audio'.tr,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'msg_resume_from_verse'.tr.replaceAll(
                                    '{verse}',
                                    '${_resumeFromVerse! + 1}',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            rtlChevron(context),
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            _VerseProgressIndicator(
              surahId: widget.surahId,
              totalVerses: totalVerses,
              handler: _handler,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            _buildControls(theme, isPlaying),
            const Spacer(),
            _buildBottomActions(theme),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  /// Extracted into [_VerseProgressIndicator] to avoid rebuilding the
  /// entire screen on every verse change.

  Widget _buildControls(ThemeData theme, bool isPlaying) {
    // In RTL the Quran is read right-to-left, so spatial "previous"
    // is on the right and "next" is on the left. We flip the skip
    // icons horizontally so the arrows match the user's mental model.
    Widget rtlAwareIcon(
      IconData icon,
      BuildContext rtlContext, {
      double size = 24,
    }) {
      final isRtl = Directionality.of(rtlContext) == TextDirection.rtl;
      final child = Icon(icon, size: size);
      if (!isRtl) return child;
      // Only flip directional skip icons, not temporal replay/forward.
      if (icon != Icons.skip_previous && icon != Icons.skip_next) {
        return child;
      }
      return Transform.flip(flipX: true, child: child);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (rtlContext) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous verse (Spatially on the right in RTL)
              Semantics(
                button: true,
                label: 'lbl_previous_verse'.tr,
                child: IconButton(
                  icon: rtlAwareIcon(Icons.skip_previous, rtlContext, size: 32),
                  tooltip: 'lbl_previous_verse'.tr,
                  onPressed: isPlaying ? _previousVerse : null,
                ),
              ),
              const SizedBox(width: 12),
              // Rewind 10s
              Semantics(
                button: true,
                label: 'lbl_rewind_10'.tr,
                child: IconButton(
                  icon: const Icon(Icons.replay_10, size: 28),
                  tooltip: 'lbl_rewind_10'.tr,
                  onPressed: isPlaying
                      ? () {
                          _handler.seekRelative(const Duration(seconds: -10));
                          setState(() {});
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Play/Pause
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Semantics(
                        button: true,
                        label: _handler.isPlaying
                            ? 'lbl_pause'.tr
                            : 'lbl_play'.tr,
                        child: IconButton(
                          icon: Icon(
                            _handler.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: theme.colorScheme.onPrimary,
                            size: 36,
                          ),
                          tooltip: _handler.isPlaying
                              ? 'lbl_pause'.tr
                              : 'lbl_play'.tr,
                          onPressed: () {
                            if (_handler.isPlaying) {
                              _handler.pause();
                            } else if (_handler.currentSurahId ==
                                widget.surahId) {
                              _handler.resume();
                            } else {
                              _play();
                            }
                            setState(() {});
                          },
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Forward 10s
              Semantics(
                button: true,
                label: 'lbl_forward_10'.tr,
                child: IconButton(
                  icon: const Icon(Icons.forward_10, size: 28),
                  tooltip: 'lbl_forward_10'.tr,
                  onPressed: isPlaying
                      ? () {
                          _handler.seekRelative(const Duration(seconds: 10));
                          setState(() {});
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Next verse
              Semantics(
                button: true,
                label: 'lbl_next_verse'.tr,
                child: IconButton(
                  icon: rtlAwareIcon(Icons.skip_next, rtlContext, size: 32),
                  tooltip: 'lbl_next_verse'.tr,
                  onPressed: isPlaying ? _nextVerse : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.speed),
          label: Text('lbl_speed_x'.tr.replaceAll('{speed}', '$_speed')),
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

/// Self-contained verse progress indicator that listens to the audio handler
/// stream directly, preventing the entire [AudioPlayerScreen] from rebuilding
/// on every verse change.
class _VerseProgressIndicator extends StatefulWidget {
  final int surahId;
  final int totalVerses;
  final AudioPlayerHandler handler;

  const _VerseProgressIndicator({
    required this.surahId,
    required this.totalVerses,
    required this.handler,
  });

  @override
  State<_VerseProgressIndicator> createState() =>
      _VerseProgressIndicatorState();
}

class _VerseProgressIndicatorState extends State<_VerseProgressIndicator> {
  int _currentVerse = -1;
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.handler.currentVerseStream.listen((verseIndex) {
      if (mounted && _currentVerse != verseIndex) {
        setState(() => _currentVerse = verseIndex);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        widget.handler.currentSurahId == widget.surahId && _currentVerse >= 0;
    if (!isPlaying) return const SizedBox.shrink();

    final displayVerse = _currentVerse + 1;
    final progress = displayVerse / widget.totalVerses;
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'msg_verse_progress'.tr
                  .replaceAll('{label}', 'lbl_verse_num'.tr)
                  .replaceAll('{current}', '$displayVerse')
                  .replaceAll('{total}', '${widget.totalVerses}'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
