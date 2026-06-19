import 'package:dio/dio.dart';
import '../models/unimatch_profile.dart';
import 'auth_service.dart';
import '../constants/api_constants.dart';

class UnimatchService {
  final Dio _dio = AuthService.dio;

  /// Descubrir perfiles para hacer swipe
  Future<List<UnimatchProfile>> discoverProfiles({int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/unimatch/discover',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => UnimatchProfile.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error al descubrir perfiles de UniMatch: $e');
      return [];
    }
  }

  /// Registrar un swipe (like o dislike)
  /// Retorna un mapa indicando si hubo match: {'matched': true/false}
  Future<Map<String, dynamic>> recordSwipe({
    required String toUserId,
    required String type, // 'like' | 'dislike'
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/unimatch/swipe',
        data: {
          'toUserId': toUserId,
          'type': type,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data ?? {'matched': false};
      }
      return {'matched': false};
    } catch (e) {
      print('Error al registrar swipe: $e');
      return {'matched': false};
    }
  }

  /// Aceptar los términos y condiciones de UniMatch
  Future<bool> acceptTerms() async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/unimatch/accept-terms',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al aceptar términos de UniMatch: $e');
      return false;
    }
  }

  /// Obtener los matches actuales del usuario
  Future<List<dynamic>> getMatches() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/unimatch/matches',
      );
      if (response.statusCode == 200) {
        return response.data ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener matches de UniMatch: $e');
      return [];
    }
  }
}
