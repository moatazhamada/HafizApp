class MushafImageConfig {
  static String? pageImageUrl(String mushafType, int pageNumber) {
    final page = pageNumber.toString().padLeft(3, '0');
    switch (mushafType) {
      case 'madani':
        return 'https://cdn.islamic.network/quran/images/high-resolution/$page.png';
      default:
        return null;
    }
  }
}
