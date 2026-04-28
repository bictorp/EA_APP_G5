import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio = Dio();

  Future<User?> login(String email, String password) async {
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
        final String token = data['accessToken'] ?? '';
        final Map<String, dynamic> userData = data['usuario'] ?? {};
        
        return User.fromJson(userData, token);
      } else {
        throw Exception(response.data['message'] ?? 'Error desconocido');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // El servidor respondió con un error (4xx, 5xx)
        throw Exception(e.response?.data['message'] ?? 'Error de autenticación');
      }
      throw Exception('Error de conexión al iniciar sesión');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
