import 'dart:async';

class InternetRoomInfo {
  final String code;
  final String roomName;
  final String hostName;
  final bool isPrivate;
  final bool isInGame;
  final int playerCount;
  final int updatedAt;

  const InternetRoomInfo({
    required this.code,
    required this.roomName,
    required this.hostName,
    required this.isPrivate,
    required this.isInGame,
    required this.playerCount,
    required this.updatedAt,
  });
}

abstract class INetworkService {
  /// Flujo de mensajes entrantes en formato JSON
  Stream<String> get messages;

  /// Código de la sala (solo aplica para Firebase)
  String? get roomCode;

  /// Iniciar una sala como Host
  /// [roomCode] se usa como nombre de la sala.
  /// [isPrivate] define si la sala es privada (solo por código) en Internet.
  Future<void> hostGame(String playerName, {String? roomCode, bool isPrivate = false});

  /// Unirse a una sala existente
  /// [connectionData] puede ser un servicio mDNS (nsd.Service) o un String de Firebase (RoomCode).
  Future<void> joinGame(String playerName, dynamic connectionData);

  /// Enviar un evento al resto de los jugadores
  void sendMessage(String eventType, dynamic payload);

  /// Actualizar metadatos y estado de la sala (en espera vs en juego y conteo de jugadores)
  Future<void> updateRoomMetadata({required bool isInGame, required int playerCount});

  /// Desconectarse y limpiar la sesión
  Future<void> disconnect();
}
