import 'dart:async';
import 'package:nsd/nsd.dart';

class NetworkDiscoveryService {
  final String serviceType = '_basta._tcp';
  Registration? _registration;
  Discovery? _discovery;
  
  final StreamController<List<Service>> _servicesController = StreamController.broadcast();
  Stream<List<Service>> get discoveredServices => _servicesController.stream;

  // Emite el servicio (Para el Host)
  Future<void> registerHostService(int port, String hostName, {String? roomName}) async {
    try {
      final serviceName = (roomName != null && roomName.isNotEmpty) ? roomName : 'BastaHost_$hostName';
      final service = Service(
        name: serviceName,
        type: serviceType,
        port: port,
      );
      _registration = await register(service);
      print('Servicio mDNS registrado en el puerto $port con nombre $serviceName');
    } catch (e) {
      print('Error al registrar mDNS: $e');
    }
  }

  // Escanea la red en busca del servicio (Para los Clientes)
  Future<void> startServiceDiscovery() async {
    try {
      if (_discovery != null) {
        await stopDiscovery(_discovery!);
      }
      _discovery = await startDiscovery(serviceType);
      _discovery!.addListener(() {
        _servicesController.add(_discovery!.services);
      });
    } catch (e) {
      print('Error al buscar servicios: $e');
    }
  }

  Future<void> stopServiceDiscovery() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
  }

  Future<void> unregisterHostService() async {
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
  }
}
