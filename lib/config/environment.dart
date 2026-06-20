import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  /// Carga el archivo .env
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print("Warning: Could not load .env file. Falling back to default values. Error: $e");
    }
  }

  /// Obtiene la URL de la API según la plataforma
  static String get apiUrlWeb => dotenv.env['API_URL_WEB'] ?? 'http://localhost:1338';
  static String get apiUrlAndroid => dotenv.env['API_URL_ANDROID'] ?? 'http://10.0.2.2:1338';
  static String get apiUrlIos => dotenv.env['API_URL_IOS'] ?? 'http://localhost:1338';
}
