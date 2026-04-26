/// Mushaf page rendering configuration.
///
/// Three rendering modes:
/// - **text**: Render verse text from local JSON assets (default, always available)
/// - **ayah_images**: Load individual ayah images from EveryAyah CDN
/// - **glyph**: Use QF code_v2 glyph codes for font-based page rendering
class MushafRenderingConfig {
  /// Rendering mode identifiers stored in preferences.
  static const String textMode = 'text';
  static const String ayahImagesMode = 'ayah_images';
  static const String glyphMode = 'glyph';

  /// All available rendering modes in display order.
  static const List<String> modes = [textMode, ayahImagesMode, glyphMode];

  /// Human-readable label key for each mode.
  static String labelKey(String mode) => switch (mode) {
        ayahImagesMode => 'lbl_render_ayah_images',
        glyphMode => 'lbl_render_glyph',
        _ => 'lbl_render_text',
      };

  /// Description key for each mode.
  static String descriptionKey(String mode) => switch (mode) {
        ayahImagesMode => 'msg_render_ayah_images_desc',
        glyphMode => 'msg_render_glyph_desc',
        _ => 'msg_render_text_desc',
      };

  // ─── Ayah-level image URLs (EveryAyah CDN) ──────────────────────────

  static const String _everyAyahBase =
      'https://everyayah.com/data/images_png';

  /// Returns the EveryAyah CDN URL for a specific ayah image.
  /// Pattern: `https://everyayah.com/data/images_png/{surah}_{ayah}.png`
  static String ayahImageUrl(int surahId, int ayahNumber) =>
      '$_everyAyahBase/${surahId}_$ayahNumber.png';

  // ─── QF Glyph API ───────────────────────────────────────────────────

  /// Quran.com v4 API base for fetching glyph data.
  static const String quranApiBase = 'https://api.quran.com/api/v4';

  /// Endpoint for fetching verses with word-level glyph data for a page.
  /// Returns code_v1, code_v2, line_v2, v2_page, page_number per word.
  static String glyphPageUrl(int pageNumber) =>
      '$quranApiBase/verses/by_page/$pageNumber'
      '?fields=code_v1,code_v2,v2_page,page_number'
      '&words=true'
      '&word_fields=code_v1,code_v2,position,v2_page,line_v2,page_number'
      '&per_page=300';
}
