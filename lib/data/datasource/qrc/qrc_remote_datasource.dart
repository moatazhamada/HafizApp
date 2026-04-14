import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';

class QrcWsClosedEvent {
  const QrcWsClosedEvent();
}

abstract class QrcRemoteDataSource {
  Stream<dynamic> get events;
  Future<void> connect();
  void send(Map<String, dynamic> data);
  void sendAudio(Uint8List data);
  Future<void> disconnect();
}

class QrcRemoteDataSourceImpl implements QrcRemoteDataSource {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _eventController =
      StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> get events => _eventController!.stream;

  @override
  Future<void> connect() async {
    if (_channel != null) return;

    final uri = Uri.parse(ApiConfig.qrcWsBase);

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (message) => _eventController?.add(message),
      onError: (e) => _eventController?.addError(e),
      onDone: () {
        _eventController?.add(const QrcWsClosedEvent());
        _channel = null;
      },
    );

    send({'method': 'Authenticate', 'api_key': ApiConfig.qrcApiKey});
  }

  @override
  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  @override
  void sendAudio(Uint8List data) {
    _channel?.sink.add(data);
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    await _eventController?.close();
    _eventController = null;
  }
}
