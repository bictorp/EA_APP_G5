class Asignatura {
  final String id;
  final String nombre;
  final List<dynamic> usuarios; // Can contain user IDs or populated users

  Asignatura({
    required this.id,
    required this.nombre,
    this.usuarios = const [],
  });

  factory Asignatura.fromJson(Map<String, dynamic> json) {
    return Asignatura(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      usuarios: json['usuarios'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'usuarios': usuarios,
    };
  }
}