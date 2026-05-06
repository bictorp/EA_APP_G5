import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/post.dart';
import 'auth_service.dart';

class PostService {
  // Usamos la misma instancia de Dio que AuthService
  final Dio _dio = AuthService.dio;

  Future<Map<String, dynamic>> getFollowingFeed({int page = 1, int limit = 10}) async {
    try {
      if (kDebugMode) {
        print('Fetching feed from: ${ApiConstants.baseUrl}/posts/following');
      }
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/posts/following',
        queryParameters: {'page': page, 'limit': limit},
      );
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response data length: ${response.data['docs']?.length}');
      }

      if (response.statusCode == 200) {
        final List docs = response.data['docs'] ?? [];
        final List<Post> posts = docs.map((json) => Post.fromJson(json)).toList();
        
        return {
          'posts': posts,
          'hasNextPage': response.data['hasNextPage'] ?? false,
          'nextPage': response.data['nextPage'],
        };
      }
      return {'posts': <Post>[], 'hasNextPage': false};
    } catch (e) {
      if (kDebugMode) {
        print('Error in getFollowingFeed: $e');
        if (e is DioException) {
          print('Dio error: ${e.response?.data}');
        }
      }
      return {'posts': <Post>[], 'hasNextPage': false};
    }
  }

  Future<Post?> toggleLike(String postId) async {
    try {
      final response = await _dio.patch('${ApiConstants.baseUrl}/posts/$postId/like');
      if (response.statusCode == 200) {
        return Post.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling like: $e');
      }
      return null;
    }
  }
}
