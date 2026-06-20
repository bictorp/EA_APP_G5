import 'package:flutter/foundation.dart';
import '../config/environment.dart';

class ApiConstants {
  static String get _url {
    if (kIsWeb) {
      return Environment.apiUrlWeb;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Environment.apiUrlAndroid;
    }
    return Environment.apiUrlIos;
  }

  static String get baseUrl => _url;

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get refreshEndpoint => '$baseUrl/auth/refresh';

  static String get socketUrl => baseUrl;
}
