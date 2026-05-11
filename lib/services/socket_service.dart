import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StorageService _storageService = StorageService();
  final Map<String, List<Function(dynamic)>> _listeners = {};

  IO.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return;

    if (_socket != null && _socket!.connected) return;

    print('[Socket] Conectando a ${ApiConstants.socketUrl}');

    _socket = IO.io(ApiConstants.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      print('[Socket] Conectado');
      // Re-vincular los eventos que ya teníamos registrados
      _listeners.forEach((event, callbacks) {
        _socket!.off(event); // Evitar duplicados previos
        _socket!.on(event, (data) {
          for (var cb in List.from(callbacks)) {
            cb(data);
          }
        });
      });
    });

    _socket!.onDisconnect((_) => print('[Socket] Desconectado'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
      _socket?.on(event, (data) {
        for (var cb in List.from(_listeners[event]!)) {
          cb(data);
        }
      });
    }
    
    // Evitar añadir exactamente la misma función si ya existe
    if (!_listeners[event]!.contains(callback)) {
      _listeners[event]!.add(callback);
    }
  }

  void off(String event) {
    _listeners.remove(event);
    _socket?.off(event);
  }
}
