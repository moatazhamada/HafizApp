class MushafRenderingConfig {
  static const String quranApiBase = 'https://api.quran.com/api/v4';

  static String glyphPageUrl(int pageNumber) =>
      '$quranApiBase/verses/by_page/$pageNumber'
      '?fields=code_v1,code_v2,v2_page,page_number'
      '&words=true'
      '&word_fields=code_v1,code_v2,position,v2_page,line_v2,page_number'
      '&per_page=300';
}
