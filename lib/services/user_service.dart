import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class UserService {
  final Dio _dio = AuthService.dio;

  Future<Map<String, dynamic>?> getUserById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/usuarios/$id');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getFollowers(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/usuarios/followers/$userId');
      if (response.statusCode == 200) {
        final List data = response.data['seguidores'] ?? [];
        return data.map((f) => (f is String) ? f : f['_id'].toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getFollowing(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/usuarios/following/$userId');
      if (response.statusCode == 200) {
        final List data = response.data['seguidos'] ?? [];
        return data.map((f) => (f is String) ? f : f['_id'].toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> toggleFollow(String userId) async {
    try {
      final response = await _dio.post('${ApiConstants.baseUrl}/usuarios/follow/$userId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> acceptFollowRequest(String followerId) async {
    try {
      final response = await _dio.post('${ApiConstants.baseUrl}/usuarios/requests/accept/$followerId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectFollowRequest(String followerId) async {
    try {
      final response = await _dio.post('${ApiConstants.baseUrl}/usuarios/requests/reject/$followerId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateUser(dynamic data) async {
    try {
      final response = await _dio.patch('${ApiConstants.baseUrl}/auth/me', data: data);
      if (response.statusCode == 200) {
        // If the response wraps the user in a 'usuario' key, extract it
        if (response.data is Map && response.data.containsKey('usuario')) {
          return response.data['usuario'];
        }
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateAsignaturas(String usuarioId, List<String> asignaturas) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.baseUrl}/usuarios/$usuarioId/asignaturas',
        data: {'asignaturas': asignaturas},
      );
      if (response.statusCode == 200) {
        if (response.data is Map && response.data.containsKey('usuario')) {
          return response.data['usuario'];
        }
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/auth/me');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  
  Future<Map<String, dynamic>?> searchUsers({
      String query = '',
      List<String> allIds = const [],
      List<dynamic> allUnis = const [],
      List<dynamic> allGrados = const [],
      List<dynamic> allAsignaturas = const [],
      int page = 1,
    }) async {
    try {
      final unis = allIds.where((id) => allUnis.any((u) => (u['_id'] ?? u['id']) == id)).toList();
      final grads = allIds.where((id) => allGrados.any((g) => (g['_id'] ?? g['id']) == id)).toList();
      final asigs = allIds.where((id) => allAsignaturas.any((a) => (a['_id'] ?? a['id']) == id)).toList();

      final queryParams = {
        'search': query.isNotEmpty ? query : null,
        'universidades': unis.isNotEmpty ? unis.join(',') : null,
        'grados': grads.isNotEmpty ? grads.join(',') : null,
        'asignaturas': asigs.isNotEmpty ? asigs.join(',') : null,
        'page': page,
        'limit': 10,

        }..removeWhere((key, value) => value == null);
        
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/usuarios', 
        queryParameters: queryParams,
      );

      return response.statusCode == 200 ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getFollowersList(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/usuarios/followers/$userId');
      if (response.statusCode == 200) {
        return response.data['seguidores'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getFollowingList(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/usuarios/following/$userId');
      if (response.statusCode == 200) {
        return response.data['seguidos'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> softDeleteUser(String usuarioId) async {
    try {
      final response = await _dio.patch('${ApiConstants.baseUrl}/usuarios/$usuarioId/soft-delete');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

