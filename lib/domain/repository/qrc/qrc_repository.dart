import 'dart:async';
import 'dart:typed_data';

abstract class QrcRepository {
  Stream<dynamic> get events;
  Future<void> connect();
  void subscribeCheckTilawa();
  void startTilawaSession({
    required int surahIndex,
    required int verseIndex,
    int wordIndex = 1,
    int hafzLevel = 1,
    int tajweedLevel = 3,
  });
  void sendAudio(Uint8List data);
  Future<void> dispose();
}
