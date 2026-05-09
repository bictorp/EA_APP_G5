import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/post.dart';
import '../models/comment.dart';
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

  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/posts/$postId');
      if (response.statusCode == 200) {
        final List commentsData = response.data['comments'] ?? [];
        return commentsData.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Error fetching comments: $e');
      return [];
    }
  }

  Future<Comment?> addComment(String postId, String texto) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/comments',
        data: {
          'post': postId,
          'texto': texto,
        },
      );
      if (response.statusCode == 201) {
        return Comment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error adding comment: $e');
      return null;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      final response = await _dio.delete('${ApiConstants.baseUrl}/comments/$commentId');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) print('Error deleting comment: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _dio.delete('${ApiConstants.baseUrl}/posts/$postId');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Error deleting post: $e');
      return false;
    }
  }

  Future<Post?> createPost(String imageUrl, String caption) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/posts',
        data: {
          'imageUrl': imageUrl,
          'caption': caption,
        },
      );
      if (response.statusCode == 201) {
        return Post.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error creating post: $e');
      return null;
    }
  }

  Future<bool> toggleFollow(String targetId) async {
    try {
      final response = await _dio.post('${ApiConstants.baseUrl}/usuarios/follow/$targetId');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Error toggling follow: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPostsByUserId(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/posts/user/$userId');
      
      if (response.statusCode == 200) {
        final List docs = response.data['docs'] ?? [];
        final List<Post> posts = docs.map((json) => Post.fromJson(json)).toList();
        
        return {
          'posts': posts,
          'hasNextPage': response.data['hasNextPage'] ?? false,
        };
      }
      return {'posts': <Post>[], 'hasNextPage': false};
    } catch (e) {
      if (kDebugMode) print('Error in getPostsByUserId: $e');
      return {'posts': <Post>[], 'hasNextPage': false};
    }
  }
}
