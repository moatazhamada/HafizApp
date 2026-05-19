import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/domain/entities/hifz_entry.dart';
import 'package:hafiz_app/domain/repository/hifz_repository.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:uuid/uuid.dart';

import 'hifz_event.dart';
import 'hifz_state.dart';

class HifzBloc extends Bloc<HifzEvent, HifzState> {
  final HifzRepository repository;

  HifzBloc({required this.repository}) : super(HifzInitial()) {
    on<LoadHifzEntries>(_onLoad);
    on<AddHifzEntry>(_onAdd);
    on<LogHifzReview>(_onLogReview);
    on<DeleteHifzEntry>(_onDelete);
    on<MigrateOldHifzData>(_onMigrate);
  }

  Future<void> _onLoad(LoadHifzEntries event, Emitter<HifzState> emit) async {
    emit(HifzLoading());
    final result = await repository.getAllEntries();
    result.fold(
      (failure) => emit(HifzError(failure.errorMessage)),
      (entries) => emit(_groupEntries(entries)),
    );
  }

  Future<void> _onAdd(AddHifzEntry event, Emitter<HifzState> emit) async {
    emit(HifzActionLoading());
    final entry = HifzEntry(
      id: const Uuid().v4(),
      surahId: event.surahId,
      startVerse: event.startVerse,
      endVerse: event.endVerse,
      title: event.title,
      status: HifzStatus.newLesson,
      memorizedDate: DateTime.now(),
      lastReviewedDate: DateTime.now(),
    );
    final result = await repository.saveEntry(entry);
    result.fold(
      (failure) => emit(HifzActionError(failure.errorMessage)),
      (_) {
        unawaited(sl<AnalyticsService>().logRawEvent(
          'hifz_entry_created',
          parameters: {'surah_id': event.surahId, 'verse_count': event.endVerse - event.startVerse + 1},
        ));
        add(LoadHifzEntries());
      },
    );
  }

  Future<void> _onLogReview(LogHifzReview event, Emitter<HifzState> emit) async {
    emit(HifzActionLoading());
    final result = await repository.logReview(
      entryId: event.entryId,
      score: event.score,
      scoreLabel: event.scoreLabel,
    );
    result.fold(
      (failure) => emit(HifzActionError(failure.errorMessage)),
      (updated) {
        unawaited(sl<AnalyticsService>().logRawEvent(
          'hifz_review_logged',
          parameters: {'entry_id': event.entryId, 'score': event.score},
        ));
        add(LoadHifzEntries());
      },
    );
  }

  Future<void> _onDelete(DeleteHifzEntry event, Emitter<HifzState> emit) async {
    emit(HifzActionLoading());
    final result = await repository.deleteEntry(event.entryId);
    result.fold(
      (failure) => emit(HifzActionError(failure.errorMessage)),
      (_) => add(LoadHifzEntries()),
    );
  }

  Future<void> _onMigrate(MigrateOldHifzData event, Emitter<HifzState> emit) async {
    final result = await repository.migrateOldData();
    result.fold(
      (failure) => Logger.warning('Hifz migration failed: ${failure.errorMessage}', feature: 'Hifz'),
      (_) => add(LoadHifzEntries()),
    );
  }

  HifzLoaded _groupEntries(List<HifzEntry> entries) {
    final today = DateTime.now();
    final dueToday = <HifzEntry>[];
    final newLessons = <HifzEntry>[];
    final recent = <HifzEntry>[];
    final solid = <HifzEntry>[];
    final mastered = <HifzEntry>[];
    final weak = <HifzEntry>[];

    for (final e in entries) {
      if (e.isDueForReview(today)) {
        dueToday.add(e);
      }
      switch (e.status) {
        case HifzStatus.newLesson:
          newLessons.add(e);
        case HifzStatus.recent:
          recent.add(e);
        case HifzStatus.solid:
          solid.add(e);
        case HifzStatus.mastered:
          mastered.add(e);
        case HifzStatus.weak:
          weak.add(e);
      }
    }

    // Sort dueToday by urgency (most overdue first)
    dueToday.sort((a, b) => a.daysUntilNextReview(today).compareTo(b.daysUntilNextReview(today)));

    return HifzLoaded(
      entries: entries,
      dueToday: dueToday,
      newLessons: newLessons,
      recent: recent,
      solid: solid,
      mastered: mastered,
      weak: weak,
      totalEntries: entries.length,
      masteredCount: mastered.length,
    );
  }
}
