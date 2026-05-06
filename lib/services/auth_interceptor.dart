import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../services/storage_service.dart';
import '../constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService = StorageService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final String? token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final String? refresh = await _storageService.getRefreshToken();
      
      if (refresh != null) {
        try {
          // Intentar refrescar directamente aquí para evitar circularidad
          final response = await Dio().post(
            ApiConstants.refreshEndpoint,
            data: {'refreshToken': refresh},
          );

          if (response.statusCode == 200) {
            final String newAccess = response.data['accessToken'];
            final String newRefresh = response.data['refreshToken'] ?? refresh;
            await _storageService.saveTokens(newAccess, newRefresh);

            // Reintentar petición original
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccess';
            
            final retryResponse = await Dio().fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          // Si el refresco falla, logout
        }
      }

      // Si llegamos aquí, el refresco falló o no había token
      await _storageService.clearAll();
      getx.Get.offAllNamed('/login');
    }
    return handler.next(err);
  }
}
