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

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      texto: json['texto'] ?? '',
      usuario: User.fromJson(json['usuario'] ?? {}, ''),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
