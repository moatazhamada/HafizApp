import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';

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
  group('NumberConverter', () {
    testWidgets('converts digits to Arabic-Indic for Arabic locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _LocaleOverride(
            locale: const Locale('ar'),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text(0.toLocalizedNumber(context)),
                      Text(1.toLocalizedNumber(context)),
                      Text(42.toLocalizedNumber(context)),
                      Text(123.toLocalizedNumber(context)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('٠'), findsOneWidget);
      expect(find.text('١'), findsOneWidget);
      expect(find.text('٤٢'), findsOneWidget);
      expect(find.text('١٢٣'), findsOneWidget);
    });

    testWidgets('leaves digits unchanged for English locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _LocaleOverride(
            locale: const Locale('en'),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text(0.toLocalizedNumber(context)),
                      Text(42.toLocalizedNumber(context)),
                      Text(12345.toLocalizedNumber(context)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('12345'), findsOneWidget);
    });
  });
}
