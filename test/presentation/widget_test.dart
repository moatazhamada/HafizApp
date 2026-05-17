import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

void main() {
  testWidgets('MaterialApp renders Text widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Hafiz'))),
    );
    expect(find.text('Hafiz'), findsOneWidget);
  });

  test('Surah model creates from constructor', () {
    final surah = Surah(1, 'Al-Fatiha', 'الفاتحة');
    expect(surah.id, 1);
    expect(surah.nameEnglish, 'Al-Fatiha');
    expect(surah.nameArabic, 'الفاتحة');
  });
}
