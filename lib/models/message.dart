class Message {
  final String id;
  final String remitenteId;
  final String destinatarioId;
  final String contenido;
  final DateTime createdAt;
  final bool leido;
  final bool eliminadoParaTodos;

  Message({
    required this.id,
    required this.remitenteId,
    required this.destinatarioId,
    required this.contenido,
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
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        leido: json['leido'] ?? false,
        eliminadoParaTodos: json['eliminadoParaTodos'] ?? false,
      );
    } catch (e) {
      print('[Message] Error parseando mensaje: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'remitente': remitenteId,
      'destinatario': destinatarioId,
      'contenido': contenido,
      'createdAt': createdAt.toIso8601String(),
      'leido': leido,
      'eliminadoParaTodos': eliminadoParaTodos,
    };
  }
}
