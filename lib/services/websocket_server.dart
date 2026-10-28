import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketServerService {
  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];
  final StreamController<String> _messageController = StreamController.broadcast();

  Stream<String> get messages => _messageController.stream;

  Future<int> startServer() async {
    var handler = webSocketHandler((webSocket) {
      if (_clients.length >= 19) {
        webSocket.sink.close(1008, 'Sala llena (Máx 20 jugadores)');
        return;
      }
      _clients.add(webSocket);
      print('Cliente conectado. Total: ${_clients.length}');

      webSocket.stream.listen((message) {
        _messageController.add(message);
        broadcastMessage(message); 
      }, onDone: () {
        _clients.remove(webSocket);
        print('Cliente desconectado.');
      });
    });

    // InternetAddress.anyIPv4 expone el servidor a la red local
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    print('Servidor WebSocket corriendo en ws://${_server!.address.host}:${_server!.port}');
    return _server!.port;
  }

  void broadcastMessage(String message) {
    for (var client in _clients) {
      client.sink.add(message);
    }
  }

  Future<void> stopServer() async {
    for (var client in _clients) {
      client.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }
}
