class User {
  final String id;
  final String nombre;
  final String email;
  final String accessToken;
  final String? avatarUrl;
  final String? rol;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.accessToken,
    this.avatarUrl,
    this.rol,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      accessToken: token,
      avatarUrl: json['avatarUrl'],
      rol: json['rol'],
    );
  }
}
