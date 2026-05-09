import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../services/storage_service.dart';
import '../constants/api_constants.dart';
import '../services/socket_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService = StorageService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final String? token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  static Completer<String?>? _refreshCompleter;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      print('[Auth] Error 401 detectado en ${err.requestOptions.path}');
      
      // Si ya hay un refresco en curso, esperamos a que termine
      if (_refreshCompleter != null) {
        print('[Auth] Esperando a que el refresco actual termine...');
        final newToken = await _refreshCompleter!.future;
        if (newToken != null) {
          return _retry(err.requestOptions, newToken, handler);
        }
        return handler.next(err);
      }

      // Si no hay refresco en curso, lo iniciamos
      _refreshCompleter = Completer<String?>();
      
      try {
        print('[Auth] Iniciando refresco único de token...');
        final String? refresh = await _storageService.getRefreshToken();
        
        if (refresh == null) {
          _refreshCompleter!.complete(null);
          _refreshCompleter = null;
          _handleLogout();
          return handler.next(err);
        }

        final response = await Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )).post(
          ApiConstants.refreshEndpoint,
          data: {'refreshToken': refresh},
        );

        if (response.statusCode == 200) {
          final String newAccess = response.data['accessToken'];
          final String newRefresh = response.data['refreshToken'] ?? refresh;
          await _storageService.saveTokens(newAccess, newRefresh);
          
          print('[Auth] Refresco exitoso. Liberando peticiones en cola.');
          _refreshCompleter!.complete(newAccess);
          final result = await _retry(err.requestOptions, newAccess, handler);
          _refreshCompleter = null;
          return result;
        } else {
          _refreshCompleter!.complete(null);
          _refreshCompleter = null;
          _handleLogout();
        }
      } catch (e) {
        print('[Auth] Error durante el refresco: $e');
        _refreshCompleter!.complete(null);
        _refreshCompleter = null;
        _handleLogout();
      }
    }
    
    return handler.next(err);
  }

  Future<void> _retry(RequestOptions options, String token, ErrorInterceptorHandler handler) async {
    options.headers['Authorization'] = 'Bearer $token';
    options.extra['retried'] = true;
    
    print('[Auth] Reintentando petición con nuevo token: ${options.path}');
    try {
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      )).fetch(options);
      return handler.resolve(response);
    } catch (e) {
      if (e is DioException) return handler.next(e);
      return handler.reject(DioException(requestOptions: options, error: e));
    }
  }

  void _handleLogout() async {
    await _storageService.clearAll();
    SocketService().disconnect();
    getx.Get.offAllNamed('/login');
  }
}
