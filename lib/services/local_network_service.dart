import 'dart:async';
import 'dart:convert';
import 'package:nsd/nsd.dart';
import '../core/network_interface.dart';
import 'network_discovery_service.dart';
import 'websocket_server.dart';
import 'websocket_client.dart';

class LocalNetworkService implements INetworkService {
  final NetworkDiscoveryService _discoveryService;
  final WebSocketServerService _serverService = WebSocketServerService();
  final WebSocketClientService _clientService = WebSocketClientService();

  bool _isHost = false;
  Timer? _emptyRoomTimer;

  LocalNetworkService(this._discoveryService);

  @override
  Stream<String> get messages => _clientService.messages;

  @override
  String? get roomCode => null;

  @override
  Future<void> hostGame(String playerName, {String? roomCode, bool isPrivate = false}) async {
    _isHost = true;
    int port = await _serverService.startServer();
    await _discoveryService.registerHostService(port, playerName, roomName: roomCode);
    await _clientService.connect('127.0.0.1', port);
  }

  @override
  Future<void> joinGame(String playerName, dynamic connectionData) async {
    _isHost = false;
    if (connectionData is Service && connectionData.host != null && connectionData.port != null) {
      await _clientService.connect(connectionData.host!, connectionData.port!);
    } else {
      throw Exception('Datos de conexión inválidos para red local.');
    }
  }

  @override
  void sendMessage(String eventType, dynamic payload) {
    final event = json.encode({
      'type': eventType,
      'payload': payload,
    });
    _clientService.sendMessage(event);
  }

  @override
  Future<void> updateRoomMetadata({required bool isInGame, required int playerCount}) async {
    if (!_isHost) return;
    if (playerCount <= 0) {
      _emptyRoomTimer ??= Timer(const Duration(seconds: 15), () {
        disconnect();
      });
    } else {
      _emptyRoomTimer?.cancel();
      _emptyRoomTimer = null;
    }
  }

  @override
  Future<void> disconnect() async {
    _emptyRoomTimer?.cancel();
    _emptyRoomTimer = null;
    _clientService.disconnect();
    if (_isHost) {
      await _serverService.stopServer();
      await _discoveryService.unregisterHostService();
    }
  }
}
