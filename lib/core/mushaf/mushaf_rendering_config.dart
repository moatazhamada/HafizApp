class MushafRenderingConfig {
  static const String _everyAyahBase =
      'https://everyayah.com/data/images_png';

  static String ayahImageUrl(int surahId, int ayahNumber) =>
      '$_everyAyahBase/${surahId}_$ayahNumber.png';
}
