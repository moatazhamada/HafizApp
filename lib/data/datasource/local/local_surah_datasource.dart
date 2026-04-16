import 'package:hafiz_app/domain/entities/surah.dart';
import 'package:hafiz_app/data/model/surah_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local data source for Surah data
/// Stores Surah metadata and download status in Hive
class LocalSurahDataSource {
  final Box<SurahModel> surahBox;

  LocalSurahDataSource(this.surahBox);

  /// Get all Surahs from local storage
  Future<List<Surah>> getAllSurahs() async {
    final models = surahBox.values.toList();
    return models.map((m) => m.toEntity()).toList();
  }

  /// Get a single Surah by chapter number
  Future<Surah?> getSurah(int chapterNumber) async {
    final model = surahBox.get('surah_$chapterNumber');
    return model?.toEntity();
  }

  /// Save a Surah to local storage
  Future<void> saveSurah(Surah surah) async {
    final model = SurahModel.fromEntity(surah);
    await surahBox.put('surah_${surah.chapterNumber}', model);
  }

  /// Check if a Surah is downloaded
  Future<bool> isDownloaded(int chapterNumber) async {
    final model = surahBox.get('surah_$chapterNumber');
    return model?.isDownloaded ?? false;
  }

  /// Update download status for a Surah
  Future<void> updateDownloadStatus(
    int chapterNumber,
    bool isDownloaded,
    DateTime? lastDownloadedAt,
  ) async {
    final model = surahBox.get('surah_$chapterNumber');
    if (model != null) {
      final updatedModel = model.copyWith(
        isDownloaded: isDownloaded,
        lastDownloadedAt: lastDownloadedAt,
      );
      await surahBox.put('surah_$chapterNumber', updatedModel);
    }
  }

  /// Delete a Surah from local storage
  Future<void> deleteSurah(int chapterNumber) async {
    await surahBox.delete('surah_$chapterNumber');
  }
}
