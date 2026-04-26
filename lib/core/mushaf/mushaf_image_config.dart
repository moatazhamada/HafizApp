class MushafImageConfig {
  /// Returns a mushaf page image URL for the given type and page number.
  ///
  /// Returns `null` to use text rendering. When a reliable CDN for page-level
  /// mushaf images is available, add the URL pattern here. The mushaf screen's
  /// `CachedNetworkImage` will automatically use image mode when a non-null URL
  /// is returned, with a fallback to text rendering on error.
  ///
  /// Page numbers are 1-indexed (1–604).
  ///
  /// Known CDNs (all currently 403 or broken as of 2026-04):
  ///   - https://cdn.islamic.network/quran/images/high-resolution/{page}.png
  ///   - https://c22506.r6.cf1.rackcdn.com/{surah}_{ayah}.png (verse-level)
  ///
  /// Quran Foundation API v4 provides `code_v1`/`code_v2` glyph codes for
  /// font-based page rendering — that's the recommended future approach for
  /// pixel-perfect mushaf pages instead of CDN images.
  static String? pageImageUrl(String mushafType, int pageNumber) {
    // Text-only mode until a working page-level image CDN is available.
    return null;
  }
}
