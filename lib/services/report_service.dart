import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../constants/api_constants.dart';

class ReportService {
  final Dio _dio = AuthService.dio;

  Future<bool> reportContent({
    required String tipo, // 'post' | 'comment' | 'user'
    required String objetivoId,
    required String descripcion,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/reports',
        data: {
          'tipo': tipo,
          'objetivoId': objetivoId,
          'descripcion': descripcion,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
