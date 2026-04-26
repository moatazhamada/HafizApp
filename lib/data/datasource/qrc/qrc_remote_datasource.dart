import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';

class QrcWsClosedEvent {
  final bool wasUnexpected;

  const QrcWsClosedEvent({this.wasUnexpected = false});
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

  bool _intentionalDisconnect = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectBaseDelay = Duration(seconds: 2);
  Timer? _reconnectTimer;

  @override
  Stream<dynamic> get events => _eventController!.stream;

  @override
  Future<void> connect() async {
    if (_channel != null || _isConnecting) return;

    _intentionalDisconnect = false;
    _isConnecting = true;

    try {
      final uri = Uri.parse(ApiConfig.qrcWsBase);

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          _reconnectAttempts = 0; // Reset on successful message
          _eventController?.add(message);
        },
        onError: (e) {
          Logger.error('QRC WebSocket error: $e', feature: 'QRC');
          _eventController?.addError(e);
          _handleDisconnect(wasUnexpected: true);
        },
        onDone: () {
          _handleDisconnect(
            wasUnexpected: !_intentionalDisconnect,
          );
        },
      );

      send({'method': 'Authenticate', 'api_key': ApiConfig.qrcApiKey});
    } catch (e) {
      Logger.error('QRC WebSocket connect failed: $e', feature: 'QRC');
      _handleDisconnect(wasUnexpected: true);
    } finally {
      _isConnecting = false;
    }
  }

  void _handleDisconnect({required bool wasUnexpected}) {
    _channel = null;

    if (wasUnexpected && !_intentionalDisconnect) {
      _eventController?.add(const QrcWsClosedEvent(wasUnexpected: true));
      _attemptReconnect();
    } else {
      _eventController?.add(const QrcWsClosedEvent(wasUnexpected: false));
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Logger.warning(
        'QRC max reconnect attempts reached ($_maxReconnectAttempts)',
        feature: 'QRC',
      );
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectBaseDelay * _reconnectAttempts;
    Logger.info(
      'QRC reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
      feature: 'QRC',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (!_intentionalDisconnect) {
        await connect();
      }
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
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await _channel?.sink.close();
    _channel = null;
    await _eventController?.close();
    _eventController = null;
  }
}
