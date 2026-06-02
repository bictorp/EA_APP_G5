import 'package:dio/dio.dart';
import '../models/notification.dart';
import 'auth_service.dart';

class NotificationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:1337', // Ajustar según entorno
    connectTimeout: const Duration(seconds: 5),
  ));
  
  final AuthService _authService = AuthService();

  NotificationService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/notifications', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> docs = response.data['docs'] ?? [];
        return {
          'notifications': docs.map((json) => NotificationModel.fromJson(json)).toList(),
          'hasNextPage': response.data['hasNextPage'] ?? false,
        };
      }
      return {'notifications': [], 'hasNextPage': false};
    } catch (e) {
      print('Error fetching notifications: $e');
      return {'notifications': [], 'hasNextPage': false};
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _dio.patch('/notifications/$id/read');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.patch('/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
