import 'post.dart';

class Message {
  final String id;
  final String remitenteId;
  final String destinatarioId;
  final String contenido;
  final Post? post; 
  final Message? parentMessage; 
  final List<MessageReaction>? reactions; 
  final DateTime createdAt;
  final bool leido;
  final bool eliminadoParaTodos;

  Message({
    required this.id,
    required this.remitenteId,
    required this.destinatarioId,
    required this.contenido,
    this.post,
    this.parentMessage,
    this.reactions,
    required this.createdAt,
    this.leido = false,
    this.eliminadoParaTodos = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['_id']?.toString() ?? '',
        remitenteId: (json['remitente'] is Map ? json['remitente']['_id'] : json['remitente'])?.toString() ?? '',
        destinatarioId: (json['destinatario'] is Map ? json['destinatario']['_id'] : json['destinatario'])?.toString() ?? '',
        contenido: json['contenido']?.toString() ?? '',
        post: (json['post'] != null && json['post'] is Map) 
               ? Post.fromJson(Map<String, dynamic>.from(json['post'])) 
               : null,
        parentMessage: (json['parentMessage'] != null && json['parentMessage'] is Map)
               ? Message.fromJson(Map<String, dynamic>.from(json['parentMessage']))
               : null,
        reactions: (json['reactions'] != null && json['reactions'] is List)
               ? (json['reactions'] as List).map((r) => MessageReaction.fromJson(Map<String, dynamic>.from(r))).toList()
               : [],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        leido: json['leido'] ?? false,
        eliminadoParaTodos: json['eliminadoParaTodos'] ?? false,
      );
    } catch (e) {
      print('Error parsing message: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'remitente': remitenteId,
      'destinatario': destinatarioId,
      'contenido': contenido,
      'post': post?.id,
      'createdAt': createdAt.toIso8601String(),
      'leido': leido,
      'eliminadoParaTodos': eliminadoParaTodos,
    };
  }
}

class MessageReaction {
  final String usuarioId;
  final String emoji;

  MessageReaction({required this.usuarioId, required this.emoji});

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      usuarioId: (json['usuario'] is Map ? json['usuario']['_id'] : json['usuario'])?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
    );
  }
}
