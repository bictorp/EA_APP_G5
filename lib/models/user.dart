class User {
  final String id;
  final String nombre;
  final String email;
  final String accessToken;
  final String? avatarUrl;
  final String? rol;
  final String? descripcion;
  final dynamic universidad; // Can be ID or Object
  final dynamic grado; // Can be ID or Object
  final List<dynamic> asignaturas;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.accessToken,
    this.avatarUrl,
    this.rol,
    this.descripcion,
    this.universidad,
    this.grado,
    this.asignaturas = const [],
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      accessToken: token,
      avatarUrl: json['avatarUrl'],
      rol: json['rol'],
      descripcion: json['descripcion'],
      universidad: json['universidad'],
      grado: json['grado'],
      asignaturas: json['asignaturas'] ?? [],
    );
  }
}
