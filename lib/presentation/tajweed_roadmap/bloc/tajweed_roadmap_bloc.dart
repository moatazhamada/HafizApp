import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/tajweed/tajweed_analyzer.dart';
import 'package:hafiz_app/core/tajweed/tajweed_models.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/domain/repository/recitation_error_repository.dart';
import 'package:hafiz_app/domain/repository/recitation_session_repository.dart';

part 'tajweed_roadmap_event.dart';
part 'tajweed_roadmap_state.dart';

class TajweedRoadmapBloc
    extends Bloc<TajweedRoadmapEvent, TajweedRoadmapState> {
  final RecitationSessionRepository sessionRepository;
  final RecitationErrorRepository errorRepository;

  TajweedRoadmapBloc({
    required this.sessionRepository,
    required this.errorRepository,
  }) : super(const TajweedRoadmapInitial()) {
    on<LoadTajweedRoadmap>(_onLoad);
  }

  Future<void> _onLoad(
    LoadTajweedRoadmap event,
    Emitter<TajweedRoadmapState> emit,
  ) async {
    emit(const TajweedRoadmapLoading());
    try {
      final sessionsResult = await sessionRepository.getSessions();
      final errorsResult = await errorRepository.getRecitationErrors();

      final sessions = sessionsResult.fold(
        (_) => <RecitationSession>[],
        (s) => s,
      );
      final errors = errorsResult.fold(
        (_) => <RecitationErrorModel>[],
        (e) => e,
      );

      final progress = TajweedAnalyzer.analyze(
        sessions: sessions,
        errors: errors,
      );

      final practiceItems = TajweedAnalyzer.generatePracticePlan(progress);

      emit(
        TajweedRoadmapLoaded(progress: progress, practiceItems: practiceItems),
      );
    } catch (e) {
      emit(TajweedRoadmapError(e.toString()));
    }
  }
}
