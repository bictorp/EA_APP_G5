import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StorageService _storageService = StorageService();

  IO.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await _storageService.getAccessToken();
    if (token == null) {
      print('[Socket] No hay token, no se puede conectar');
      return;
    }

    if (_socket != null && _socket!.connected) {
      print('[Socket] Ya está conectado');
      return;
    }

    print('[Socket] Intentando conectar a ${ApiConstants.socketUrl}');

    _socket = IO.io(ApiConstants.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      print('[Socket] Conectado exitosamente');
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Desconectado del servidor');
    });

    _socket!.onConnectError((err) {
      print('[Socket] Error de conexión: $err');
    });

    _socket!.onError((err) {
      print('[Socket] Error general: $err');
    });
  }

  void disconnect() {
    print('[Socket] Desconectando...');
    _socket?.disconnect();
    _socket = null;
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      print('[Socket] No se puede emitir "$event", socket no conectado');
    }
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }
}
