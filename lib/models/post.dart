import 'package:flutter/foundation.dart';
import 'user.dart';

class Post {
  final String id;
  final User usuario;
  final String? imageUrl;
  final String? caption;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.usuario,
    this.imageUrl,
    this.caption,
    required this.likes,
    required this.commentsCount,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    try {
      return Post(
        id: json['_id'] ?? '',
        usuario: User.fromJson(json['usuario'] ?? {}, ''),
        imageUrl: json['imageUrl'],
        caption: json['caption'],
        likes: List<String>.from(json['likes'] ?? []),
        commentsCount: (json['comments'] as List?)?.length ?? 0,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Post: $e');
        print('JSON data: $json');
      }
      rethrow;
    }
  }
}
