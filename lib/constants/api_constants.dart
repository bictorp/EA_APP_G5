import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get _url {
    if (kIsWeb) {
      return 'http://localhost:1338';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:1338';
    }
    return 'http://localhost:1338';
  }

  static String get baseUrl => _url;

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get refreshEndpoint => '$baseUrl/auth/refresh';

  static String get socketUrl => baseUrl;
}
