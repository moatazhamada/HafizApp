import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hafiz_app/core/audio/whisper_platform.dart'
    if (dart.library.html) 'package:hafiz_app/core/audio/whisper_platform_web.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/app_export.dart';
import '../../../injection_container.dart';

import '../../../domain/entities/verse.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/services/voice_recording_controller.dart';
import '../custom_asr_service.dart';
import '../local_whisper_service.dart';
import '../qrc_recitation_service.dart';
import '../sheikh_audio_coach_sheet.dart';
import '../voice_verification_service.dart';

class VoiceVerificationDialog extends StatefulWidget {
  final Surah surah;
  final Verse aya;
  final String expectedText;
  final VoidCallback onCorrect;
  final VoidCallback onSaveForPractice;
  final Function(BuildContext context) onWrong;

  const VoiceVerificationDialog({
    super.key,
    required this.surah,
    required this.aya,
    required this.expectedText,
    required this.onCorrect,
    required this.onSaveForPractice,
    required this.onWrong,
  });

  @override
  State<VoiceVerificationDialog> createState() =>
      _VoiceVerificationDialogState();
}

class _VoiceVerificationDialogState extends State<VoiceVerificationDialog> {
  final VoiceVerificationService _voiceService = VoiceVerificationService();
  final QrcRecitationService _qrcService = QrcRecitationService();
  final CustomAsrService _customAsrService = CustomAsrService();
  final FlutterSoundRecorder _customRecorder = FlutterSoundRecorder();
  final LocalWhisperService _whisperService = LocalWhisperService();

  late String _expectedText;
  bool _isListening = false;

