import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';
import '../core/network_interface.dart';
import '../services/local_network_service.dart';
import '../services/firebase_network_service.dart';
import '../services/network_discovery_service.dart';

enum NetworkMode { local, internet }

class NetworkProvider extends ChangeNotifier {
  NetworkMode _currentMode = NetworkMode.local;
  NetworkMode get currentMode => _currentMode;
  late INetworkService _activeService;

  final NetworkDiscoveryService _discoveryService = NetworkDiscoveryService();
  StreamSubscription<List<InternetRoomInfo>>? _internetRoomsSub;

  bool _isHost = false;
  bool get isHost => _isHost;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  List<Service> _availableHosts = [];
  List<Service> get availableHosts => _availableHosts;

  List<InternetRoomInfo> _availableInternetRooms = [];
  List<InternetRoomInfo> get availableInternetRooms => _availableInternetRooms;

  INetworkService get activeService => _activeService;

  NetworkProvider() {
    _setMode(NetworkMode.local);
    _discoveryService.discoveredServices.listen((services) {
      _availableHosts = services;
      notifyListeners();
    });
  }

  void setMode(NetworkMode mode) {
    if (_isConnected) return;
    _setMode(mode);
  }

  void _setMode(NetworkMode mode) {
    _internetRoomsSub?.cancel();
    _internetRoomsSub = null;
    _availableInternetRooms = [];

    _currentMode = mode;
    if (mode == NetworkMode.local) {
      _activeService = LocalNetworkService(_discoveryService);
    } else {
      final firebaseService = FirebaseNetworkService();
      _activeService = firebaseService;
      _internetRoomsSub = firebaseService.availableInternetRooms.listen((rooms) {
        _availableInternetRooms = rooms;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<String?> hostGame(String playerName, {String? roomCode, bool isPrivate = false}) async {
    _isHost = true;
    try {
      await _activeService.hostGame(playerName, roomCode: roomCode, isPrivate: isPrivate);
      _isConnected = true;
      notifyListeners();
      return _activeService.roomCode ?? roomCode;
    } catch (e) {
      debugPrint('Error al hostear la partida: $e');
      return null;
    }
  }

  Future<void> scanForLocalHosts() async {
    if (_currentMode == NetworkMode.local) {
      await _discoveryService.startServiceDiscovery();
      notifyListeners();
    } else if (_activeService is FirebaseNetworkService) {
      (_activeService as FirebaseNetworkService).startRoomDiscovery();
      notifyListeners();
    }
  }

  void stopRoomDiscovery() {
    if (_activeService is FirebaseNetworkService) {
      (_activeService as FirebaseNetworkService).stopRoomDiscovery();
    }
  }

  Future<bool> joinGame(String playerName, dynamic connectionData) async {
    _isHost = false;
    try {
      await _activeService.joinGame(playerName, connectionData);
      _isConnected = true;
      if (_currentMode == NetworkMode.local) {
        await _discoveryService.stopServiceDiscovery();
      } else if (_activeService is FirebaseNetworkService) {
        (_activeService as FirebaseNetworkService).stopRoomDiscovery();
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al unirse a la partida: $e');
      return false;
    }
  }

  void disconnect() {
    _activeService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _internetRoomsSub?.cancel();
    disconnect();
    super.dispose();
  }
}
