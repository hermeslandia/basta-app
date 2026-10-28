import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClientService {
  WebSocketChannel? _channel;
  final StreamController<String> _messageController = StreamController.broadcast();

  Stream<String> get messages => _messageController.stream;

  Future<void> connect(String ip, int port) async {
    final wsUrl = Uri.parse('ws://$ip:$port');
    _channel = WebSocketChannel.connect(wsUrl);
    
    // Esperar a que la conexión se establezca, arrojará excepción si el host ya no existe.
    await _channel!.ready;

    _channel!.stream.listen((message) {
      _messageController.add(message);
    }, onDone: () {
      print('Desconectado del servidor.');
    }, onError: (error) {
      print('Error de conexión WebSocket: $error');
    });
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
