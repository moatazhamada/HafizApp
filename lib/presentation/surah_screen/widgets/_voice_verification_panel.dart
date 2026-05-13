part of '../surah_screen.dart';

class _VoiceVerificationPanel extends StatefulWidget {
  final Surah? surah;
  final SurahBloc surahBloc;
  final GlobalKey<_CompletionCelebrationState> completionKey;

  const _VoiceVerificationPanel({
    super.key,
    required this.surah,
    required this.surahBloc,
    required this.completionKey,
  });

  @override
  _VoiceVerificationPanelState createState() =>
      _VoiceVerificationPanelState();
}

class _VoiceVerificationPanelState extends State<_VoiceVerificationPanel> {
  final VoiceVerificationService _voiceService = VoiceVerificationService();
  final QiraatService _qiraatService = QiraatService();
  int _sessionCorrectCount = 0;
  int _sessionTotalCount = 0;

  Future<void> show(Verse aya) async {
    bool available = await _voiceService.requestPermission();

    if (!mounted) return;

    if (!available) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('msg_mic_permission'.tr),
          content: Text('msg_mic_permission_desc'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('lbl_cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                openAppSettings();
              },
              child: Text('lbl_settings'.tr),
            ),
          ],
        ),
      );
      return;
    }

    String expectedText = await _resolveExpectedText(aya);
    if (aya.verseNumber == 1 && widget.surah?.id != 1) {
      const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
      const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
      if (expectedText.startsWith(bismillahPrefix)) {
        expectedText = expectedText.substring(bismillahPrefix.length).trim();
      } else if (expectedText.startsWith(bismillahSimple)) {
        expectedText = expectedText.substring(bismillahSimple.length).trim();
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VoiceVerificationDialog(
        surah: widget.surah!,
        aya: aya,
        expectedText: expectedText,
        onCorrect: () {
          HapticFeedback.heavyImpact();
          if (mounted) {
            _onRecitationCorrect(aya);
          }
        },
        onSaveForPractice: () {
          HapticFeedback.mediumImpact();
          if (mounted) {
            _saveAndAdvanceToNext(aya);
          }
        },
        onWrong: (ctx) {
          HapticFeedback.mediumImpact();
          if (mounted) {
            _showWrongDialog(aya);
          }
        },
      ),
    );
  }

  Future<String> _resolveExpectedText(Verse aya) async {
    if (widget.surah == null) return aya.arabicText;
    final edition = PrefUtils().getQiraatEdition();
    if (edition == 'quran-uthmani' || edition.isEmpty) {
      return aya.arabicText;
    }
    final remoteText = await _qiraatService.fetchAyahText(
      surahId: widget.surah!.id,
      verseNumber: aya.verseNumber,
      edition: edition,
    );
    return remoteText ?? aya.arabicText;
  }

  void _onRecitationCorrect(Verse currentVerse) {
    if (!mounted) return;

    _sessionCorrectCount++;
    _sessionTotalCount++;

    final currentState = widget.surahBloc.state;
    if (currentState is SuccessSurahState) {
      final chapters = currentState.chapters;
      final currentIndex = chapters.indexWhere(
        (v) => v.verseNumber == currentVerse.verseNumber,
      );

      if (currentIndex != -1 && currentIndex < chapters.length - 1) {
        final nextVerse = chapters[currentIndex + 1];
        show(nextVerse);
      } else {
        _showCompletionDialog();
      }
    }
  }

  void _saveAndAdvanceToNext(Verse aya) {
    _sessionTotalCount++;
    final recitationErrorBloc = context.read<RecitationErrorBloc>();
    recitationErrorBloc.add(
      AddRecitationErrorEvent(
        RecitationErrorModel(
          surahId: widget.surah!.id,
          surahName: widget.surah!.nameEnglish,
          verseId: aya.verseNumber,
          createdAt: DateTime.now(),
        ),
      ),
    );

    final currentState = widget.surahBloc.state;
    if (currentState is SuccessSurahState) {
      final chapters = currentState.chapters;
      final currentIndex = chapters.indexWhere(
        (v) => v.verseNumber == aya.verseNumber,
      );
      if (currentIndex != -1 && currentIndex < chapters.length - 1) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            show(chapters[currentIndex + 1]);
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showCompletionDialog();
        });
      }
    }
  }

  void _showWrongDialog(Verse aya) {
    _sessionTotalCount++;

    final recitationErrorBloc = context.read<RecitationErrorBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('lbl_incorrect'.tr),
        content: Text('msg_incorrect_recitation'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  show(aya);
                }
              });
            },
            child: Text('lbl_try_again'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              recitationErrorBloc.add(
                AddRecitationErrorEvent(
                  RecitationErrorModel(
                    surahId: widget.surah!.id,
                    surahName: widget.surah!.nameEnglish,
                    verseId: aya.verseNumber,
                    createdAt: DateTime.now(),
                  ),
                ),
              );
              Navigator.pop(dialogContext);

              final currentState = widget.surahBloc.state;
              if (currentState is SuccessSurahState) {
                final chapters = currentState.chapters;
                final currentIndex = chapters.indexWhere(
                  (v) => v.verseNumber == aya.verseNumber,
                );
                if (currentIndex != -1 && currentIndex < chapters.length - 1) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      show(chapters[currentIndex + 1]);
                    }
                  });
                } else {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _showCompletionDialog();
                  });
                }
              }
            },
            child: Text('lbl_save_practice'.tr),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    if (!mounted) return;

    double percentage = 0;
    if (_sessionTotalCount > 0) {
      percentage = (_sessionCorrectCount / _sessionTotalCount) * 100;
    }

    widget.completionKey.currentState?.show(
      percentage: percentage,
      correctCount: _sessionCorrectCount,
      totalCount: _sessionTotalCount,
      onClose: () {
        _sessionCorrectCount = 0;
        _sessionTotalCount = 0;
      },
    );
  }

  @override
  void dispose() {
    _voiceService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
