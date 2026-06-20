import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class UniversidadService {
  final Dio _dio = AuthService.dio;

  Future<List<dynamic>> getAllUniversidades() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/universidades',
        queryParameters: { 'limit': 100, },
      );
      
      if (response.statusCode == 200) {
        return response.data is List ? response.data : (response.data['docs'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> joinChat(String id) async {
    try {
      final response = await _dio.post('${ApiConstants.baseUrl}/universidades/$id/join');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> leaveChat(String id) async {
    try {
      final response = await _dio.post('${ApiConstants.baseUrl}/universidades/$id/leave');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}