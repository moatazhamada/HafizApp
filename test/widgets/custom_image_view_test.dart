import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/widgets/custom_image_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/test_app_widget.dart';

void main() {
  group('CustomImageView Tests', () {
    testWidgets('renders local PNG file', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          Scaffold(
            // We use a known existing asset from test utils setup, e.g. ImageConstant.imgBismillah
            body: CustomImageView(imagePath: 'assets/images/bismillah.png'),
          ),
        ),
      );

      // We expect an Image widget for pngs
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders SVG file', (WidgetTester tester) async {
      await tester.pumpWidget(
        mountTestWidget(
          Scaffold(
            // The MockAssetBundle will provide a dummy inline SVG for this
            body: CustomImageView(imagePath: 'assets/images/dummy.svg'),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders CachedNetworkImage for network URLs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        mountTestWidget(
          Scaffold(
            body: CustomImageView(imagePath: 'https://example.com/image.png'),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}
