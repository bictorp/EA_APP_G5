import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class AssistantService {
  final Dio _dio = AuthService.dio;

  Future<String> askToni(String pregunta) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/assistant/chat',
        data: {'pregunta': pregunta},
      );
      if (response.statusCode == 200) {
        return response.data['respuesta'] ?? 'No he podido obtener respuesta.';
      }
      return 'Error al obtener respuesta del asistente.';
    } catch (e) {
      return 'Error de conexión con el servidor del asistente.';
    }
  }
}
