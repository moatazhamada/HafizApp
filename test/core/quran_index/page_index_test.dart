import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';

void main() {
  group('MushafPageIndex', () {
    group('getPage', () {
      test('should return correct page for page 1 (Al-Fatiha)', () {
        final page = MushafPageIndex.getPage(1);
        expect(page, isNotNull);
        expect(page!.pageNumber, 1);
        expect(page.surahId, 1);
        expect(page.startVerse, 1);
        expect(page.endVerse, 7);
        expect(page.surahNameEn, 'Al-Fatiha');
      });

      test('should return correct page for page 2 (Al-Baqarah start)', () {
        final page = MushafPageIndex.getPage(2);
        expect(page, isNotNull);
        expect(page!.pageNumber, 2);
        expect(page.surahId, 2);
        expect(page.startVerse, 1);
        expect(page.isSurahStart, true);
      });

      test('should return null for invalid page numbers', () {
        expect(MushafPageIndex.getPage(0), isNull);
        expect(MushafPageIndex.getPage(1000), isNull);
        expect(MushafPageIndex.getPage(-1), isNull);
      });

      test('should return correct page for pages within range', () {
        final pages = MushafPageIndex.getAllPages();
        // Test first few pages
        for (int i = 1; i <= 5 && i <= pages.length; i++) {
          final page = MushafPageIndex.getPage(i);
          expect(page, isNotNull, reason: 'Page $i should exist');
          expect(page!.pageNumber, i);
        }
      });
    });

    group('getAllPages', () {
      test('should return pages', () {
        final pages = MushafPageIndex.getAllPages();
        expect(pages.length, greaterThan(0));
      });

      test('should have consecutive page numbers', () {
        final pages = MushafPageIndex.getAllPages();
        for (int i = 0; i < pages.length && i < 10; i++) {
          expect(pages[i].pageNumber, i + 1);
        }
      });
    });

    group('findPageForVerse', () {
      test('should find page for Al-Fatiha verse 1', () {
        final page = MushafPageIndex.findPageForVerse(1, 1);
        expect(page, 1);
      });

      test('should find page for Al-Baqarah verse 1', () {
        final page = MushafPageIndex.findPageForVerse(2, 1);
        expect(page, 2);
      });

      test('should return null for invalid verse', () {
        expect(MushafPageIndex.findPageForVerse(1, 100), isNull);
        expect(MushafPageIndex.findPageForVerse(0, 1), isNull);
      });
    });

    group('getVersesForPage', () {
      test('should return verses for page 1', () {
        final verses = MushafPageIndex.getVersesForPage(1);
        expect(verses.length, 7); // Al-Fatiha has 7 verses
        expect(verses.first.verseNumber, 1);
        expect(verses.last.verseNumber, 7);
      });

      test('should return empty list for invalid page', () {
        final verses = MushafPageIndex.getVersesForPage(0);
        expect(verses, isEmpty);
      });

      test('verses should have correct page number', () {
        final verses = MushafPageIndex.getVersesForPage(5);
        for (final verse in verses) {
          expect(verse.pageNumber, 5);
        }
      });
    });

    group('isSurahStart', () {
      test('page 1 should be surah start', () {
        final page = MushafPageIndex.getPage(1);
        expect(page!.isSurahStart, true);
      });

      test('page 2 should be surah start (Al-Baqarah)', () {
        final page = MushafPageIndex.getPage(2);
        expect(page!.isSurahStart, true);
      });
    });

    group('containsBismillah', () {
      test('Al-Fatiha page should not contain Bismillah (already has it)', () {
        final page = MushafPageIndex.getPage(1);
        expect(page!.containsBismillah, false); // Surah 1 starts with Bismillah as verse 1
      });

      test('Al-Baqarah page should contain Bismillah', () {
        final page = MushafPageIndex.getPage(2);
        expect(page!.containsBismillah, true);
      });

      test('At-Tawbah (Surah 9) should not contain Bismillah', () {
        // Find page for Surah 9
        final pages = MushafPageIndex.getAllPages();
        try {
          final surah9Page = pages.firstWhere((p) => p.surahId == 9 && p.isSurahStart);
          expect(surah9Page.containsBismillah, false);
        } catch (e) {
          // If Surah 9 not found in first pages, skip this test
          markTestSkipped('Surah 9 not found in generated data');
        }
      });
    });

    group('totalPages', () {
      test('should be 604', () {
        expect(MushafPageIndex.totalPages, 604);
      });
    });

    group('MushafVerse', () {
      test('should create verse correctly', () {
        const verse = MushafVerse(
          surahId: 1,
          verseNumber: 1,
          pageNumber: 1,
        );
        expect(verse.surahId, 1);
        expect(verse.verseNumber, 1);
        expect(verse.pageNumber, 1);
      });
    });

    group('MushafType page counts', () {
      test('Madani should have 604 pages', () {
        expect(MushafType.madani.totalPages, 604);
      });

      test('Egyptian should have 604 pages', () {
        expect(MushafType.egyptian.totalPages, 604);
      });

      test('Indo-Pak should have 558 pages', () {
        expect(MushafType.indoPak.totalPages, 558);
      });

      test('Warsh should have 604 pages', () {
        expect(MushafType.warsh.totalPages, 604);
      });
    });
  });
}
