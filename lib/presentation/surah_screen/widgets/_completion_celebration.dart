part of '../surah_screen.dart';

class _CompletionCelebration extends StatefulWidget {
  final Surah? surah;

  const _CompletionCelebration({super.key, required this.surah});

  @override
  _CompletionCelebrationState createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<_CompletionCelebration> {
  void show({
    required double percentage,
    required int correctCount,
    required int totalCount,
    required VoidCallback onClose,
  }) {
    _saveSession(percentage, correctCount, totalCount);
    showCompletionDialog(
      context,
      percentage: percentage,
      onClose: onClose,
    );
  }

  void _saveSession(double percentage, int correctCount, int totalCount) {
    if (widget.surah == null || totalCount == 0) return;

    final session = RecitationSession(
      id: '${widget.surah!.id}_${DateTime.now().millisecondsSinceEpoch}',
      surahId: widget.surah!.id,
      surahName: widget.surah!.localizedName(context),
      totalVerses: totalCount,
      correctCount: correctCount,
      totalCount: totalCount,
      score: percentage,
      createdAt: DateTime.now(),
    );
    sl<RecitationSessionBloc>().add(SaveSession(session));
    sl<MemorizationBloc>().add(
      RecordReview(surahId: widget.surah!.id, score: percentage),
    );
    sl<KhatmahBloc>().add(RecordReading(verses: totalCount));

    unawaited(
      sl<KhatmahRepository>().reportReadingSession(widget.surah!.id, 1),
    );
    unawaited(
      sl<AnalyticsService>().logReadingSession(
        chapterNumber: widget.surah!.id,
        versesRead: totalCount,
      ),
    );

    if (PrefUtils().isAdaptiveQrc()) {
      sl<RecitationSessionBloc>().add(LoadSessions());
      sl<RecitationSessionBloc>()
          .stream
          .firstWhere((s) => s is RecitationSessionLoaded)
          .timeout(const Duration(seconds: 5))
          .then((state) {
            if (state is RecitationSessionLoaded) {
              AdaptiveQrc.evaluateAndAdjust(state.sessions);
            }
          })
          .catchError((e) {
            Logger.warning(
              'Adaptive QRC evaluation failed: \$e',
              feature: 'QRC',
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
