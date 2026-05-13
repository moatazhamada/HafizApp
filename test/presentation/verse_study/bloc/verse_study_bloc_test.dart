import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran/quran_word_models.dart';
import 'package:hafiz_app/core/quran/quran_word_service.dart';
import 'package:hafiz_app/data/datasource/qf_post/qf_post_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/verse_study/qf_verse_study_remote_data_source.dart';
import 'package:hafiz_app/presentation/verse_study/bloc/verse_study_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVerseStudyDataSource extends Mock
    implements QfVerseStudyRemoteDataSource {}

class MockPostDataSource extends Mock implements QfPostRemoteDataSource {}

class MockQuranWordService extends Mock implements QuranWordService {}

void main() {
  late MockVerseStudyDataSource mockDataSource;
  late MockPostDataSource mockPostDataSource;
  late MockQuranWordService mockWordService;

  const testVerseKey = '1:1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDataSource = MockVerseStudyDataSource();
    mockPostDataSource = MockPostDataSource();
    mockWordService = MockQuranWordService();
  });

  test('initial state is VerseStudyInitial', () {
    final bloc = VerseStudyBloc(
      dataSource: mockDataSource,
      wordService: mockWordService,
      postDataSource: mockPostDataSource,
    );
    expect(bloc.state, isA<VerseStudyInitial>());
    bloc.close();
  });

  group('LoadVerseStudy', () {
    blocTest<VerseStudyBloc, VerseStudyState>(
      'emits [Loading, Loaded] on success with reflections auto-loaded',
      setUp: () {
        when(
          () => mockDataSource.getVerseStudy(
            testVerseKey,
            tafsirId: any(named: 'tafsirId'),
            translationId: any(named: 'translationId'),
          ),
        ).thenAnswer(
          (_) async => const VerseStudyData(
            arabicText: 'بِسْمِ',
            translation: 'In the name of',
            tafsir: 'Tafsir text',
          ),
        );
        when(
          () => mockWordService.fetchVerseWords(testVerseKey),
        ).thenAnswer((_) async => null);
        when(
          () => mockPostDataSource.getReflections(testVerseKey),
        ).thenAnswer((_) async => []);
      },
      build: () => VerseStudyBloc(
        dataSource: mockDataSource,
        wordService: mockWordService,
        postDataSource: mockPostDataSource,
      ),
      act: (bloc) => bloc.add(const LoadVerseStudy(testVerseKey)),
      expect: () => [
        isA<VerseStudyLoading>(),
        isA<VerseStudyLoaded>()
            .having((s) => s.arabicText, 'arabicText', 'بِسْمِ')
            .having((s) => s.translation, 'translation', 'In the name of')
            .having((s) => s.tafsir, 'tafsir', 'Tafsir text')
            .having((s) => s.words, 'words', isNull),
        // LoadReflections sets reflectionsLoading = true
        isA<VerseStudyLoaded>().having(
          (s) => s.reflectionsLoading,
          'reflectionsLoading',
          true,
        ),
        // Then reflections loaded
        isA<VerseStudyLoaded>()
            .having((s) => s.reflectionsLoading, 'reflectionsLoading', false)
            .having((s) => s.reflections, 'reflections', isEmpty),
      ],
    );

    blocTest<VerseStudyBloc, VerseStudyState>(
      'emits [Loading, Error] on failure',
      setUp: () {
        when(
          () => mockDataSource.getVerseStudy(
            testVerseKey,
            tafsirId: any(named: 'tafsirId'),
            translationId: any(named: 'translationId'),
          ),
        ).thenThrow(Exception('Network error'));
      },
      build: () => VerseStudyBloc(
        dataSource: mockDataSource,
        wordService: mockWordService,
        postDataSource: mockPostDataSource,
      ),
      act: (bloc) => bloc.add(const LoadVerseStudy(testVerseKey)),
      expect: () => [isA<VerseStudyLoading>(), isA<VerseStudyError>()],
    );
  });

  group('LoadVerseStudyWithSources', () {
    blocTest<VerseStudyBloc, VerseStudyState>(
      'emits [Loading, Loaded] with provided source IDs',
      setUp: () {
        when(
          () => mockDataSource.getVerseStudy(
            testVerseKey,
            tafsirId: '91',
            translationId: '101',
          ),
        ).thenAnswer(
          (_) async => const VerseStudyData(
            arabicText: 'بِسْمِ',
            translation: 'Bismillah',
            tafsir: 'Tafsir Saadi',
          ),
        );
        when(
          () => mockWordService.fetchVerseWords(testVerseKey),
        ).thenAnswer(
          (_) async => const VerseWordData(
            verseKey: testVerseKey,
            words: [],
          ),
        );
      },
      build: () => VerseStudyBloc(
        dataSource: mockDataSource,
        wordService: mockWordService,
      ),
      act:
          (bloc) => bloc.add(
            const LoadVerseStudyWithSources(
              testVerseKey,
              tafsirId: '91',
              translationId: '101',
            ),
          ),
      expect: () => [
        isA<VerseStudyLoading>(),
        isA<VerseStudyLoaded>()
            .having((s) => s.selectedTafsirId, 'selectedTafsirId', '91')
            .having(
              (s) => s.selectedTranslationId,
              'selectedTranslationId',
              '101',
            )
            .having((s) => s.words, 'words', isNotNull),
      ],
    );
  });

  group('CreateReflection', () {
    blocTest<VerseStudyBloc, VerseStudyState>(
      'adds reflection to loaded state',
      setUp: () {
        when(
          () => mockPostDataSource.createReflection(
            verseKey: testVerseKey,
            text: 'My reflection',
          ),
        ).thenAnswer(
          (_) async => {
            'id': 'post_1',
            'text': 'My reflection',
            'createdAt': '2024-01-01',
          },
        );
      },
      build: () => VerseStudyBloc(
        dataSource: mockDataSource,
        wordService: mockWordService,
        postDataSource: mockPostDataSource,
      ),
      seed: () => const VerseStudyLoaded(
        arabicText: 'text',
        translation: 'trans',
        tafsir: 'tafsir',
        verseKey: testVerseKey,
        words: null,
      ),
      act: (bloc) => bloc.add(
        const CreateReflection(verseKey: testVerseKey, text: 'My reflection'),
      ),
      expect: () => [
        isA<VerseStudyLoaded>().having(
          (s) => s.reflections,
          'reflections',
          hasLength(1),
        ),
      ],
    );
  });

  group('DeleteReflection', () {
    blocTest<VerseStudyBloc, VerseStudyState>(
      'removes reflection from loaded state',
      setUp: () {
        when(
          () => mockPostDataSource.deletePost('post_1'),
        ).thenAnswer((_) async {});
      },
      build: () => VerseStudyBloc(
        dataSource: mockDataSource,
        wordService: mockWordService,
        postDataSource: mockPostDataSource,
      ),
      seed: () => const VerseStudyLoaded(
        arabicText: 'text',
        translation: 'trans',
        tafsir: 'tafsir',
        verseKey: testVerseKey,
        words: null,
        reflections: [
          {'id': 'post_1', 'text': 'Reflection'},
        ],
      ),
      act: (bloc) => bloc.add(const DeleteReflection('post_1')),
      expect: () => [
        isA<VerseStudyLoaded>().having(
          (s) => s.reflections,
          'reflections',
          isEmpty,
        ),
      ],
    );
  });
}
