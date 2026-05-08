import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:1337';
    } else if (Platform.isAndroid) {
      // Usamos la IP local de tu PC para máxima compatibilidad
      return 'http://192.168.1.24:1337';
    } else {
      return 'http://localhost:1337';
    }
  }

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get refreshEndpoint => '$baseUrl/auth/refresh';
}
