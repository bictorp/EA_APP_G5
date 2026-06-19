import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class GradoService {
  final Dio _dio = AuthService.dio;

  Future<List<dynamic>> getAllGrados() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/grados',
        queryParameters: { 'limit': 100, },
      );
      
      if (response.statusCode == 200) {
        return response.data is List ? response.data : (response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAllAsignaturas() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/asignaturas',
        queryParameters: { 'limit': 100, },
      );
      
      if (response.statusCode == 200) {
        return response.data is List ? response.data : (response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getGradosByUniversidad(String uniId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/grados/universidad/$uniId');
      if (response.statusCode == 200) {
        return response.data is List ? response.data : (response.data['data'] ?? response.data ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAsignaturasByGrado(String gradoId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/grados/$gradoId/asignaturas');
      if (response.statusCode == 200) {
        return response.data is List ? response.data : (response.data['data'] ?? response.data ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}