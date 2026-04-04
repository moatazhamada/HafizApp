import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/surah_list_item.dart';

import '../utils/test_app_widget.dart';

void main() {
  group('SurahListItem Tests', () {
    testWidgets('renders english and arabic names', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        mountTestWidget(
          const Scaffold(
            body: SurahListItem(
              surahId: 1,
              nameEnglish: 'Al-Fatihah',
              nameArabic: 'الفاتحة',
            ),
          ),
        ),
      );

      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('الفاتحة'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // from localized number converter
    });
  });
}
