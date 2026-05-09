import 'package:flutter/foundation.dart';
import 'user.dart';

class Post {
  final String id;
  final User usuario;
  final String? imageUrl;
  final String? caption;
  final List<User> likes;
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

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} s';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 365) {
      return 'Hace ${difference.inDays} d';
    } else {
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      if (months > 0) {
        return 'Hace ${years}a ${months}m';
      }
      return 'Hace ${years}a';
    }
  }

  static String formatCount(int count) {
    if (count >= 1000000) {
      double millions = count / 1000000;
      return '${millions.toStringAsFixed(millions < 10 ? 1 : 0)}M';
    } else if (count >= 1000) {
      double thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}k';
    }
    return count.toString();
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    try {
      return Post(
        id: json['_id'] ?? '',
        usuario: User.fromJson(json['usuario'] ?? {}, ''),
        imageUrl: json['imageUrl'],
        caption: json['caption'],
        likes: (json['likes'] as List?)
          ?.map((like) => User.fromJson(Map<String, dynamic>.from(like), '', )).toList() ?? [],
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
