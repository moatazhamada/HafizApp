import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/surah_name_formatter.dart';

class _LocaleOverride extends StatelessWidget {
  final Locale locale;
  final Widget child;

  const _LocaleOverride({required this.locale, required this.child});

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }
}

void main() {
  group('SurahNameFormatter', () {
    final surah = Surah(1, 'Al-Fatiha', 'الفاتحة');

    testWidgets('returns Arabic name only for Arabic locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _LocaleOverride(
            locale: const Locale('ar'),
            child: Builder(
              builder: (context) {
                return Text(surah.localizedName(context));
              },
            ),
          ),
        ),
      );
      expect(find.text('الفاتحة'), findsOneWidget);
    });

    testWidgets('returns English - Arabic for English locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _LocaleOverride(
            locale: const Locale('en'),
            child: Builder(
              builder: (context) {
                return Text(surah.localizedName(context));
              },
            ),
          ),
        ),
      );
      expect(find.text('Al-Fatiha - الفاتحة'), findsOneWidget);
    });
  });
}
