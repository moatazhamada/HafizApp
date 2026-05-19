import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/i18n/locale_controller.dart';
import 'package:hafiz_app/data/datasource/translation/qf_translation_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });
  late QfTranslationRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(BaseOptions());
    when(() => mockDio.interceptors).thenReturn(Interceptors());
    dataSource = QfTranslationRemoteDataSource(dio: mockDio);
  });

  group('getTranslationsByChapter', () {
    final tResponse = Response(
      data: {
        'translations': [
          {'text': 'In the name of Allah'},
          {'text': '<b>Alhamdu</b> lillahi Rabbil Alamin'},
        ],
        'pagination': {'total_pages': 1},
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: ''),
    );

    test('should return empty map for Arabic locale', () async {
      LocaleController.notifier.value = const Locale('ar', '');

      final result = await dataSource.getTranslationsByChapter(1);

      expect(result, isEmpty);
      verifyNever(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')));
    });

    test('should return translations for non-Arabic locale', () async {
      LocaleController.notifier.value = const Locale('en', '');

      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => tResponse);

      final result = await dataSource.getTranslationsByChapter(1);

      expect(result.length, 2);
      expect(result[1], 'In the name of Allah');
      expect(result[2], 'Alhamdu lillahi Rabbil Alamin');
      verify(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('should return empty map on failure', () async {
      LocaleController.notifier.value = const Locale('en', '');

      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final result = await dataSource.getTranslationsByChapter(1);

      expect(result, isEmpty);
    });

    test('should use cache on second call', () async {
      LocaleController.notifier.value = const Locale('en', '');

      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => tResponse);

      await dataSource.getTranslationsByChapter(1);
      final result = await dataSource.getTranslationsByChapter(1);

      expect(result.length, 2);
      verify(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).called(1);
    });
  });
}
