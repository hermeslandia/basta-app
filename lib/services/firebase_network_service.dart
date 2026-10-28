import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../core/network_interface.dart';

class FirebaseNetworkService implements INetworkService {
  final StreamController<String> _messageController = StreamController.broadcast();
  final StreamController<List<InternetRoomInfo>> _roomsController =
      StreamController<List<InternetRoomInfo>>.broadcast();

  DatabaseReference? _roomRef;
  String? _roomCode;
  bool _isHost = false;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _roomsListSubscription;
  Timer? _emptyRoomTimer;

  @override
  Stream<String> get messages => _messageController.stream;

  Stream<List<InternetRoomInfo>> get availableInternetRooms => _roomsController.stream;

  @override
  String? get roomCode => _roomCode;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  @override
  Future<void> hostGame(String playerName, {String? roomCode, bool isPrivate = false}) async {
    _isHost = true;
    _roomCode = _generateRoomCode();
    _roomRef = FirebaseDatabase.instance.ref('rooms/$_roomCode');

    final String displayRoomName =
        (roomCode != null && roomCode.trim().isNotEmpty) ? roomCode.trim() : 'Sala de $playerName';

    await _roomRef!.set({
      'code': _roomCode,
      'roomName': displayRoomName,
      'host': playerName,
      'isPrivate': isPrivate,
      'status': 'waiting',
      'isInGame': false,
      'playerCount': 1,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    }).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception(
        'Tiempo de espera agotado. Asegúrate de tener conexión a Internet y Firebase Realtime Database activo.',
      );
    });

    // Si el host pierde la conexión abruptamente, Firebase destruye la sala automáticamente
    try {
      await _roomRef!.onDisconnect().remove();
    } catch (_) {}

    _listenToMessages();
  }

  /// Escucha en tiempo real las salas públicas disponibles en Firebase y limpia salas abandonadas (>20s sin pulso)
  void startRoomDiscovery() {
    _roomsListSubscription?.cancel();
    final roomsRootRef = FirebaseDatabase.instance.ref('rooms');

    _roomsListSubscription = roomsRootRef.onValue.listen((event) {
      final List<InternetRoomInfo> publicRooms = [];
      final int nowMs = DateTime.now().millisecondsSinceEpoch;

      if (event.snapshot.exists && event.snapshot.value is Map) {
        final rawMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        rawMap.forEach((key, value) {
          if (value is Map) {
            final roomData = Map<String, dynamic>.from(value);
            final String code = (roomData['code'] ?? key).toString().toUpperCase();
            final String roomName = (roomData['roomName'] ?? 'Sala $code').toString();
            final String hostName = (roomData['host'] ?? 'Anfitrión').toString();
            final bool isPrivate = roomData['isPrivate'] == true;
            final String status = (roomData['status'] ?? 'waiting').toString();
            final bool isInGame = roomData['isInGame'] == true || status == 'in_game';
            final int playerCount = (roomData['playerCount'] as num?)?.toInt() ?? 1;
            final int updatedAt = (roomData['updatedAt'] as num?)?.toInt() ?? nowMs;

            // Si la sala está vacía o lleva más de 25 segundos sin reportar latido del Host, destruirla
            final bool isStale = (nowMs - updatedAt).abs() > 25000 && updatedAt < nowMs;
            if (playerCount <= 0 || isStale) {
              roomsRootRef.child(key.toString()).remove();
              return;
            }

            // Mostrar en la lista únicamente las salas PÚBLICAS que están EN ESPERA (waiting)
            if (!isPrivate && !isInGame && playerCount >= 1) {
              publicRooms.add(
                InternetRoomInfo(
                  code: code,
                  roomName: roomName,
                  hostName: hostName,
                  isPrivate: isPrivate,
                  isInGame: isInGame,
                  playerCount: playerCount,
                  updatedAt: updatedAt,
                ),
              );
            }
          }
        });
      }

      publicRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _roomsController.add(publicRooms);
    });
  }

  void stopRoomDiscovery() {
    _roomsListSubscription?.cancel();
    _roomsListSubscription = null;
  }

  @override
  Future<void> joinGame(String playerName, dynamic connectionData) async {
    _isHost = false;
    _roomCode = (connectionData as String).trim().toUpperCase();
    _roomRef = FirebaseDatabase.instance.ref('rooms/$_roomCode');

    final snapshot = await _roomRef!.get().timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Tiempo de espera agotado al buscar la sala.');
    });

    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Sala no encontrada. Verifica el código.');
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final String status = (data['status'] ?? 'waiting').toString();
    final bool isInGame = data['isInGame'] == true || status == 'in_game';
    final int playerCount = (data['playerCount'] as num?)?.toInt() ?? 1;

    if (playerCount <= 0) {
      await _roomRef!.remove();
      throw Exception('La sala está vacía y ha sido destruida.');
    }

    if (isInGame) {
      throw Exception('Esta sala ya se encuentra en juego.');
    }

    stopRoomDiscovery();
    _listenToMessages();
  }

  void _listenToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _roomRef!.child('messages').onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final message = event.snapshot.value as String;
        _messageController.add(message);
      }
    });
  }

  @override
  void sendMessage(String eventType, dynamic payload) {
    if (_roomRef != null) {
      final message = json.encode({
        'type': eventType,
        'payload': payload,
      });
      _roomRef!.child('messages').push().set(message);
    }
  }

  @override
  Future<void> updateRoomMetadata({required bool isInGame, required int playerCount}) async {
    if (!_isHost || _roomRef == null) return;
    try {
      await _roomRef!.update({
        'status': isInGame ? 'in_game' : 'waiting',
        'isInGame': isInGame,
        'playerCount': playerCount,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (_) {}

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
    stopRoomDiscovery();
    await _messagesSubscription?.cancel();
    _messagesSubscription = null;
    if (_isHost && _roomRef != null) {
      try {
        await _roomRef!.remove();
      } catch (_) {}
    }
    _roomRef = null;
    _roomCode = null;
  }
}
