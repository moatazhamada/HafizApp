import 'dart:async';
import 'dart:typed_data';
import '../datasource/qrc/qrc_remote_datasource.dart';

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

class QrcRepositoryImpl implements QrcRepository {
  final QrcRemoteDataSource remoteDataSource;

  QrcRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<dynamic> get events => remoteDataSource.events;

  @override
  Future<void> connect() => remoteDataSource.connect();

  @override
  void subscribeCheckTilawa() {
    remoteDataSource.send({'method': 'SubscribeCheckTilawa'});
  }

  @override
  void startTilawaSession({
    required int surahIndex,
    required int verseIndex,
    int wordIndex = 1,
    int hafzLevel = 1,
    int tajweedLevel = 3,
  }) {
    remoteDataSource.send({
      'method': 'StartTilawaSession',
      'chapter_index': surahIndex,
      'verse_index': verseIndex,
      'word_index': wordIndex,
      'hafz_level': hafzLevel,
      'tajweed_level': tajweedLevel,
    });
  }

  @override
  void sendAudio(Uint8List data) => remoteDataSource.sendAudio(data);

  @override
  Future<void> dispose() => remoteDataSource.disconnect();
}
