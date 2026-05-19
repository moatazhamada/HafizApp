String stripHtmlTags(String htmlText) {
  final regExp = RegExp(r'<[^>]*>', multiLine: true);
  return htmlText.replaceAll(regExp, '').trim();
}
