import 'user.dart';

class Comment {
  final String id;
  final String texto;
  final User usuario;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.texto,
    required this.usuario,
    required this.createdAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 3) {
      return 'Hace un momento';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h';
    } else if (difference.inDays < 365) {
      return '${difference.inDays} d';
    } else {
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      if (months > 0) {
        return '${years}a ${months}m';
      }
      return '${years}a';
    }
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      texto: json['texto'] ?? '',
      usuario: User.fromJson(json['usuario'] ?? {}, ''),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
