import 'package:equatable/equatable.dart';

class MushafPageCoords extends Equatable {
  final int pageNumber;
  final List<VerseBoundingBox> verses;

  const MushafPageCoords({required this.pageNumber, required this.verses});

  factory MushafPageCoords.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('verses') || json['verses'] == null) {
      return MushafPageCoords(
        pageNumber: json['page_number'] ?? 0,
        verses: const [],
      );
    }

    final versesList = json['verses'] as Map<String, dynamic>;
    final List<VerseBoundingBox> parsedVerses = [];

    versesList.forEach((verseKey, verseData) {
      // verseKey is usually formatted as "surahNumber:verseNumber" (e.g. "2:5")
      final parts = verseKey.split(':');
      if (parts.length == 2 && verseData is List) {
        final surahNumber = int.tryParse(parts[0]) ?? 0;
        final verseNumber = int.tryParse(parts[1]) ?? 0;

        // An Ayah might wrap across multiple lines, so it has multiple bounding boxes
        final List<BoundingBoxLine> lines = [];
        for (var lineData in verseData) {
          // Quran.com format: "min_x:min_y:max_x:max_y" OR map {x, y, w, h}
          // We'll support parsing the array/map directly if it's standardized
          if (lineData is Map<String, dynamic>) {
            lines.add(
              BoundingBoxLine(
                minX: (lineData['min_x'] ?? 0).toDouble(),
                minY: (lineData['min_y'] ?? 0).toDouble(),
                maxX: (lineData['max_x'] ?? 0).toDouble(),
                maxY: (lineData['max_y'] ?? 0).toDouble(),
              ),
            );
          }
        }

        if (lines.isNotEmpty) {
          parsedVerses.add(
            VerseBoundingBox(
              surahNumber: surahNumber,
              verseNumber: verseNumber,
              lines: lines,
            ),
          );
        }
      }
    });

    return MushafPageCoords(
      pageNumber: json['page_number'] ?? 0,
      verses: parsedVerses,
    );
  }

  @override
  List<Object?> get props => [pageNumber, verses];
}

class VerseBoundingBox extends Equatable {
  final int surahNumber;
  final int verseNumber;
  final List<BoundingBoxLine> lines;

  const VerseBoundingBox({
    required this.surahNumber,
    required this.verseNumber,
    required this.lines,
  });

  @override
  List<Object?> get props => [surahNumber, verseNumber, lines];
}

class BoundingBoxLine extends Equatable {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const BoundingBoxLine({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  bool containsPoint(double x, double y) {
    return x >= minX && x <= maxX && y >= minY && y <= maxY;
  }

  @override
  List<Object?> get props => [minX, minY, maxX, maxY];
}
