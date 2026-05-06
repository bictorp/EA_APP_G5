import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

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
      // Intentar refrescar token
      final String? newToken = await _authService.refreshToken();
      
      if (newToken != null) {
        // Reintentar petición original con nuevo token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';
        
        final response = await Dio().fetch(options);
        return handler.resolve(response);
      } else {
        // Si no se puede refrescar, forzar logout
        await _authService.logout();
        getx.Get.offAllNamed('/login');
      }
    }
    return handler.next(err);
  }
}
