class Grado {
  final String id;
  final String nombre;
  final List<dynamic> asignaturas; // Can be IDs or populated objects
  final dynamic universidad; // Can be ID or populated object

  Grado({
    required this.id,
    required this.nombre,
    this.asignaturas = [],
    this.universidad,
  });

  factory Grado.fromJson(Map<String, dynamic> json) {
    return Grado(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      asignaturas: json['asignaturas'] ?? [],
      universidad: json['universidad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'asignaturas': asignaturas,
      'universidad': universidad,
    };
  }
}