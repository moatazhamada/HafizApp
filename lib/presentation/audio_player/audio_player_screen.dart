import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/app_export.dart';
import 'widgets/audio_player_action_button.dart';
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
import '../../core/analytics/analytics_service.dart';

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

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with WidgetsBindingObserver {
  final AudioPlayerHandler _handler = AudioPlayerHandler();
  final ReadingSessionTracker _sessionTracker = ReadingSessionTracker();
  bool _isLoading = false;
  double _speed = 1.0;
  String? _errorMessage;
  int _currentVerse = -1;
  StreamSubscription<int>? _verseSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _playingSub;
  Timer? _sleepTimerUpdater;
  Timer? _uiRefreshTimer;
  String? _sleepTimerRemaining;
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
    unawaited(
      sl<AnalyticsService>().logAudioPlay(
        surahId: widget.surahId,
        verseNumber: widget.startVerse,
        reciterId: _getReciterCdnId(),
      ),
    );

    _verseSub = _handler.currentVerseStream.listen((verseIndex) {
      if (mounted && _currentVerse != verseIndex) {
        setState(() => _currentVerse = verseIndex);
        // Persist last played verse for resume functionality
        if (verseIndex >= 0) {
          PrefUtils().setLastAudioVerse(widget.surahId, verseIndex);
          _sessionTracker.updateProgress(verseIndex + 1);

          // Sync global last read surah for home screen consistency
          final surah = QuranIndex.quranSurahs[widget.surahId - 1];
          PrefUtils().saveLastReadSurah(surah);
        }
      }
    });

    _errorSub = _handler.errorStream.listen((errorKey) {
      if (mounted) {
        setState(() {
          _errorMessage = errorKey.tr;
          _isLoading = false;
        });
      }
    });

    _playingSub = _handler.playingStateStream.listen((isPlaying) {
      if (mounted) setState(() {});
    });

    _startSleepTimerUpdater();
    _startUiRefreshTimer();

    // Check if we have a saved position to resume from
    final saved = PrefUtils().getLastAudioVerse(widget.surahId);
    if (saved != null &&
        saved > 0 &&
        saved < _getVerseCount(widget.surahId)) {
      _resumeFromVerse = saved;
    }
    // Auto-play if a startVerse was explicitly provided
    if (widget.startVerse != null) {
      _play(startVerse: (widget.startVerse!) - 1);
    }
  }

  @override
  void dispose() {
    // Only finalize the session if audio has actually stopped.
    // If the user navigated away while audio is still playing, we keep the
    // audio running in the background and do NOT report a premature session.
    if (_handler.currentSurahId != widget.surahId || !_handler.isPlaying) {
      _finalizeCurrentSession();
    }
    WidgetsBinding.instance.removeObserver(this);
    _verseSub?.cancel();
    _errorSub?.cancel();
    _playingSub?.cancel();
    _sleepTimerUpdater?.cancel();
    _uiRefreshTimer?.cancel();
    // Intentionally do NOT stop audio here — users expect Quran recitation
    // to continue even after leaving the audio player screen.
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _sessionTracker.pause();
        // Allow the screen to lock when the app is backgrounded to save battery.
        WakelockPlus.disable();
        break;
      case AppLifecycleState.resumed:
        _sessionTracker.resume();
        // Re-enable wakelock only if we're still actively playing this surah.
        if (_handler.currentSurahId == widget.surahId && _handler.isPlaying) {
          WakelockPlus.enable();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _startSleepTimerUpdater() {
    _sleepTimerUpdater?.cancel();
    _sleepTimerUpdater = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateSleepTimerDisplay(),
    );
  }

  /// Periodically refreshes the UI so the play/pause button and progress
  /// indicator stay in sync with the actual player state. This is a robust
  /// fallback for any stream synchronization delays or platform quirks.
  void _startUiRefreshTimer() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  void _updateSleepTimerDisplay() {
    if (!mounted) return;
    final end = _handler.sleepTimerEnd;
    if (end == null) {
      if (_sleepTimerRemaining != null) {
        setState(() => _sleepTimerRemaining = null);
      }
      return;
    }
    final remaining = end.difference(DateTime.now());
    if (remaining.isNegative) {
      if (_sleepTimerRemaining != null) {
        setState(() => _sleepTimerRemaining = null);
      }
      return;
    }
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final formatted = 'msg_sleep_timer_remaining'
        .tr
        .replaceAll('{minutes}', minutes)
        .replaceAll('{seconds}', seconds);
    if (formatted != _sleepTimerRemaining) {
      setState(() => _sleepTimerRemaining = formatted);
    }
  }

  void _finalizeCurrentSession() {
    final sessions = _sessionTracker.endSession();
    for (final session in sessions) {
      if (session.endVerse >= session.startVerse) {
        final totalVerses = session.endVerse - session.startVerse + 1;

        try {
          sl<KhatmahBloc>().add(RecordReading(verses: totalVerses));
        } catch (e, s) {
          Logger.warning('Failed to record reading: $e\n$s', feature: 'AudioPlayer');
        }
        unawaited(sl<KhatmahRepository>().reportReadingSession(session));

        // Analytics
        unawaited(
          sl<AnalyticsService>().logReadingSession(
            chapterNumber: session.surahId,
            versesRead: totalVerses,
            durationSeconds: session.durationSeconds,
          ),
        );
        unawaited(
            sl<AnalyticsService>().logAudioCompleted(surahId: widget.surahId));

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
            ...[5, 10, 15, 30, 45, 60].map(
              (minutes) => ListTile(
                title: Text('$minutes ${'lbl_minutes'.tr}'),
                onTap: () {
                  _handler.setSleepTimer(Duration(minutes: minutes));
                  Navigator.pop(context);
                  _updateSleepTimerDisplay();
                  setState(() {});
                  unawaited(
                    sl<AnalyticsService>().logSleepTimerSet(minutes),
                  );
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
                  _updateSleepTimerDisplay();
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
                    unawaited(
                      sl<AnalyticsService>().logAudioSpeedChanged(speed),
                    );
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
    final current = _handler.currentVerseIndex;
    if (current > 0) {
      _handler.seekToVerse(current - 1);
    }
  }

  void _nextVerse() {
    final total = _getVerseCount(widget.surahId);
    final current = _handler.currentVerseIndex;
    if (current < total - 1) {
      _handler.seekToVerse(current + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surah = QuranIndex.quranSurahs[widget.surahId - 1];
    final totalVerses = _getVerseCount(widget.surahId);
    final isPlaying =
        _handler.currentSurahId == widget.surahId && _handler.isPlaying;

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Sleep timer countdown chip
            if (_sleepTimerRemaining != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Chip(
                  avatar: Icon(
                    Icons.timer,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    _sleepTimerRemaining!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.4),
                  side: BorderSide.none,
                ),
              ),

            const Spacer(flex: 2),

            // Resume prompt
            if (_resumeFromVerse != null && !isPlaying)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
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
                  textAlign: TextAlign.center,
                ),
              ),
            _buildControls(theme, isPlaying),
            const Spacer(),
            _buildBottomActions(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isPlaying) {
    // Enable skip/seek whenever this surah is loaded (even if paused),
    // or when a load is in progress.
    final canControl =
        _handler.currentSurahId == widget.surahId || _isLoading;
    final isRTL = isRtl(context);

    // Spatial buttons swap sides for RTL, but temporal buttons
    // (rewind / forward) stay in fixed positions per Material guidelines.
    final leftSpatial = Semantics(
      button: true,
      label: isRTL ? 'lbl_next_verse'.tr : 'lbl_previous_verse'.tr,
      child: IconButton(
        icon: isRTL
            ? rtlSkipNextIcon(context, size: 32)
            : rtlSkipPreviousIcon(context, size: 32),
        tooltip: isRTL ? 'lbl_next_verse'.tr : 'lbl_previous_verse'.tr,
        onPressed: canControl ? (isRTL ? _nextVerse : _previousVerse) : null,
      ),
    );

    final rightSpatial = Semantics(
      button: true,
      label: isRTL ? 'lbl_previous_verse'.tr : 'lbl_next_verse'.tr,
      child: IconButton(
        icon: isRTL
            ? rtlSkipPreviousIcon(context, size: 32)
            : rtlSkipNextIcon(context, size: 32),
        tooltip: isRTL ? 'lbl_previous_verse'.tr : 'lbl_next_verse'.tr,
        onPressed: canControl ? (isRTL ? _previousVerse : _nextVerse) : null,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leftSpatial,
        const SizedBox(width: 12),
        // Rewind 10s — temporal, fixed position (left of play)
        Semantics(
          button: true,
          label: 'lbl_rewind_10'.tr,
          child: IconButton(
            icon: const Icon(Icons.replay_10, size: 28),
            tooltip: 'lbl_rewind_10'.tr,
            onPressed: canControl
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
                        unawaited(
                          sl<AnalyticsService>().logAudioPause(
                            surahId: widget.surahId,
                          ),
                        );
                      } else if (_handler.currentSurahId ==
                          widget.surahId) {
                        _handler.resume();
                        unawaited(
                          sl<AnalyticsService>().logAudioPlay(
                            surahId: widget.surahId,
                            verseNumber: _currentVerse >= 0
                                ? _currentVerse + 1
                                : null,
                            reciterId: _getReciterCdnId(),
                          ),
                        );
                      } else {
                        _play();
                      }
                      setState(() {});
                    },
                  ),
                ),
        ),
        const SizedBox(width: 16),
        // Forward 10s — temporal, fixed position (right of play)
        Semantics(
          button: true,
          label: 'lbl_forward_10'.tr,
          child: IconButton(
            icon: const Icon(Icons.forward_10, size: 28),
            tooltip: 'lbl_forward_10'.tr,
            onPressed: canControl
                ? () {
                    _handler.seekRelative(const Duration(seconds: 10));
                    setState(() {});
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        rightSpatial,
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    final loopLabel = _handler.isLooping
        ? 'lbl_loop_surah'.tr
        : 'lbl_loop_verses'.tr;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AudioPlayerActionButton(
          icon: Icons.speed,
          label: 'lbl_speed_x'.tr.replaceAll('{speed}', '$_speed'),
          isActive: _speed != 1.0,
          onPressed: _showSpeedDialog,
        ),
        AudioPlayerActionButton(
          icon: Icons.timer,
          label: 'lbl_sleep_timer'.tr,
          isActive: _handler.sleepTimerEnd != null,
          onPressed: _showSleepTimerDialog,
        ),
        AudioPlayerActionButton(
          icon: Icons.loop,
          label: loopLabel,
          isActive: _handler.isLooping,
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
  bool _isPlayingAudio = false;
  StreamSubscription<int>? _sub;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    _sub = widget.handler.currentVerseStream.listen((verseIndex) {
      if (mounted && _currentVerse != verseIndex) {
        setState(() => _currentVerse = verseIndex);
      }
    });
    _playingSub = widget.handler.playingStateStream.listen((isPlaying) {
      if (mounted && _isPlayingAudio != isPlaying) {
        setState(() => _isPlayingAudio = isPlaying);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveVerse =
        widget.handler.currentSurahId == widget.surahId && _currentVerse >= 0;
    if (!hasActiveVerse) return const SizedBox.shrink();

    final displayVerse = _currentVerse + 1;
    final progress = widget.totalVerses > 0
        ? displayVerse / widget.totalVerses
        : 0.0;
    final theme = Theme.of(context);

    // Dim the indicator when paused so it doesn't look "active".
    final opacity = _isPlayingAudio ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlayingAudio)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Icon(
                    Icons.pause,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
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
      ),
    );
  }
}
