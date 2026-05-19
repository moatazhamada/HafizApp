import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';

class VerseMediaItem {
  final String url;
  final String? type;
  final String? author;
  final String? description;

  const VerseMediaItem({
    required this.url,
    this.type,
    this.author,
    this.description,
  });

  factory VerseMediaItem.fromJson(Map<String, dynamic> json) {
    return VerseMediaItem(
      url: json['url'] as String? ?? '',
      type: json['type'] as String?,
      author: json['authorName'] as String? ?? json['author'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Remote data source for Quran.Foundation Verse Media API.
/// Fetches images and media associated with specific verses.
abstract class VerseMediaRemoteDataSource {
  Future<List<VerseMediaItem>> getVerseMedia(String verseKey);
}

class VerseMediaRemoteDataSourceImpl implements VerseMediaRemoteDataSource {
  final Dio _dio;

  VerseMediaRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<VerseMediaItem>> getVerseMedia(String verseKey) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.contentBase}/verses/media',
        queryParameters: {'verse_key': verseKey},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final mediaList = (data['media'] ?? data['images'] ?? data['data']) as List?;
        if (mediaList != null) {
          return mediaList
              .whereType<Map<String, dynamic>>()
              .map((m) => VerseMediaItem.fromJson(m))
              .where((item) => item.url.isNotEmpty)
              .toList();
        }
      }
      return [];
    } catch (e) {
      Logger.warning('Failed to fetch verse media for $verseKey: $e',
          feature: 'VerseMedia');
      return [];
    }
  }
}
