import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../constants/api_constants.dart';

class BugService {
  final Dio _dio = AuthService.dio;

  Future<bool> reportBug({
    required String titulo,
    required String descripcion,
    required String comoReplicarlo,
    required String plataforma,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/bugs',
        data: {
          'titulo': titulo,
          'descripcion': descripcion,
          'comoReplicarlo': comoReplicarlo,
          'plataforma': plataforma,
          'imageUrls': [],
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
