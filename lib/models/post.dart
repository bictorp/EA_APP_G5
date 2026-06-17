import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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
      return 'ago_seconds_short'.trParams({'val': difference.inSeconds.toString()});
    } else if (difference.inMinutes < 60) {
      return 'ago_minutes_short'.trParams({'val': difference.inMinutes.toString()});
    } else if (difference.inHours < 24) {
      return 'ago_hours_short'.trParams({'val': difference.inHours.toString()});
    } else if (difference.inDays < 365) {
      return 'ago_days_short'.trParams({'val': difference.inDays.toString()});
    } else {
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      if (months > 0) {
        return 'ago_years_months_short'.trParams({
          'years': years.toString(),
          'months': months.toString(),
        });
      }
      return 'ago_years_short'.trParams({'val': years.toString()});
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
        likes: (json['likes'] as List?)?.map((item) {
          if (item is Map) {
            return User.fromJson(Map<String, dynamic>.from(item), '');
          }
          // Si es un String (ID), creamos un objeto User básico con ese ID
          return User.fromJson({'_id': item.toString(), 'nombre': 'Usuario'}, '');
        }).toList() ?? [],
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
