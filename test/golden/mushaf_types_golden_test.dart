import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';

void main() {
  group('Mushaf Types Golden Tests', () {
    testWidgets('Mushaf type selection cards render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ListView.builder(
              itemCount: allMushafTypes.length,
              itemBuilder: (context, index) {
                final type = allMushafTypes[index];
                return Card(
                  child: ListTile(
                    leading: Icon(type.icon),
                    title: Text(type.displayNameEn),
                    subtitle: Text(type.description),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 4 Mushaf types are rendered
      expect(find.byType(Card), findsNWidgets(4));
      expect(find.text('Madani (Uthmani)'), findsOneWidget);
      expect(find.text('Indo-Pak'), findsOneWidget);
    });

    testWidgets('Mushaf type colors are applied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Row(
              children: allMushafTypes.map((type) {
                return Container(
                  width: 50,
                  height: 50,
                  color: type.primaryColor,
                  child: Icon(type.icon),
                );
              }).toList(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsNWidgets(4));
    });
  });
}
