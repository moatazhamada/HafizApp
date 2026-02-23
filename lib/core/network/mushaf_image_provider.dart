import '../../data/models/mushaf_page_coords.dart';
import '../../core/utils/logger.dart';
import '../quran_index/mushaf_types.dart';

class MushafImageProvider {
  // Quran.com CDN paths
  // v4 images are high quality, often used on standard Quran apps
  static const String baseImageUrl = 'https://android.quran.com/data/';

  /// Get the full URL for a specific Mushaf page image
  static String getImageUrl(MushafType type, int pageNumber) {
    // Madani (Hafs) is the standard 15-line Mushaf
    String typePath = 'images_1280'; // Default base

    // Different Mushaf types have different image endpoints on the CDN
    switch (type) {
      case MushafType.madani:
        typePath = 'images_1280';
        break;
      case MushafType.indoPak:
        typePath = 'naskh_1280';
        break;
      case MushafType.egyptian:
        typePath = 'shamerly'; // Egyptian/Shamerly
        break;
      case MushafType.warsh:
        typePath = 'warsh'; // Warsh/Madani
        break;
    }

    // Format pad page number (e.g. page001.png, page042.png, page604.png)
    final paddedPage = pageNumber.toString().padLeft(3, '0');
    return '$baseImageUrl$typePath/page$paddedPage.png';
  }

  /// Fetch and parse the tap coordinates (Ayah bounding boxes) for a page
  static Future<MushafPageCoords?> getPageCoordinates(
    MushafType type,
    int pageNumber,
  ) async {
    // Note: To implement exactly against quran.com API, we use the specific word-by-word coords endpoint
    // If the endpoint is unavailable or returns 404 for certain Mushaf types, we return null
    // and the page gracefully falls back to a non-interactive image

    try {
      // Example endpoint for Madani bounding boxes (Quran.com API v4)
      // https://api.quran.com/api/v4/verses/by_page/X?words=true&word_fields=text_uthmani,location

      // Since fetching thousands of JSON points via HTTP per page swipe is slow,
      // apps typically bundle the JSON sqlite db locally.
      // For this dynamic implementation, we try a mock implementation
      // representing what the API parse looks like

      // In a production scenario, we hit our own CDN or raw Github repo hosting the mapped json files
      // Because open-source coord repos are large: https://github.com/quran/quran.com-images

      return null; // Return null until absolute endpoint confirmed, gracefully ignoring taps
    } catch (e) {
      Logger.error(
        'Failed to load page $pageNumber coordinates',
        feature: 'MushafImage',
        error: e,
      );
      return null;
    }
  }
}
