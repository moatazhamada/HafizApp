import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/app_export.dart';
import '../../core/audio/recitation_models.dart';
import '../../core/audio/recitation_service.dart';

class SheikhAudioCoachSheet extends StatefulWidget {
  final int chapterNumber;
  final int verseNumber;
  final String expectedText;
  final int reciterId;

  const SheikhAudioCoachSheet({
    super.key,
    required this.chapterNumber,
    required this.verseNumber,
    required this.expectedText,
    required this.reciterId,
  });

  @override
  State<SheikhAudioCoachSheet> createState() => _SheikhAudioCoachSheetState();
}

class _SheikhAudioCoachSheetState extends State<SheikhAudioCoachSheet> {
  final RecitationService _recitationService = RecitationService();
  final AudioPlayer _player = AudioPlayer();
  ChapterAudioFile? _audioFile;
  VerseTiming? _verseTiming;
  int _currentWordIndex = 0;
  bool _isLoading = true;
  bool _isPlaying = false;
  StreamSubscription<Duration>? _posSub;

  List<String> get _words => widget.expectedText
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final audio = await _recitationService.fetchChapterAudio(
      reciterId: widget.reciterId,
      chapterNumber: widget.chapterNumber,
      segments: true,
    );
    if (!mounted) return;
    setState(() {
      _audioFile = audio;
      _verseTiming = _findVerseTiming(audio);
      _isLoading = false;
    });
  }

  VerseTiming? _findVerseTiming(ChapterAudioFile? audio) {
    if (audio == null) return null;
    final key = '${widget.chapterNumber}:${widget.verseNumber}';
    return audio.timings.firstWhere(
      (t) => t.verseKey == key,
      orElse: () => const VerseTiming(
        verseKey: '',
        timestampFrom: 0,
        timestampTo: 0,
        segments: [],
      ),
    );
  }

  Future<void> _play() async {
    final timing = _verseTiming;
    final audio = _audioFile;
    if (timing == null || audio == null || audio.audioUrl.isEmpty) return;

    await _player.setUrl(audio.audioUrl);
    await _player.seek(Duration(milliseconds: timing.timestampFrom));
    await _player.play();
    await _posSub?.cancel();
    _posSub = _player.positionStream.listen((pos) async {
      final currentMs = pos.inMilliseconds;
      _updateWordIndex(currentMs, timing);
      if (currentMs >= timing.timestampTo && _isPlaying) {
        await _stop();
      }
    });
    setState(() => _isPlaying = true);
  }

  Future<void> _stop() async {
    await _player.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _repeatWord() async {
    final timing = _verseTiming;
    final audio = _audioFile;
    if (timing == null || audio == null || audio.audioUrl.isEmpty) return;
    if (timing.segments.isEmpty) {
      await _player.seek(Duration(milliseconds: timing.timestampFrom));
      return;
    }
    final idx = (_currentWordIndex - 1).clamp(0, timing.segments.length - 1);
    final seg = timing.segments[idx];
    await _player.seek(Duration(milliseconds: seg.startMs));
  }

  void _updateWordIndex(int currentMs, VerseTiming timing) {
    int newIndex = _currentWordIndex;
    for (final seg in timing.segments) {
      if (currentMs >= seg.startMs) {
        newIndex = seg.wordIndex;
      }
    }
    if (newIndex != _currentWordIndex && mounted) {
      setState(() => _currentWordIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'lbl_sheikh_listen'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_words.length, (index) {
                    final word = _words[index];
                    final highlight = _currentWordIndex >= index + 1;
                    return Text(
                      word,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Amiri',
                        color: highlight ? Colors.green : Colors.black87,
                        fontWeight:
                            highlight ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? _stop : _play,
                      icon:
                          Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(
                        _isPlaying ? 'lbl_pause'.tr : 'lbl_play'.tr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _repeatWord,
                      child: Text('lbl_repeat_word'.tr),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
