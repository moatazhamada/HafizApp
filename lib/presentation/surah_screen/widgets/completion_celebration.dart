import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/qrc/adaptive_qrc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/surah_name_formatter.dart';
import 'package:hafiz_app/domain/entities/reading_session.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_bloc.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_event.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_bloc.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_event.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_bloc.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_event.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_state.dart';
import 'completion_dialog.dart';

class CompletionCelebration extends StatefulWidget {
  final Surah? surah;

  const CompletionCelebration({super.key, required this.surah});

  @override
  CompletionCelebrationState createState() => CompletionCelebrationState();
}

class CompletionCelebrationState extends State<CompletionCelebration> {
  void _safeAdd(Bloc bloc, Object event) {
    try {
      if (!bloc.isClosed) {
        bloc.add(event);
      }
    } catch (e, s) {
      Logger.warning('Failed to add event to bloc: $e\n$s', feature: 'CompletionCelebration');
    }
  }

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
    _safeAdd(sl<RecitationSessionBloc>(), SaveSession(session));
    _safeAdd(
      sl<MemorizationBloc>(),
      RecordReview(surahId: widget.surah!.id, score: percentage),
    );
    _safeAdd(sl<KhatmahBloc>(), RecordReading(verses: totalCount));

    final readingSession = ReadingSession(
      surahId: widget.surah!.id,
      startVerse: 1,
      endVerse: totalCount,
      durationSeconds: 0, // Duration tracking for voice sessions can be added later
      readAt: DateTime.now(),
    );
    unawaited(
      sl<KhatmahRepository>().reportReadingSession(readingSession),
    );
    unawaited(
      sl<AnalyticsService>().logReadingSession(
        chapterNumber: widget.surah!.id,
        versesRead: totalCount,
      ),
    );

    if (PrefUtils().isAdaptiveQrc()) {
      final bloc = sl<RecitationSessionBloc>();
      if (!bloc.isClosed) {
        bloc.add(LoadSessions());
        bloc.stream
            .firstWhere((s) => s is RecitationSessionLoaded)
            .timeout(const Duration(seconds: 5))
            .then((state) {
              if (state is RecitationSessionLoaded) {
                AdaptiveQrc.evaluateAndAdjust(state.sessions);
              }
            })
            .catchError((e) {
              Logger.warning(
                'Adaptive QRC evaluation failed: $e',
                feature: 'QRC',
              );
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
