import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/network/network_manager.dart';
import 'package:hafiz_app/data/datasource/surah/surah_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixture/fixture_reader.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late SurahRemoteDataSourceImpl surahRemoteDataSource;
  late NetworkManagerImpl networkManagerImpl;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    mockDio.options = BaseOptions(
      baseUrl: 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1',
    );
    when(() => mockDio.interceptors).thenReturn(Interceptors());
    networkManagerImpl = NetworkManagerImpl(mockDio);
    surahRemoteDataSource = SurahRemoteDataSourceImpl(
      networkManager: networkManagerImpl,
    );
  });

  group('Make sure data source ', () {
    void setUpMockDioSuccess() {
      final responsePayload = json.decode(fixture('surah_response.json'));
      final response = Response(
        data: responsePayload,
        statusCode: 200,
        requestOptions: RequestOptions(baseUrl: ''),
      );
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);
    }

    void setUpMockDioFailed() {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Unknown Error',
          type: DioExceptionType.unknown,
        ),
      );
    }

    test('make sure get surah return success', () async {
      setUpMockDioSuccess();
      var result = await surahRemoteDataSource.getSurah('114');
      expect(result.chapters.length, 6);
      expect(result.chapters.first.verseNumber, 1);
      verify(
        () => mockDio.get(
          '/verses/by_chapter/114',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      );
    });

    test('make sure get surah return failure', () async {
      setUpMockDioFailed();
      expect(
        () => surahRemoteDataSource.getSurah('114'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
