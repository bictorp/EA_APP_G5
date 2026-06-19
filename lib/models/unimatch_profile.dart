class UnimatchPhoto {
  final String id;
  final String userId;
  final String imageUrl;
  final int order;

  UnimatchPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.order,
  });

  factory UnimatchPhoto.fromJson(Map<String, dynamic> json) {
    return UnimatchPhoto(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class UnimatchProfile {
  final String id;
  final String nombre;
  final String? avatarUrl;
  final String? descripcion;
  final Map<String, dynamic>? universidad;
  final Map<String, dynamic>? grado;
  final List<Map<String, dynamic>> asignaturas;
  final List<UnimatchPhoto> unimatchPhotos;

  UnimatchProfile({
    required this.id,
    required this.nombre,
    this.avatarUrl,
    this.descripcion,
    this.universidad,
    this.grado,
    this.asignaturas = const [],
    this.unimatchPhotos = const [],
  });

  factory UnimatchProfile.fromJson(Map<String, dynamic> json) {
    var photosList = json['unimatchPhotos'] as List? ?? [];
    List<UnimatchPhoto> photos = photosList.map((p) => UnimatchPhoto.fromJson(p)).toList();

    var asigList = json['asignaturas'] as List? ?? [];
    List<Map<String, dynamic>> asig = asigList.map((a) => Map<String, dynamic>.from(a)).toList();

    return UnimatchProfile(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      avatarUrl: json['avatarUrl'],
      descripcion: json['descripcion'],
      universidad: json['universidad'] != null ? Map<String, dynamic>.from(json['universidad']) : null,
      grado: json['grado'] != null ? Map<String, dynamic>.from(json['grado']) : null,
      asignaturas: asig,
      unimatchPhotos: photos,
    );
  }
}
