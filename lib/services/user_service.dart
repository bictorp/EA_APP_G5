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
      final response = await _dio.get('${ApiConstants.baseUrl}/usuarios/$userId/seguidores');
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
      final response = await _dio.get('${ApiConstants.baseUrl}/usuarios/$userId/seguidos');
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
      final response = await _dio.patch('${ApiConstants.baseUrl}/usuarios/$userId/follow');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
