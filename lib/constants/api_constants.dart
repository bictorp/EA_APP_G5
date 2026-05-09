import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class ApiConstants {
  static String get baseUrl {
    // Si la app está compilada para producción (Release Mode)
    if (const bool.fromEnvironment('dart.vm.product') || kReleaseMode) {
      return 'https://tu-servidor-produccion.com'; // CAMBIAR AQUÍ PARA PRODUCCIÓN
    }

    if (kIsWeb) {
      return 'http://localhost:1337';
    } else if (Platform.isAndroid) {
      // Usamos tu IP local que sabemos que funciona en tu entorno
      return 'http://192.168.1.24:1337';
    } else {
      return 'http://localhost:1337';
    }
  }

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get refreshEndpoint => '$baseUrl/auth/refresh';

  static String get socketUrl => baseUrl;
}
