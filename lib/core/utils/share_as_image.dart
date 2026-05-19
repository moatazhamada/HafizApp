import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Utility class for capturing a Flutter widget as a PNG image file.
class ShareAsImage {
  /// Captures the widget associated with [key] and saves it as a PNG file.
  ///
  /// Returns the absolute file path of the generated image.
  /// Throws an exception if the render boundary cannot be found or image
  /// conversion fails.
  static Future<String> captureWidget(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Render boundary not found');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to PNG');
    }

    final bytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'verse_share_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }
}
