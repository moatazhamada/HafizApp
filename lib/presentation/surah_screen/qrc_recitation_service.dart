import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get_it/get_it.dart';
import '../../core/app_export.dart';
import '../../core/config/api_config.dart';
import '../../data/datasource/qrc/qrc_remote_datasource.dart';
import '../../data/repository/qrc/qrc_repository_impl.dart';
import '../../domain/repository/qrc/qrc_repository.dart';

class QrcTajweedMistake {
  final String? name;
  final int? wordIndex;
  final String? message;

  const QrcTajweedMistake({this.name, this.wordIndex, this.message});

  factory QrcTajweedMistake.fromJson(Map<String, dynamic> json) {
    return QrcTajweedMistake(
      name: json['speachLike']?.toString() ?? json['name']?.toString(),
      wordIndex: json['word'] as int? ?? json['word_index'] as int?,
      message: json['message']?.toString(),
    );
  }
}

class QrcCheckTilawa {
  final int? verseIndex;
  final int? wordIndex;
  final List<int> skippedWords;
  final List<QrcTajweedMistake> tajweedMistakes;

  const QrcCheckTilawa({
    this.verseIndex,
    this.wordIndex,
    this.skippedWords = const [],
    this.tajweedMistakes = const [],
  });

  factory QrcCheckTilawa.fromJson(Map<String, dynamic> json) {
    final skipped = <int>[];
    if (json['skipped_words'] is List) {
      for (final w in json['skipped_words']) {
        if (w is Map<String, dynamic>) {
          final word = w['word'] as int?;
          if (word != null) skipped.add(word);
        } else if (w is int) {
          skipped.add(w);
        }
      }
    }
    final mistakes = <QrcTajweedMistake>[];
    if (json['tajweed_mistakes'] is List) {
      for (final m in json['tajweed_mistakes']) {
        if (m is Map<String, dynamic>) {
          mistakes.add(QrcTajweedMistake.fromJson(m));
        }
      }
    }
    int? wordIndex = json['word_index'] as int?;
    if (wordIndex == null && json['correct_words'] is List) {
      int maxWord = 0;
      for (final w in json['correct_words']) {
        if (w is Map<String, dynamic>) {
          final word = w['word'] as int? ?? 0;
          if (word > maxWord) maxWord = word;
        }
      }
      if (maxWord > 0) wordIndex = maxWord;
    }
    return QrcCheckTilawa(
      verseIndex: json['verse_index'] as int?,
      wordIndex: wordIndex,
      skippedWords: skipped,
      tajweedMistakes: mistakes,
    );
  }
}

abstract class QrcEvent {}

class QrcStatusEvent extends QrcEvent {
  final String status;
  QrcStatusEvent(this.status);
}

class QrcCheckEvent extends QrcEvent {
  final QrcCheckTilawa data;
  QrcCheckEvent(this.data);
}

class QrcErrorEvent extends QrcEvent {
  final String message;
  QrcErrorEvent(this.message);
}

class QrcRecitationService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final QrcRepository _repository;
  StreamSubscription? _repoSub;
  final StreamController<QrcEvent> _events =
      StreamController<QrcEvent>.broadcast();
  StreamController<Uint8List>? _audioStreamController;
  StreamSubscription<Uint8List>? _audioSub;

  QrcRecitationService({QrcRepository? repository})
    : _repository = repository ?? _defaultRepository();

  static QrcRepository _defaultRepository() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<QrcRepository>()) return sl<QrcRepository>();
    } catch (_) {}
    return QrcRepositoryImpl(remoteDataSource: QrcRemoteDataSourceImpl());
  }

  Stream<QrcEvent> get events => _events.stream;

  Future<bool> connect() async {
    if (ApiConfig.qrcApiKey.isEmpty) {
      _events.add(QrcErrorEvent('msg_qrc_missing_key'.tr));
      return false;
    }

    try {
      _repoSub = _repository.events.listen(
        _handleRepositoryMessage,
        onError: (e) => _events.add(QrcErrorEvent(e.toString())),
      );
      await _repository.connect();
      _repository.subscribeCheckTilawa();
      _events.add(QrcStatusEvent('connected'));
      return true;
    } catch (e) {
      _events.add(QrcErrorEvent('msg_qrc_error'.tr));
      return false;
    }
  }

  Future<void> startTilawaSession({
    required int surahIndex,
    required int verseIndex,
    int wordIndex = 1,
    int hafzLevel = 1,
    int tajweedLevel = 3,
  }) async {
    _repository.startTilawaSession(
      surahIndex: surahIndex,
      verseIndex: verseIndex,
      wordIndex: wordIndex,
      hafzLevel: hafzLevel,
      tajweedLevel: tajweedLevel,
    );
  }

  Future<void> startRecording() async {
    await _recorder.openRecorder();
    _audioStreamController = StreamController<Uint8List>();
    _audioSub = _audioStreamController!.stream.listen((data) {
      if (data.isNotEmpty) {
        _repository.sendAudio(data);
      }
    });

    await _recorder.startRecorder(
      toStream: _audioStreamController!.sink,
      codec: Codec.opusWebM,
      numChannels: 1,
      sampleRate: 16000,
      bitRate: 32000,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    await _audioSub?.cancel();
    await _audioStreamController?.close();
    _audioSub = null;
    _audioStreamController = null;
  }

  void _handleRepositoryMessage(dynamic message) {
    if (message is QrcWsClosedEvent) {
      if (message.wasUnexpected) {
        _events.add(QrcStatusEvent('reconnecting'));
      } else {
        _events.add(QrcStatusEvent('closed'));
      }
      return;
    }

    try {
      if (message is String) {
        final json = jsonDecode(message);
        if (json is Map<String, dynamic>) {
          final event = json['event']?.toString();
          if (event == 'check_tilawa' || event == 'CheckTilawaResponse') {
            _events.add(QrcCheckEvent(QrcCheckTilawa.fromJson(json)));
          } else if (event == 'error') {
            _events.add(
              QrcErrorEvent(json['message']?.toString() ?? 'msg_qrc_error'.tr),
            );
          } else if (event != null) {
            _events.add(QrcStatusEvent(event));
          }
        }
      }
    } catch (e) {
      _events.add(QrcErrorEvent('msg_qrc_invalid_message'.tr));
    }
  }

  Future<void> dispose() async {
    await stopRecording();
    await _recorder.closeRecorder();
    await _repoSub?.cancel();
    await _events.close();
    await _repository.dispose();
  }
}
