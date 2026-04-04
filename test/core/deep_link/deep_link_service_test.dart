import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/deep_link/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    late DeepLinkService service;

    setUp(() {
      service = DeepLinkService();
    });

    group('parseDeepLink', () {
      test('should parse surah-only URL correctly', () {
        final result = service.parseDeepLink(
          Uri.parse('https://hafiz.app/surah/1'),
        );
        expect(result, isNotNull);
        expect(result!.type, DeepLinkType.verse);
        expect(result.surahId, 1);
        expect(result.verseNumber, null);
      });

      test('should parse surah and verse URL correctly', () {
        final result = service.parseDeepLink(
          Uri.parse('https://hafiz.app/surah/2/verse/255'),
        );
        expect(result, isNotNull);
        expect(result!.type, DeepLinkType.verse);
        expect(result.surahId, 2);
        expect(result.verseNumber, 255);
      });

      test('should parse Mushaf page URL', () {
        final result = service.parseDeepLink(
          Uri.parse('https://hafiz.app/page/255'),
        );
        expect(result, isNotNull);
        expect(result!.type, DeepLinkType.mushafPage);
        expect(result.pageNumber, 255);
      });

      test('should parse Juz URL', () {
        final result = service.parseDeepLink(
          Uri.parse('https://hafiz.app/juz/30'),
        );
        expect(result, isNotNull);
        expect(result!.type, DeepLinkType.juz);
        expect(result.juzNumber, 30);
      });

      test('should parse hafiz:// scheme URLs', () {
        final result = service.parseDeepLink(Uri.parse('hafiz://surah/1'));
        expect(result, isNotNull);
        expect(result!.type, DeepLinkType.verse);
        expect(result.surahId, 1);
        expect(result.verseNumber, null);
      });

      test('should parse hafiz:// scheme URLs with verse', () {
        final result = service.parseDeepLink(
          Uri.parse('hafiz://surah/2/verse/3'),
        );
        expect(result, isNotNull);
        expect(result!.type, DeepLinkType.verse);
        expect(result.surahId, 2);
        expect(result.verseNumber, 3);
      });

      test('should return null for invalid surah numbers', () {
        expect(
          service.parseDeepLink(Uri.parse('https://hafiz.app/surah/0')),
          null,
        );
        expect(
          service.parseDeepLink(Uri.parse('https://hafiz.app/surah/115')),
          null,
        );
        expect(
          service.parseDeepLink(Uri.parse('https://hafiz.app/surah/abc')),
          null,
        );
      });

      test('should return null for invalid page numbers', () {
        expect(
          service.parseDeepLink(Uri.parse('https://hafiz.app/page/0')),
          null,
        );
        expect(
          service.parseDeepLink(Uri.parse('https://hafiz.app/page/605')),
          null,
        );
      });

      test('should return null for invalid juz numbers', () {
        expect(
          service.parseDeepLink(Uri.parse('https://hafiz.app/juz/0')),
          null,
        );
        expect(
          service.parseDeepLink(Uri.parse('https://hafiz.app/juz/31')),
          null,
        );
      });

      test('should return null for non-hafiz URLs', () {
        expect(
          service.parseDeepLink(Uri.parse('https://example.com/surah/1')),
          null,
        );
        expect(service.parseDeepLink(Uri.parse('https://google.com')), null);
      });

      test('should return null for empty path', () {
        expect(service.parseDeepLink(Uri.parse('https://hafiz.app/')), null);
      });

      test('should handle all valid surahs', () {
        for (int i = 1; i <= 114; i++) {
          final result = service.parseDeepLink(
            Uri.parse('https://hafiz.app/surah/$i'),
          );
          expect(result, isNotNull, reason: 'Surah $i should be valid');
          expect(result!.surahId, i);
        }
      });

      test('should handle all valid pages', () {
        for (int i = 1; i <= 604; i++) {
          final result = service.parseDeepLink(
            Uri.parse('https://hafiz.app/page/$i'),
          );
          expect(result, isNotNull, reason: 'Page $i should be valid');
          expect(result!.pageNumber, i);
        }
      });

      test('should handle all valid juz numbers', () {
        for (int i = 1; i <= 30; i++) {
          final result = service.parseDeepLink(
            Uri.parse('https://hafiz.app/juz/$i'),
          );
          expect(result, isNotNull, reason: 'Juz $i should be valid');
          expect(result!.juzNumber, i);
        }
      });
    });

    group('generateVerseLink', () {
      test('should generate correct surah-only URL', () {
        final url = service.generateVerseLink(1);
        expect(url, 'https://hafiz.app/surah/1');
      });

      test('should generate correct surah+verse URL', () {
        final url = service.generateVerseLink(2, verseNumber: 255);
        expect(url, 'https://hafiz.app/surah/2/verse/255');
      });

      test('should handle all surah numbers', () {
        for (int i = 1; i <= 114; i++) {
          final url = service.generateVerseLink(i);
          expect(url, 'https://hafiz.app/surah/$i');
        }
      });
    });

    group('generatePageLink', () {
      test('should generate correct page URL', () {
        final url = service.generatePageLink(255);
        expect(url, 'https://hafiz.app/page/255');
      });

      test('should handle all page numbers', () {
        for (int i = 1; i <= 604; i++) {
          final url = service.generatePageLink(i);
          expect(url, 'https://hafiz.app/page/$i');
        }
      });
    });

    group('singleton behavior', () {
      test('should return same instance', () {
        final instance1 = DeepLinkService();
        final instance2 = DeepLinkService();
        expect(identical(instance1, instance2), true);
      });
    });

    group('VerseImageStyle', () {
      test('should have all required styles', () {
        expect(VerseImageStyle.values.length, 4);
        expect(VerseImageStyle.values, contains(VerseImageStyle.classic));
        expect(VerseImageStyle.values, contains(VerseImageStyle.modern));
        expect(VerseImageStyle.values, contains(VerseImageStyle.minimal));
        expect(VerseImageStyle.values, contains(VerseImageStyle.gradient));
      });
    });

    group('DeepLinkType', () {
      test('should have all required types', () {
        expect(DeepLinkType.values.length, 3);
        expect(DeepLinkType.values, contains(DeepLinkType.verse));
        expect(DeepLinkType.values, contains(DeepLinkType.mushafPage));
        expect(DeepLinkType.values, contains(DeepLinkType.juz));
      });
    });

    group('DeepLinkData', () {
      test('should create data with verse info', () {
        final data = DeepLinkData(
          type: DeepLinkType.verse,
          surahId: 1,
          verseNumber: 1,
        );
        expect(data.type, DeepLinkType.verse);
        expect(data.surahId, 1);
        expect(data.verseNumber, 1);
        expect(data.pageNumber, null);
        expect(data.juzNumber, null);
      });

      test('should create data with page info', () {
        final data = DeepLinkData(
          type: DeepLinkType.mushafPage,
          pageNumber: 255,
        );
        expect(data.type, DeepLinkType.mushafPage);
        expect(data.pageNumber, 255);
        expect(data.surahId, null);
      });

      test('should create data with juz info', () {
        final data = DeepLinkData(type: DeepLinkType.juz, juzNumber: 30);
        expect(data.type, DeepLinkType.juz);
        expect(data.juzNumber, 30);
      });
    });
  });
}
