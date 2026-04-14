import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';

abstract class QrcRemoteDataSource {
  Stream<dynamic> get events;
  Future<void> connect();
  void send(Map<String, dynamic> data);
  void sendAudio(Uint8List data);
  Future<void> disconnect();
}

class QrcRemoteDataSourceImpl implements QrcRemoteDataSource {
  WebSocketChannel? _channel;
  final StreamController<dynamic> _eventController = StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> get events => _eventController.stream;

  @override
  Future<void> connect() async {
    if (_channel != null) return;

    final uri = Uri.parse(ApiConfig.qrcWsBase);

    // We send the API key as the first message after connection to avoid
    // sub-protocol character constraints and keep the URL clean.
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (message) => _eventController.add(message),
      onError: (e) => _eventController.addError(e),
      onDone: () {
        _eventController.add('closed');
        _channel = null;
      },
    );

    // Authenticate immediately after connection
    send({
      'method': 'Authenticate',
      'api_key': ApiConfig.qrcApiKey,
    });
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
  }
}
