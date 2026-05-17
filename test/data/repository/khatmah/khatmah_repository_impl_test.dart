import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/data/datasource/khatmah/khatmah_local_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_activity/qf_activity_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'package:hafiz_app/data/model/reading_goal_model.dart';
import 'package:hafiz_app/data/model/reading_session_model.dart';
import 'package:hafiz_app/data/repository/khatmah/khatmah_repository_impl.dart';
import 'package:hafiz_app/domain/entities/reading_session.dart';
import 'package:mocktail/mocktail.dart';

class MockKhatmahLocalDataSource extends Mock implements KhatmahLocalDataSource {}
class MockQfActivityRemoteDataSource extends Mock implements QfActivityRemoteDataSource {}
class MockQfGoalsRemoteDataSource extends Mock implements QfGoalsRemoteDataSource {}

class DailyReadingLogModelFake extends Fake implements DailyReadingLogModel {}
class ReadingSessionModelFake extends Fake implements ReadingSessionModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(DailyReadingLogModelFake());
    registerFallbackValue(ReadingSessionModelFake());
  });

  late KhatmahRepositoryImpl repository;
  late MockKhatmahLocalDataSource mockLocalDataSource;
  late MockQfActivityRemoteDataSource mockActivityRemoteDataSource;
  late MockQfGoalsRemoteDataSource mockGoalsRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockKhatmahLocalDataSource();
    mockActivityRemoteDataSource = MockQfActivityRemoteDataSource();
    mockGoalsRemoteDataSource = MockQfGoalsRemoteDataSource();
    repository = KhatmahRepositoryImpl(
      localDataSource: mockLocalDataSource,
      activityRemoteDataSource: mockActivityRemoteDataSource,
      goalsRemoteDataSource: mockGoalsRemoteDataSource,
    );
  });

  group('KhatmahRepositoryImpl', () {
    final tToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tLog = DailyReadingLogModel(
      date: tToday,
      versesRead: 10,
      readingDuration: const Duration(minutes: 5),
    );

    test('should return today log from local data source', () async {
      // arrange
      when(() => mockLocalDataSource.getLog(any())).thenAnswer((_) async => tLog);
      // act
      final result = await repository.getTodayLog();
      // assert
      expect(result, Right(tLog));
      verify(() => mockLocalDataSource.getLog(tToday));
    });

    test('should log reading locally and report activity to remote', () async {
      // arrange
      when(() => mockLocalDataSource.getLog(any()))
          .thenAnswer((_) async => null);
      when(() => mockLocalDataSource.saveLog(any())).thenAnswer((_) async => {});
      when(() => mockActivityRemoteDataSource.postActivityDay(
        type: any(named: 'type'),
        date: any(named: 'date'),
        mushafId: any(named: 'mushafId'),
      )).thenAnswer((_) async => {});

      // act
      final result = await repository.logReading(verses: 5);

      // assert
      expect(result, const Right(null));
      // Wait for background task
      await Future.delayed(const Duration(milliseconds: 100));
      // _reportActivityDay re-reads the log after posting;
      // since getLog returns null, only the initial save occurs
      verify(() => mockLocalDataSource.saveLog(any())).called(1);
    });

    test('should queue reading session offline if remote report fails', () async {
      // arrange
      final tSession = ReadingSession(
        surahId: 1,
        startVerse: 1,
        endVerse: 7,
        durationSeconds: 300,
        readAt: DateTime.now(),
      );
      when(() => mockGoalsRemoteDataSource.postReadingSession(
        chapterNumber: any(named: 'chapterNumber'),
        verseNumber: any(named: 'verseNumber'),
      )).thenThrow(Exception('Network error'));
      when(() => mockLocalDataSource.saveOfflineSession(any())).thenAnswer((_) async => {});

      // act
      await repository.reportReadingSession(tSession);

      // assert
      verify(() => mockLocalDataSource.saveOfflineSession(any())).called(1);
    });
  });
}
