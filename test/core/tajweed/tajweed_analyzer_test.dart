import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/tajweed/tajweed_analyzer.dart';
import 'package:hafiz_app/core/tajweed/tajweed_models.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';

void main() {
  group('TajweedAnalyzer', () {
    group('analyze', () {
      test('returns empty progress when no sessions or errors', () {
        final progress = TajweedAnalyzer.analyze(sessions: [], errors: []);
        expect(progress.overallAccuracy, 0.0);
        expect(progress.totalSessions, 0);
        expect(progress.totalMistakes, 0);
        expect(progress.weakAreas, isEmpty);
      });

      test('computes overall accuracy from sessions', () {
        final sessions = [
          RecitationSession(
            id: '1_1',
            surahId: 1,
            surahName: 'Al-Fatiha',
            totalVerses: 7,
            correctCount: 6,
            totalCount: 7,
            score: 85.7,
            createdAt: DateTime(2024, 1, 1),
          ),
          RecitationSession(
            id: '2_1',
            surahId: 2,
            surahName: 'Al-Baqara',
            totalVerses: 10,
            correctCount: 9,
            totalCount: 10,
            score: 90.0,
            createdAt: DateTime(2024, 1, 2),
          ),
        ];

        final progress = TajweedAnalyzer.analyze(
          sessions: sessions,
          errors: [],
        );

        // (85.7 + 90) / 2 / 100 = 0.8785
        expect(progress.overallAccuracy, closeTo(0.8785, 0.01));
        expect(progress.totalSessions, 2);
        expect(progress.lastSessionDate, DateTime(2024, 1, 2));
      });

      test('identifies weak areas from tajweed mistake log', () {
        final sessions = [
          RecitationSession(
            id: '1_1',
            surahId: 1,
            surahName: 'Al-Fatiha',
            totalVerses: 7,
            correctCount: 5,
            totalCount: 7,
            score: 71.4,
            createdAt: DateTime(2024, 1, 1),
          ),
        ];

        final errors = [
          RecitationErrorModel(
            surahId: 1,
            surahName: 'Al-Fatiha',
            verseId: 3,
            count: 2,
            createdAt: DateTime(2024, 1, 1),
          ),
        ];

        final progress = TajweedAnalyzer.analyze(
          sessions: sessions,
          errors: errors,
          tajweedMistakeLog: {
            '1_1': ['ikhfa', 'idgham', 'ikhfa'],
          },
        );

        expect(progress.weakAreas, isNotEmpty);
        // ikhfa should be the worst (2 occurrences)
        expect(progress.weakAreas.first.ruleName, 'ikhfa');
        expect(progress.weakAreas.first.errorCount, 2);
      });

      test('falls back to generic weakness when no tajweed log', () {
        final sessions = [
          RecitationSession(
            id: '1_1',
            surahId: 1,
            surahName: 'Al-Fatiha',
            totalVerses: 7,
            correctCount: 5,
            totalCount: 7,
            score: 71.4,
            createdAt: DateTime(2024, 1, 1),
          ),
        ];

        final errors = [
          RecitationErrorModel(
            surahId: 1,
            surahName: 'Al-Fatiha',
            verseId: 3,
            count: 1,
            createdAt: DateTime(2024, 1, 1),
          ),
        ];

        final progress = TajweedAnalyzer.analyze(
          sessions: sessions,
          errors: errors,
        );

        expect(progress.weakAreas, hasLength(1));
        expect(progress.weakAreas.first.ruleName, 'general');
      });
    });

    group('generatePracticePlan', () {
      test('generates items from weak areas with examples', () {
        final progress = TajweedProgress(
          overallAccuracy: 0.75,
          totalSessions: 5,
          totalMistakes: 3,
          weakAreas: const [
            TajweedWeakness(
              ruleName: 'ikhfa',
              errorCount: 3,
              accuracy: 0.4,
              exampleVerseKeys: ['1:3', '2:255', '36:1'],
            ),
            TajweedWeakness(
              ruleName: 'idgham',
              errorCount: 1,
              accuracy: 0.8,
              exampleVerseKeys: ['1:5'],
            ),
          ],
          lastSessionDate: DateTime(2024, 1, 1),
        );

        final plan = TajweedAnalyzer.generatePracticePlan(progress);

        expect(plan, hasLength(4)); // 3 from ikhfa + 1 from idgham
        expect(plan.first.ruleName, 'ikhfa');
        expect(plan.first.verseKey, '1:3');
      });

      test('returns empty plan when no weak areas', () {
        const progress = TajweedProgress();
        final plan = TajweedAnalyzer.generatePracticePlan(progress);
        expect(plan, isEmpty);
      });
    });
  });
}