  // UI State
  String _spokenText = '';
  Color _statusColor = Colors.transparent;
  String _feedbackTitle = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statusColor == Colors.transparent) {
      _statusColor = Theme.of(context).colorScheme.primary;
    }
  }
  String _scoreText = '';
  String _hintLabel = '';
  String _hintWord = '';
  List<String> _issueLines = [];
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _isWrong = false;

  // QRC State
  bool _qrcConnecting = false;
  int _qrcWordIndex = 0;
  List<QrcTajweedMistake> _qrcMistakes = [];
  Set<int> _qrcMistakeIndices = {};
  List<String> _qrcMistakeLines = [];
  String _repeatLabel = '';
  String _repeatWord = '';
  StreamSubscription? _qrcSub;

  // Whisper / Custom
  String? _customFilePath;
  bool _whisperTranscribing = false;
  late WhisperModel _whisperModel;

  @override
  void initState() {
    super.initState();
    VoiceRecordingController.register(
      'voice_verification_dialog_${widget.aya.verseNumber}',
      _cleanup,
    );
    _expectedText = widget.expectedText;
    _whisperModel = _resolveWhisperModel(PrefUtils().getWhisperModel());

    // Auto-start listening on first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _voiceService.initialize();
        if (mounted) await _startListening();
      } catch (e, stackTrace) {
        Logger.error(
          'Voice verification auto-start failed: $e',
          feature: 'VoiceVerification',
          error: e,
          stackTrace: stackTrace,
        );
        if (mounted) {
          setState(() {
            _statusColor = AppColors.of(context).needsReviewStatus;
            _feedbackTitle = 'msg_voice_init_failed'.tr;
            _showFeedback = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    VoiceRecordingController.unregister(
      'voice_verification_dialog_${widget.aya.verseNumber}',
    );
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    await _voiceService.stop();
    await _qrcSub?.cancel();
    await _qrcService.dispose();
    if (_customRecorder.isRecording) {
      try { await _customRecorder.stopRecorder(); } catch (_) {}
    }
    if (!_customRecorder.isStopped) {
      try { await _customRecorder.closeRecorder(); } catch (_) {}
    }
    // Clean up temp WAV files to prevent storage exhaustion.
    if (_customFilePath != null) {
      try {
        final file = File(_customFilePath!);
        if (await file.exists()) {
          await file.delete();
          Logger.info('Deleted temp audio: $_customFilePath', feature: 'VoiceVerification');
        }
      } catch (e) {
        Logger.warning('Failed to delete temp audio: $e', feature: 'VoiceVerification');
      }
      _customFilePath = null;
    }
    await _whisperService.dispose();
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      final options = AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: options,
        avAudioSessionMode: AVAudioSessionMode.measurement,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.assistanceAccessibility,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
    } catch (e) {
      Logger.warning('Audio session config failed: $e', feature: 'VoiceVerification');
    }
  }

  WhisperModel _resolveWhisperModel(String value) {
    switch (value) {
      case 'tiny':
        return WhisperModel.tiny;
      case 'small':
        return WhisperModel.small;
      case 'base':
      default:
        return WhisperModel.base;
    }
  }

  void _resetState() {
    _isListening = false;
    _spokenText = '';
    _statusColor = Theme.of(context).colorScheme.primary;
    _feedbackTitle = '';
    _scoreText = '';
    _hintLabel = '';
    _hintWord = '';
    _issueLines = [];
    _showFeedback = false;
    _isCorrect = false;
    _isWrong = false;
    _qrcWordIndex = 0;
    _qrcMistakes = [];
    _qrcMistakeIndices = {};
    _qrcMistakeLines = [];
    _repeatLabel = '';
    _repeatWord = '';
    _whisperTranscribing = false;
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    final provider = PrefUtils().getRecitationProvider();
    final bool useQrc = provider == 'qrc';
    final bool useCustom = provider == 'custom';
    final bool useWhisper = provider == 'local_whisper';
    final String customEndpoint = PrefUtils().getCustomAsrEndpoint();

    // Recording-based providers need microphone permission
    if (useQrc || useWhisper || useCustom) {
      try {
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          if (!mounted) return;
          final isPermanentlyDenied = await Permission.microphone.isPermanentlyDenied;
          if (!mounted) return;
          setState(() {
            _statusColor = AppColors.of(context).needsReviewStatus;
            _feedbackTitle = isPermanentlyDenied
                ? 'msg_mic_permission_perm'.tr
                : 'msg_mic_permission'.tr;
            _showFeedback = true;
          });
          return;
        }
      } catch (e, stackTrace) {
        Logger.error(
          'Microphone permission request failed: $e',
          feature: 'VoiceVerification',
          error: e,
          stackTrace: stackTrace,
        );
        if (!mounted) return;
        setState(() {
          _statusColor = AppColors.of(context).needsReviewStatus;
          _feedbackTitle = 'msg_mic_permission'.tr;
          _showFeedback = true;
        });
        return;
      }

      // Configure audio session for recording + playback (Bluetooth, interruption handling)
      unawaited(_configureAudioSession());
    }

    setState(() {
      _resetState();
      _isListening = true;
      _statusColor = Theme.of(context).colorScheme.primary;
    });

    if (useQrc) {
      setState(() {
        _qrcConnecting = true;
      });

      final connected = await _qrcService.connect();
      if (!connected) {
        if (!mounted) return;
        setState(() {
          _statusColor = AppColors.of(context).needsReviewStatus;
          _feedbackTitle = 'msg_qrc_missing_key'.tr;
          _qrcConnecting = false;
          _showFeedback = true;
          _isListening = false;
        });
        return;
      }

      _qrcSub = _qrcService.events.listen((event) {
        if (!mounted) return;
        if (event is QrcStatusEvent) {
          if (event.status == 'connected' ||
              event.status == 'check_tilawa' ||
              event.status == 'CheckTilawaResponse') {
            setState(() => _qrcConnecting = false);
          }
        } else if (event is QrcCheckEvent) {
          _handleQrcCheck(event.data);
        } else if (event is QrcErrorEvent) {
          setState(() {
            _statusColor = AppColors.of(context).needsReviewStatus;
            _feedbackTitle = event.message;
            _showFeedback = true;
          });
        }
      });

      await _qrcService.startTilawaSession(
        surahIndex: widget.surah.id,
        verseIndex: widget.aya.verseNumber,
        hafzLevel: PrefUtils().getQrcHafzLevel(),
        tajweedLevel: PrefUtils().getQrcTajweedLevel(),
      );
      await _qrcService.startRecording();
    } else if (useWhisper) {
      try {
        if (!_customRecorder.isStopped) {
          await _customRecorder.stopRecorder();
          await _customRecorder.closeRecorder();
        }
        await _customRecorder.openRecorder();
      } catch (e) {
        Logger.warning('Whisper recorder open failed: $e', feature: 'VoiceVerification');
        if (!mounted) return;
        setState(() {
          _statusColor = AppColors.of(context).needsReviewStatus;
          _feedbackTitle = 'msg_voice_init_failed'.tr;
          _showFeedback = true;
          _isListening = false;
        });
        return;
      }
      final dir = await getTemporaryDirectory();
      _customFilePath =
          '${dir.path}/whisper_${widget.surah.id}_${widget.aya.verseNumber}_${DateTime.now().millisecondsSinceEpoch}.wav';
      try {
        await _customRecorder.startRecorder(
          toFile: _customFilePath,
          codec: Codec.pcm16WAV,
          numChannels: 1,
          sampleRate: 16000,
        );
      } catch (e) {
        Logger.warning('Whisper recorder start failed: $e', feature: 'VoiceVerification');
        if (!mounted) return;
        setState(() {
          _statusColor = AppColors.of(context).needsReviewStatus;
          _feedbackTitle = 'msg_voice_init_failed'.tr;
          _showFeedback = true;
          _isListening = false;
        });
        return;
      }
    } else {
      if (useCustom) {
        if (customEndpoint.isEmpty) {
          setState(() {
            _statusColor = AppColors.of(context).inProgressStatus;
            _feedbackTitle = 'msg_custom_asr_empty'.tr;
            _showFeedback = true;
          });
          return;
        }
        if (!_customRecorder.isStopped) {
          await _customRecorder.stopRecorder();
          await _customRecorder.closeRecorder();
        }
        await _customRecorder.openRecorder();
        final dir = await getTemporaryDirectory();
        _customFilePath =
            '${dir.path}/recite_${widget.surah.id}_${widget.aya.verseNumber}_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _customRecorder.startRecorder(
          toFile: _customFilePath,
          codec: Codec.pcm16WAV,
          numChannels: 1,
          sampleRate: 16000,
        );
      }

      unawaited(
        sl<AnalyticsService>().logRecitationStarted(surahId: widget.surah.id),
      );
      await _voiceService.listen(
        onResult: (text) {
          if (!mounted) return;
          setState(() {
            _spokenText = text;
          });
        },
        onDone: (finalText) async {
          _isListening = false;
          if (!mounted) return;
          String effectiveText = finalText;

          if (useCustom &&
              customEndpoint.isNotEmpty &&
              _customFilePath != null) {
            try {
              await _customRecorder.stopRecorder();
            } catch (e) {
              Logger.warning('Recorder stop failed: $e', feature: 'VoiceVerification');
            }
            final remoteText = await _customAsrService
                .transcribe(
                  endpoint: customEndpoint,
                  filePath: _customFilePath!,
                )
                .timeout(
                  const Duration(seconds: 35),
                  onTimeout: () {
                    Logger.warning(
                      'Custom ASR transcription timed out',
                      feature: 'VoiceVerification',
                    );
                    return null;
                  },
                );
            if (!mounted) return;
            if (remoteText != null && remoteText.isNotEmpty) {
              effectiveText = remoteText;
            }
          }

          if (!mounted) return;
          unawaited(_analyzeRecitation(effectiveText));
        },
      );
    }
  }

  void _handleQrcCheck(QrcCheckTilawa data) {
    if (!mounted) return;
    final expectedTokens = _expectedText
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final expectedCount = expectedTokens.length;

    setState(() {
      _qrcWordIndex = data.wordIndex ?? _qrcWordIndex;
      _qrcMistakes = data.tajweedMistakes;
      _qrcMistakeIndices = _qrcMistakes.map((m) => m.wordIndex ?? -1).toSet();
      _qrcMistakeLines = _qrcMistakes.map((m) {
        final wordIdx = (m.wordIndex ?? 1) - 1;
        final wordText = (wordIdx >= 0 && wordIdx < expectedTokens.length)
            ? expectedTokens[wordIdx]
            : '-';
        return '${m.name ?? 'lbl_tajweed'.tr}: $wordText';
      }).toList();
      _showFeedback = true;
      final progress = expectedCount == 0
          ? 0
          : ((_qrcWordIndex / expectedCount) * 100).round();
      _scoreText = '${'lbl_recitation_score'.tr}: $progress%';
      _issueLines = [];
      if (_qrcMistakes.isNotEmpty) {
        _issueLines.add('${'msg_tajweed_notes'.tr}: ${_qrcMistakes.length}');
      }
      _repeatLabel = '';
      _repeatWord = '';
      if (_qrcMistakes.isNotEmpty && (_qrcMistakes.first.wordIndex ?? 0) > 0) {
        final idx = (_qrcMistakes.first.wordIndex ?? 1) - 1;
        if (idx >= 0 && idx < expectedTokens.length) {
          _repeatLabel = 'msg_repeat_word'.tr;
          _repeatWord = expectedTokens[idx];
        }
      } else if (_qrcWordIndex < expectedCount) {
        _repeatLabel = 'msg_repeat_word'.tr;
        _repeatWord = expectedTokens[_qrcWordIndex];
      }
      if (_qrcWordIndex >= expectedCount &&
          expectedCount > 0 &&
          _qrcMistakes.isEmpty) {
        _statusColor = AppColors.of(context).memorizedStatus;
        _feedbackTitle = 'lbl_congrats'.tr;
        _isCorrect = true;
        _isListening = false;
      } else if (_qrcWordIndex >= expectedCount && _qrcMistakes.isNotEmpty) {
        _statusColor = AppColors.of(context).needsReviewStatus;
        _feedbackTitle = 'msg_incorrect_recitation'.tr;
        _isWrong = true;
        _isListening = false;
      }
    });
  }

  Future<void> _analyzeRecitation(String effectiveText) async {
    if (!mounted) return;
    final analysis = await _voiceService.analyzeRecitationAsync(
      effectiveText,
      _expectedText,
      allowPartial: true,
    );
    unawaited(
      sl<AnalyticsService>().logRecitationVerified(
        surahId: widget.surah.id,
        accuracy: (analysis.score * 100).roundToDouble(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _spokenText = effectiveText;
      final scorePercent = (analysis.score * 100).round();
      _scoreText = '${'lbl_recitation_score'.tr}: $scorePercent%';
      _issueLines = [];
      if (analysis.missingCount > 0) {
        _issueLines.add(
          '${'msg_recitation_missing'.tr}: ${analysis.missingCount}',
        );
      }
      if (analysis.extraCount > 0) {
        _issueLines.add('${'msg_recitation_extra'.tr}: ${analysis.extraCount}');
      }
      if (analysis.substituteCount > 0) {
        _issueLines.add(
          '${'msg_recitation_substitute'.tr}: ${analysis.substituteCount}',
        );
      }

      _hintLabel = '';
      _hintWord = '';
      _repeatLabel = '';
      _repeatWord = '';
      final expectedTokens = _expectedText
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (analysis.expectedRange.isValid &&
          analysis.expectedRange.start < expectedTokens.length &&
          !analysis.passed) {
        _hintLabel = 'msg_recitation_hint_start'.tr;
        _hintWord = expectedTokens[analysis.expectedRange.start];
        _repeatLabel = 'msg_repeat_word'.tr;
        _repeatWord = _hintWord;
      }

      _showFeedback = true;

      if (analysis.isTooShort) {
        _statusColor = AppColors.of(context).inProgressStatus;
        _feedbackTitle = 'msg_recitation_too_short'.tr;
        return;
      }

      if (analysis.passed) {
        _statusColor = AppColors.of(context).memorizedStatus;
        _feedbackTitle = 'lbl_congrats'.tr;
        _isCorrect = true;
      } else {
        _statusColor = AppColors.of(context).needsReviewStatus;
        _feedbackTitle = 'msg_incorrect_recitation'.tr;
        _isWrong = true;
      }
    });
  }

  String get _dialogTitle {
    if (_isCorrect) return 'lbl_congrats'.tr;
    if (_isWrong) return 'msg_incorrect_recitation'.tr;
    if (_isListening) return 'lbl_listening'.tr;
    if (_showFeedback) return _feedbackTitle;
    return 'lbl_recite_verify'.tr;
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      final provider = PrefUtils().getRecitationProvider();
      final bool useQrc = provider == 'qrc';
      final bool useWhisper = provider == 'local_whisper';

      if (useQrc) {
        await _qrcService.stopRecording();
        await _qrcSub?.cancel();
      } else if (useWhisper) {
        try {
          await _customRecorder.stopRecorder();
        } catch (e) {
          Logger.warning('Recorder stop failed: $e', feature: 'VoiceVerification');
        }
        if (_customFilePath != null) {
          if (mounted) {
            setState(() {
              _whisperTranscribing = true;
              _spokenText = 'msg_transcribing'.tr;
            });
          }
          final result = await _whisperService.transcribe(
            audioPath: _customFilePath!,
            language: 'ar',
            model: _whisperModel,
          );
          if (mounted) {
            setState(() {
              _whisperTranscribing = false;
            });
          }
          if (mounted && result.isSuccess) {
            unawaited(_analyzeRecitation(result.text!));
          } else if (mounted && !result.isSuccess) {
            final msg = switch (result.error) {
              WhisperError.noAudio => 'msg_whisper_no_audio',
              WhisperError.modelError => 'msg_whisper_error',
              WhisperError.permission => 'msg_mic_permission',
              _ => 'msg_whisper_error',
            };
            setState(() {
              _statusColor = AppColors.of(context).needsReviewStatus;
              _feedbackTitle = msg.tr;
              _showFeedback = true;
              _isListening = false;
            });
          }
        }
      } else {
        final bool useCustom = provider == 'custom';
        if (useCustom) {
          try {
            await _customRecorder.stopRecorder();
          } catch (e) {
            Logger.warning('Recorder stop failed: $e', feature: 'VoiceVerification');
          }
        }
        await _voiceService.stop();
      }

      _isListening = false;
      if (mounted) {
        setState(() {
          _statusColor = AppColors.of(context).notStartedStatus;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = PrefUtils().getRecitationProvider();
    final bool useQrc = provider == 'qrc';
    final bool useWhisper = provider == 'local_whisper';

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Semantics(header: true, child: Text(_dialogTitle)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: _isListening
                  ? 'msg_tap_to_stop'.tr
                  : 'lbl_tap_to_speak'.tr,
              child: GestureDetector(
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else if (!_isCorrect && !_isWrong) {
                    _startListening();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.1)
                        : _isCorrect
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)
                        : _isWrong
                        ? Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.1)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    _isListening
                        ? Icons.mic
                        : _isCorrect
                        ? Icons.check_circle
                        : _isWrong
                        ? Icons.refresh
                        : Icons.mic_none,
                    size: 48,
                    color: _isListening
                        ? Theme.of(context).colorScheme.error
                        : _isCorrect
                        ? Theme.of(context).colorScheme.primary
                        : _isWrong
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!useQrc && _spokenText.isNotEmpty) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _spokenText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'NotoNaskhArabic',
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (!_showFeedback && !_isCorrect && !_isWrong)
              Text(
                _isListening ? 'msg_tap_to_stop'.tr : 'lbl_tap_to_speak'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            if (useQrc) ...[
              const SizedBox(height: 12),
              if (_qrcConnecting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _expectedText
                      .split(RegExp(r'\s+'))
                      .where((t) => t.isNotEmpty)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final idx = entry.key + 1;
                        final word = entry.value;
                        final isCorrect = _qrcWordIndex >= idx;
                        final isMistake = _qrcMistakeIndices.contains(idx);
                        final colorScheme = Theme.of(context).colorScheme;
                        Color color = colorScheme.onSurface
                            .withValues(alpha: 0.87);
                        if (isCorrect) color = colorScheme.primary;
                        if (isMistake) color = colorScheme.error;
                        return Text(
                          word,
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'NotoNaskhArabic',
                            color: color,
                            fontWeight: isCorrect
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
              if (_qrcMistakeLines.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final line in _qrcMistakeLines)
                  Text(
                    line,
                    style: TextStyle(fontSize: 12, color: AppColors.of(context).needsReviewStatus),
                  ),
              ],
            ],
            if (useWhisper && _whisperTranscribing) ...[
              const SizedBox(height: 12),
              const CircularProgressIndicator(strokeWidth: 2),
            ],
            if (_showFeedback) ...[
              const SizedBox(height: 12),
              Text(
                _feedbackTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _scoreText,
                style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
              ),
              if (_issueLines.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final line in _issueLines)
                  Text(line, style: const TextStyle(fontSize: 12)),
              ],
              if (_hintLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _hintLabel,
                  style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
                ),
                Text(
                  _hintWord,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'NotoNaskhArabic',
                  ),
                ),
              ],
              if (_repeatLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _repeatLabel,
                  style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
                ),
                Text(
                  _repeatWord,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'NotoNaskhArabic',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (_isWrong && !_isListening) ...[
                const SizedBox(height: 6),
                Text(
                  'msg_coach_tip_slow'.tr,
                  style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
                ),
              ],
            ],
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'lbl_original'.tr,
              style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
            ),
            const SizedBox(height: 8),
            Text(
              _expectedText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'NotoNaskhArabic',
              ),
            ),
          ],
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => SheikhAudioCoachSheet(
                chapterNumber: widget.surah.id,
                verseNumber: widget.aya.verseNumber,
                expectedText: _expectedText,
                reciterId: PrefUtils().getReciterId(),
              ),
            );
          },
          child: Text('lbl_listen_sheikh'.tr),
        ),
        if (_isCorrect)
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCorrect();
            },
            child: Text('lbl_continue'.tr),
          )
        else if (_isWrong) ...[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSaveForPractice();
            },
            child: Text('lbl_save_practice'.tr),
          ),
          FilledButton(
            onPressed: () async {
              await _cleanup();
              setState(() => _resetState());
              await _startListening();
            },
            child: Text('lbl_try_again'.tr),
          ),
        ] else
          TextButton(
            onPressed: () {
              _stopListening();
              Navigator.pop(context);
            },
            child: Text('lbl_close'.tr),
          ),
      ],
    );
  }
}
