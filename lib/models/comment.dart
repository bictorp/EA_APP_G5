import 'package:get/get.dart';
import 'user.dart';

class Comment {
  final String id;
  final String texto;
  final User usuario;
  final List<String> likes;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.texto,
    required this.usuario,
    required this.likes,
    required this.createdAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 3) {
      return 'just_now'.tr;
    } else if (difference.inHours < 1) {
      return 'time_minutes_short'.trParams({'val': difference.inMinutes.toString()});
    } else if (difference.inDays < 1) {
      return 'time_hours_short'.trParams({'val': difference.inHours.toString()});
    } else if (difference.inDays < 365) {
      return 'time_days_short'.trParams({'val': difference.inDays.toString()});
    } else {
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      if (months > 0) {
        return 'time_years_months_short'.trParams({
          'years': years.toString(),
          'months': months.toString(),
        });
      }
      return 'time_years_short'.trParams({'val': years.toString()});
    }
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      texto: json['texto'] ?? '',
      usuario: json['usuario'] is Map
          ? User.fromJson((json['usuario'] as Map).cast<String, dynamic>(), '')
          : User(id: json['usuario']?.toString() ?? '', nombre: '...', avatarUrl: '', email: '', accessToken: ''),
      likes: (json['likes'] as List?)?.map((id) => id.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
