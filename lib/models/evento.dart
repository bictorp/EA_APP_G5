import 'user.dart';

class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String ubicacionNombre;
  final double latitude;
  final double longitude;
  final User creador;
  final List<User> asistentes;
  final int? maxAsistentes;
  final bool activo;
  final DateTime? fechaLimite;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.ubicacionNombre,
    required this.latitude,
    required this.longitude,
    required this.creador,
    required this.asistentes,
    this.maxAsistentes,
    required this.activo,
    this.fechaLimite,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    final List<dynamic> coords = json['location']?['coordinates'] ?? [0.0, 0.0];
    final double lng = coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
    final double lat = coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;

    return Evento(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      ubicacionNombre: json['ubicacionNombre'] ?? '',
      latitude: lat,
      longitude: lng,
      creador: User.fromJson(json['creador'] ?? {}, ''),
      asistentes: (json['asistentes'] as List?)?.map((item) {
        if (item is Map) {
          return User.fromJson(Map<String, dynamic>.from(item), '');
        }
        return User.fromJson({'_id': item.toString(), 'nombre': 'Usuario'}, '');
      }).toList() ?? [],
      maxAsistentes: json['maxAsistentes'],
      activo: json['activo'] ?? true,
      fechaLimite: json['fechaLimite'] != null
          ? DateTime.parse(json['fechaLimite'])
          : null,
    );
  }
}
