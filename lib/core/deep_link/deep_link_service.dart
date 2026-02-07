import 'dart:async';
import 'dart:typed_data';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../app_export.dart';

/// Deep Link Service handles:
/// - Incoming deep links (hafiz.app/surah/2/verse/255)
/// - Sharing verses as links
/// - Generating verse images for social sharing
/// - Copying verses with attribution
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();
  
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  /// Base URL for deep links
  static const String baseUrl = 'hafiz.app';
  static const String scheme = 'https';
  
  /// Initialize deep link handling
  Future<void> initialize({
    required Function(DeepLinkData) onDeepLink,
  }) async {
    // Handle initial link
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri, onDeepLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
    
    // Listen for incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleLink(uri, onDeepLink);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }
  
  void _handleLink(Uri uri, Function(DeepLinkData) onDeepLink) {
    final data = parseDeepLink(uri);
    if (data != null) {
      onDeepLink(data);
    }
  }
  
  /// Parse a deep link URI
  DeepLinkData? parseDeepLink(Uri uri) {
    // Support both https://hafiz.app/... and hafiz://... schemes
    if (uri.host != baseUrl && uri.scheme != 'hafiz') {
      return null;
    }
    
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return null;
    
    // Parse /surah/{id}/verse/{number}
    if (pathSegments[0] == 'surah' && pathSegments.length >= 2) {
      final surahId = int.tryParse(pathSegments[1]);
      if (surahId == null || surahId < 1 || surahId > 114) return null;
      
      int? verseNumber;
      if (pathSegments.length >= 4 && pathSegments[2] == 'verse') {
        verseNumber = int.tryParse(pathSegments[3]);
      }
      
      return DeepLinkData(
        type: DeepLinkType.verse,
        surahId: surahId,
        verseNumber: verseNumber,
      );
    }
    
    // Parse /page/{number} for Mushaf pages
    if (pathSegments[0] == 'page' && pathSegments.length >= 2) {
      final pageNumber = int.tryParse(pathSegments[1]);
      if (pageNumber != null && pageNumber >= 1 && pageNumber <= 604) {
        return DeepLinkData(
          type: DeepLinkType.mushafPage,
          pageNumber: pageNumber,
        );
      }
    }
    
    // Parse /juz/{number}
    if (pathSegments[0] == 'juz' && pathSegments.length >= 2) {
      final juzNumber = int.tryParse(pathSegments[1]);
      if (juzNumber != null && juzNumber >= 1 && juzNumber <= 30) {
        return DeepLinkData(
          type: DeepLinkType.juz,
          juzNumber: juzNumber,
        );
      }
    }
    
    return null;
  }
  
  /// Generate a shareable link for a verse
  String generateVerseLink(int surahId, {int? verseNumber}) {
    if (verseNumber != null) {
      return '$scheme://$baseUrl/surah/$surahId/verse/$verseNumber';
    }
    return '$scheme://$baseUrl/surah/$surahId';
  }
  
  /// Generate a shareable link for a Mushaf page
  String generatePageLink(int pageNumber) {
    return '$scheme://$baseUrl/page/$pageNumber';
  }
  
  /// Share a verse as a link
  Future<void> shareVerseLink({
    required int surahId,
    int? verseNumber,
    String? verseText,
    String? surahName,
  }) async {
    final link = generateVerseLink(surahId, verseNumber: verseNumber);
    
    String shareText;
    if (verseText != null && surahName != null) {
      shareText = '$verseText\n\n— $surahName${verseNumber != null ? ' ($verseNumber)' : ''}\n\n$link';
    } else {
      shareText = link;
    }
    
    await Share.share(
      shareText,
      subject: 'Quran Verse from Hafiz App',
    );
  }
  
  /// Copy verse with attribution to clipboard
  Future<void> copyVerseWithAttribution({
    required int surahId,
    required int verseNumber,
    required String verseText,
    required String surahName,
  }) async {
    final link = generateVerseLink(surahId, verseNumber: verseNumber);
    final text = '''
$verseText

— $surahName ($verseNumber)

via Hafiz App
$link
'''.trim();
    
    await Clipboard.setData(ClipboardData(text: text));
  }
  
  /// Generate a beautiful image for a verse (for social sharing)
  Future<File?> generateVerseImage({
    required String verseText,
    required String surahName,
    required int verseNumber,
    required BuildContext context,
    String? translation,
    VerseImageStyle style = VerseImageStyle.classic,
  }) async {
    final screenshotController = ScreenshotController();
    
    // Create the widget to capture
    final verseWidget = _buildVerseImageWidget(
      verseText: verseText,
      surahName: surahName,
      verseNumber: verseNumber,
      style: style,
      translation: translation,
    );
    
    try {
      // Capture the widget as an image
      final bytes = await screenshotController.captureFromWidget(
        verseWidget,
        context: context,
        delay: const Duration(milliseconds: 100),
      );
      
      if (bytes == null) return null;
      
      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'verse_${surahName}_${verseNumber}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Error generating verse image: $e');
      return null;
    }
  }
  
  /// Share a verse as an image
  Future<void> shareVerseImage({
    required String verseText,
    required String surahName,
    required int verseNumber,
    required BuildContext context,
    String? translation,
    VerseImageStyle style = VerseImageStyle.classic,
  }) async {
    final file = await generateVerseImage(
      verseText: verseText,
      surahName: surahName,
      verseNumber: verseNumber,
      context: context,
      translation: translation,
      style: style,
    );
    
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$surahName ($verseNumber) - via Hafiz App',
      );
    }
  }
  
  /// Build the verse image widget
  Widget _buildVerseImageWidget({
    required String verseText,
    required String surahName,
    required int verseNumber,
    required VerseImageStyle style,
    String? translation,
  }) {
    switch (style) {
      case VerseImageStyle.classic:
        return _buildClassicStyle(
          verseText: verseText,
          surahName: surahName,
          verseNumber: verseNumber,
          translation: translation,
        );
      case VerseImageStyle.modern:
        return _buildModernStyle(
          verseText: verseText,
          surahName: surahName,
          verseNumber: verseNumber,
          translation: translation,
        );
      case VerseImageStyle.minimal:
        return _buildMinimalStyle(
          verseText: verseText,
          surahName: surahName,
          verseNumber: verseNumber,
          translation: translation,
        );
      case VerseImageStyle.gradient:
        return _buildGradientStyle(
          verseText: verseText,
          surahName: surahName,
          verseNumber: verseNumber,
          translation: translation,
        );
    }
  }
  
  Widget _buildClassicStyle({
    required String verseText,
    required String surahName,
    required int verseNumber,
    String? translation,
  }) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.all(60),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0E6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header ornament
          Container(
            width: 80,
            height: 4,
            color: const Color(0xFF006754),
          ),
          const SizedBox(height: 40),
          
          // Bismillah
          const Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 36,
              color: Color(0xFF006754),
            ),
          ),
          const SizedBox(height: 40),
          
          // Verse text
          Text(
            verseText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 56,
              height: 1.8,
              color: Color(0xFF1A1A1A),
            ),
          ),
          
          if (translation != null) ...[
            const SizedBox(height: 30),
            Container(
              width: 60,
              height: 2,
              color: const Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 30),
            Text(
              translation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                height: 1.6,
                color: Color(0xFF666666),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          
          // Surah and verse info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF006754), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$surahName • $verseNumber',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006754),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Footer ornament
          Container(
            width: 80,
            height: 4,
            color: const Color(0xFF006754),
          ),
          
          const SizedBox(height: 20),
          
          // App branding
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                color: Color(0xFF999999),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Hafiz App',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernStyle({
    required String verseText,
    required String surahName,
    required int verseNumber,
    String? translation,
  }) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.all(60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006754), Color(0xFF004B40)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          
          // Verse text
          Text(
            verseText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 56,
              height: 1.8,
              color: Colors.white,
            ),
          ),
          
          if (translation != null) ...[
            const SizedBox(height: 30),
            Text(
              translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          
          // Surah and verse info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$surahName • Verse $verseNumber',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // App branding
          Text(
            'via Hafiz App',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMinimalStyle({
    required String verseText,
    required String surahName,
    required int verseNumber,
    String? translation,
  }) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.all(60),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Verse text
          Text(
            verseText,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 52,
              height: 1.8,
              color: Color(0xFF1A1A1A),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Divider
          Container(
            width: 60,
            height: 3,
            color: const Color(0xFF006754),
          ),
          
          const SizedBox(height: 20),
          
          // Surah info
          Text(
            '$surahName, $verseNumber',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              color: Color(0xFF666666),
            ),
          ),
          
          if (translation != null) ...[
            const SizedBox(height: 30),
            Text(
              translation,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                height: 1.6,
                color: Color(0xFF444444),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          
          // App branding
          const Text(
            'Hafiz App',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGradientStyle({
    required String verseText,
    required String surahName,
    required int verseNumber,
    String? translation,
  }) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.all(60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          
          // Decorative stars
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
              SizedBox(width: 8),
              Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 8),
              Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Verse text
          Text(
            verseText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 56,
              height: 1.8,
              color: Colors.white,
            ),
          ),
          
          if (translation != null) ...[
            const SizedBox(height: 30),
            Text(
              translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          
          // Surah info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$surahName • $verseNumber',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // App branding
          Text(
            '✦ Hafiz App ✦',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  void dispose() {
    _linkSubscription?.cancel();
  }
}

/// Types of deep links
enum DeepLinkType {
  verse,
  mushafPage,
  juz,
}

/// Data parsed from a deep link
class DeepLinkData {
  final DeepLinkType type;
  final int? surahId;
  final int? verseNumber;
  final int? pageNumber;
  final int? juzNumber;
  
  DeepLinkData({
    required this.type,
    this.surahId,
    this.verseNumber,
    this.pageNumber,
    this.juzNumber,
  });
}

/// Styles for verse images
enum VerseImageStyle {
  classic,
  modern,
  minimal,
  gradient,
}
