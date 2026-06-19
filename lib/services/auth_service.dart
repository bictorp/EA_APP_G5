import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'auth_interceptor.dart';
import 'socket_service.dart';

class AuthService {
  // Centralizamos la instancia de Dio
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 15),
    ));
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }

  // Getter para que otros servicios usen la misma instancia configurada
  static Dio get dio => _dio;

  final StorageService _storageService = StorageService();

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response?.data is Map) {
        return e.response?.data['message'] ?? 'Error del servidor';
      }
      return 'Error de conexión con el servidor';
    }
    return e.toString();
  }

  Future<User?> login(String email, String password) async {
    print('Intentando login en: ${ApiConstants.loginEndpoint}');
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String accessToken = data['accessToken'] ?? '';
        final String refreshToken = data['refreshToken'] ?? '';
        final Map<String, dynamic> userData = data['usuario'] ?? {};
        
        await _storageService.saveTokens(accessToken, refreshToken);
        await _storageService.saveUserData(jsonEncode(userData));
        
        final user = User.fromJson(userData, accessToken);
        // Conectar al socket tras login exitoso
        await SocketService().connect();
        return user;
      }
      return null;
    } catch (e) {
      throw _parseError(e);
    }
  }

  Future<User?> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerEndpoint,
        data: {
          'nombre': name,
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = response.data;
        final String accessToken = data['accessToken'] ?? '';
        final String refreshToken = data['refreshToken'] ?? '';
        final Map<String, dynamic> userData = data['usuario'] ?? {};
        
        await _storageService.saveTokens(accessToken, refreshToken);
        await _storageService.saveUserData(jsonEncode(userData));
        
        final user = User.fromJson(userData, accessToken);
        await SocketService().connect();
        return user;
      }
      return null;
    } catch (e) {
      throw _parseError(e);
    }
  }

  Future<String?> refreshToken() async {
    final String? refresh = await _storageService.getRefreshToken();
    if (refresh == null || JwtDecoder.isExpired(refresh)) return null;

    try {
      // Usamos una instancia limpia de Dio para el refresh
      final response = await Dio().post(
        ApiConstants.refreshEndpoint,
        data: {'refreshToken': refresh},
      );

      if (response.statusCode == 200) {
        final String newAccess = response.data['accessToken'];
        final String newRefresh = response.data['refreshToken'] ?? refresh;
        await _storageService.saveTokens(newAccess, newRefresh);
        return newAccess;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> checkSession() async {
    String? accessToken = await _storageService.getAccessToken();
    if (accessToken == null) return false;

    if (JwtDecoder.isExpired(accessToken)) {
      accessToken = await refreshToken();
      if (accessToken == null) {
        await logout();
        return false;
      }
    }
    return true;
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    SocketService().disconnect();
  }

  Future<String?> getToken() async {
    return await _storageService.getAccessToken();
  }
}
