import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:1337';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:1337';
    } else {
      return 'http://localhost:1337';
    }
  }

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
}
