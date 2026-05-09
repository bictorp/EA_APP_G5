import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class UniversidadService {
  final Dio _dio = AuthService.dio;

  Future<List<dynamic>> getAllUniversidades() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/universidades');
      
      if (response.statusCode == 200) {
        return response.data is List ? response.data : (response.data['docs'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}