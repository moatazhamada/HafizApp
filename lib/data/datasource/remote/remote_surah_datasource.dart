import 'package:dio/dio.dart';
import 'package:hafiz_app/data/model/surah_model.dart';

/// Remote data source for Surah data
/// Fetches Surah metadata from API endpoints
class RemoteSurahDataSource {
  final Dio dio;

  RemoteSurahDataSource(this.dio);

  /// Fetch all Surahs from remote API
  Future<List<SurahModel>> fetchAllSurahs() async {
    try {
      final response = await dio.get('/chapters');
      final data = response.data['chapters'] as List;

      return data
          .map((e) => SurahModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single Surah by chapter number from remote API
  Future<SurahModel> fetchSurah(int chapterNumber) async {
    try {
      final response = await dio.get('/chapters/$chapterNumber');
      return SurahModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if audio is available for a Surah
  Future<bool> checkAudioAvailability(int chapterNumber) async {
    try {
      final response = await dio.get('/chapters/$chapterNumber/audio');
      return response.data['available'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
