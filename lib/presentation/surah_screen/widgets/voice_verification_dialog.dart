import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

import '../../../core/app_export.dart';

import '../../../domain/entities/verse.dart';
import '../../../core/quran_index/quran_surah.dart';
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
  final Function(BuildContext context) onWrong;

  const VoiceVerificationDialog({
    super.key,
    required this.surah,
    required this.aya,
    required this.expectedText,
    required this.onCorrect,
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
  String _spokenText = 'lbl_listening'.tr;
  Color _statusColor = Colors.blueAccent;
  String _feedbackTitle = '';
  String _scoreText = '';
  String _hintLabel = '';
  String _hintWord = '';
  List<String> _issueLines = [];
  bool _showFeedback = false;

  // QRC State
  String _qrcStatus = '';
  bool _qrcConnecting = false;
  int _qrcWordIndex = 0;
  List<QrcTajweedMistake> _qrcMistakes = [];
  List<String> _qrcMistakeLines = [];
  String _repeatLabel = '';
  String _repeatWord = '';
  StreamSubscription? _qrcSub;

  // Whisper / Custom
  String? _customFilePath;
  bool _whisperTranscribing = false;
  late WhisperModel _whisperModel;

  bool _autoAdvanced = false;

  @override
  void initState() {
    super.initState();
    _expectedText = widget.expectedText;
    _whisperModel = _resolveWhisperModel(PrefUtils().getWhisperModel());

    // Auto-start listening on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    if (!_autoAdvanced) {
      _cleanup();
    }
    super.dispose();
  }

  Future<void> _cleanup() async {
    await _voiceService.stop();
    await _qrcSub?.cancel();
    await _qrcService.dispose();
    try {
      await _customRecorder.closeRecorder();
    } catch (_) {}
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

  Future<void> _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;

      _statusColor = Colors.blueAccent;
      _spokenText = 'lbl_listening'.tr;
    });

    final provider = PrefUtils().getRecitationProvider();
    final bool useQrc = provider == 'qrc';
    final bool useCustom = provider == 'custom';
    final bool useWhisper = provider == 'local_whisper';
    final String customEndpoint = PrefUtils().getCustomAsrEndpoint();

    if (useQrc) {
      setState(() {
        _qrcConnecting = true;
        _qrcStatus = 'lbl_connecting'.tr;
      });

      final connected = await _qrcService.connect();
      if (!connected) {
        if (!mounted) return;
        setState(() {
          _statusColor = Colors.redAccent;
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
          setState(() {
            _qrcStatus = event.status;
            if (event.status == 'connected' ||
                event.status == 'check_tilawa' ||
                event.status == 'CheckTilawaResponse') {
              _qrcConnecting = false;
            }
          });
        } else if (event is QrcCheckEvent) {
          _handleQrcCheck(event.data);
        } else if (event is QrcErrorEvent) {
          setState(() {
            _statusColor = Colors.redAccent;
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
      await _customRecorder.openRecorder();
      final dir = await getTemporaryDirectory();
      _customFilePath =
          '${dir.path}/whisper_${widget.surah.id}_${widget.aya.verseNumber}_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _customRecorder.startRecorder(
        toFile: _customFilePath,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
      );
      setState(() {
        _spokenText = 'lbl_listening'.tr;
      });
    } else {
      if (useCustom) {
        if (customEndpoint.isEmpty) {
          setState(() {
            _statusColor = Colors.orangeAccent;
            _feedbackTitle = 'msg_custom_asr_empty'.tr;
            _showFeedback = true;
          });
        } else {
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
      }

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
            } catch (_) {}
            final remoteText = await _customAsrService.transcribe(
              endpoint: customEndpoint,
              filePath: _customFilePath!,
            );
            if (remoteText != null && remoteText.isNotEmpty) {
              effectiveText = remoteText;
            }
          }

          _analyzeRecitation(effectiveText);
        },
      );
    }
  }

  void _handleQrcCheck(QrcCheckTilawa data) {
    setState(() {
      _qrcWordIndex = data.wordIndex ?? _qrcWordIndex;
      _qrcMistakes = data.tajweedMistakes;
      _qrcMistakeLines = _qrcMistakes
          .map((m) => '${m.name ?? 'Tajweed'} (${m.wordIndex ?? '-'})')
          .toList();
      _showFeedback = true;
      final expectedTokens = _expectedText
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      final expectedCount = expectedTokens.length;
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
        _statusColor = Colors.green;
        _feedbackTitle = 'lbl_congrats'.tr;
        _handleSuccess();
      }
    });
  }

  void _analyzeRecitation(String effectiveText) {
    final analysis = _voiceService.analyzeRecitation(
      effectiveText,
      _expectedText,
      allowPartial: true,
    );
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
        _statusColor = Colors.orangeAccent;
        _feedbackTitle = 'msg_recitation_too_short'.tr;
        return;
      }

      if (analysis.passed) {
        _statusColor = Colors.green;
        _feedbackTitle = 'lbl_congrats'.tr;
        _handleSuccess();
      } else {
        _statusColor = Colors.redAccent;
        _feedbackTitle = 'msg_incorrect_recitation'.tr;
        _handleFailure();
      }
    });
  }

  void _handleSuccess() {
    unawaited(
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && Navigator.canPop(context)) {
          _autoAdvanced = true;
          Navigator.pop(context);
          widget.onCorrect();
        }
      }),
    );
  }

  void _handleFailure() {
    unawaited(
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && Navigator.canPop(context)) {
          _autoAdvanced = true;
          Navigator.pop(context); // Close dialog
          widget.onWrong(
            context,
          ); // Pass context if needed, but callback handles it
        }
      }),
    );
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
        } catch (_) {}
        if (_customFilePath != null) {
          setState(() {
            _whisperTranscribing = true;
            _spokenText = 'msg_transcribing'.tr;
          });
          final transcribed = await _whisperService.transcribe(
            audioPath: _customFilePath!,
            language: 'ar',
            model: _whisperModel,
          );
          setState(() {
            _whisperTranscribing = false;
          });
          if (transcribed != null && transcribed.isNotEmpty) {
            _analyzeRecitation(transcribed);
          }
        }
      } else {
        final bool useCustom = provider == 'custom';
        if (useCustom) {
          try {
            await _customRecorder.stopRecorder();
          } catch (_) {}
        }
        await _voiceService.stop();
      }

      _isListening = false;
      if (mounted) {
        setState(() {
          _statusColor = Colors.grey;
          _spokenText = 'msg_tap_to_resume'.tr;
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
      title: Semantics(header: true, child: Text('lbl_recite_verify'.tr)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: _isListening ? 'msg_tap_to_stop'.tr : 'lbl_tap_to_speak'.tr,
            child: GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : Colors.blueAccent.withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(20),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  size: 48,
                  color: _isListening ? Colors.redAccent : Colors.blueAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!useQrc) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _spokenText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Amiri',
                  color: _statusColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            _isListening ? 'msg_tap_to_stop'.tr : 'lbl_tap_to_speak'.tr,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (useQrc) ...[
            const SizedBox(height: 12),
            if (_qrcConnecting)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (_qrcStatus.isNotEmpty)
              Text(
                _qrcStatus,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Wrap(
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
                    final isMistake = _qrcMistakes.any(
                      (m) => m.wordIndex == idx,
                    );
                    Color color = Colors.black87;
                    if (isCorrect) color = Colors.green;
                    if (isMistake) color = Colors.redAccent;
                    return Text(
                      word,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Amiri',
                        color: color,
                        fontWeight: isCorrect
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  })
                  .toList(),
            ),
            if (_qrcMistakeLines.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final line in _qrcMistakeLines)
                Text(
                  line,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
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
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                _hintWord,
                style: const TextStyle(fontSize: 14, fontFamily: 'Amiri'),
              ),
            ],
            if (_repeatLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _repeatLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                _repeatWord,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'msg_coach_tip_slow'.tr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          Text(
            'lbl_original'.tr,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _expectedText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontFamily: 'Amiri'),
          ),
        ],
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
