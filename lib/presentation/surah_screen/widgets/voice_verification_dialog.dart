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
  String _spokenText = '';
  Color _statusColor = Colors.blueAccent;
  String _feedbackTitle = '';
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
    _expectedText = widget.expectedText;
    _whisperModel = _resolveWhisperModel(PrefUtils().getWhisperModel());

    // Auto-start listening on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _cleanup();
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

  void _resetState() {
    _isListening = false;
    _spokenText = '';
    _statusColor = Colors.blueAccent;
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

    setState(() {
      _resetState();
      _isListening = true;
      _statusColor = Colors.blueAccent;
    });

    final provider = PrefUtils().getRecitationProvider();
    final bool useQrc = provider == 'qrc';
    final bool useCustom = provider == 'custom';
    final bool useWhisper = provider == 'local_whisper';
    final String customEndpoint = PrefUtils().getCustomAsrEndpoint();

    if (useQrc) {
      setState(() {
        _qrcConnecting = true;
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
          if (event.status == 'connected' ||
              event.status == 'check_tilawa' ||
              event.status == 'CheckTilawaResponse') {
            setState(() => _qrcConnecting = false);
          }
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
    } else {
      if (useCustom) {
        if (customEndpoint.isEmpty) {
          setState(() {
            _statusColor = Colors.orangeAccent;
            _feedbackTitle = 'msg_custom_asr_empty'.tr;
            _showFeedback = true;
          });
          return;
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
        final wordText =
            (wordIdx >= 0 && wordIdx < expectedTokens.length)
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
        _statusColor = Colors.green;
        _feedbackTitle = 'lbl_congrats'.tr;
        _isCorrect = true;
        _isListening = false;
      } else if (_qrcWordIndex >= expectedCount && _qrcMistakes.isNotEmpty) {
        _statusColor = Colors.redAccent;
        _feedbackTitle = 'msg_incorrect_recitation'.tr;
        _isWrong = true;
        _isListening = false;
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
        _isCorrect = true;
      } else {
        _statusColor = Colors.redAccent;
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
        } catch (_) {}
        if (_customFilePath != null) {
          if (mounted) {
            setState(() {
              _whisperTranscribing = true;
              _spokenText = 'msg_transcribing'.tr;
            });
          }
          final transcribed = await _whisperService.transcribe(
            audioPath: _customFilePath!,
            language: 'ar',
            model: _whisperModel,
          );
          if (mounted) {
            setState(() {
              _whisperTranscribing = false;
            });
          }
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
      title: Semantics(header: true, child: Text(_dialogTitle)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: _isListening ? 'msg_tap_to_stop'.tr : 'lbl_tap_to_speak'.tr,
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
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : _isCorrect
                            ? Colors.green.withValues(alpha: 0.1)
                            : _isWrong
                                ? Colors.orangeAccent.withValues(alpha: 0.1)
                                : Colors.blueAccent.withValues(alpha: 0.1),
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
                        ? Colors.redAccent
                        : _isCorrect
                            ? Colors.green
                            : _isWrong
                                ? Colors.orangeAccent
                                : Colors.blueAccent,
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                        Color color = Colors.black87;
                        if (isCorrect) color = Colors.green;
                        if (isMistake) color = Colors.redAccent;
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
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
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, fontFamily: 'NotoNaskhArabic'),
            ),
          ],
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
              widget.onWrong(context);
            },
            child: Text('lbl_save_practice'.tr),
          ),
          FilledButton(
            onPressed: () {
              _cleanup();
              setState(() => _resetState());
              _startListening();
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
