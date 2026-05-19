import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran/quran_word_models.dart';
import 'package:just_audio/just_audio.dart';

class WordByWordSection extends StatefulWidget {
  final VerseWordData? words;

  const WordByWordSection({super.key, this.words});

  @override
  State<WordByWordSection> createState() => _WordByWordSectionState();
}

class _WordByWordSectionState extends State<WordByWordSection> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playWord(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      Logger.warning('Failed to play word audio: $e', feature: 'VerseStudy');
    }
  }

  @override
  Widget build(BuildContext context) {
    final words =
        widget.words?.words.where((w) => w.charType != 'end').toList() ?? [];
    if (words.isEmpty) {
      return Center(child: Text('lbl_loading'.tr));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          spacing: 12,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          textDirection: TextDirection.rtl,
          children: words.map((word) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap:
                    word.fullAudioUrl != null
                        ? () => _playWord(word.fullAudioUrl)
                        : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.textUthmani,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: PrefUtils().getQuranFontSize(),
                          fontFamily: 'NotoNaskhArabic',
                        ),
                      ),
                      if (word.transliteration != null &&
                          word.transliteration!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            word.transliteration!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
