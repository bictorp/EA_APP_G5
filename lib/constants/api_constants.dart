class ApiConstants {
  static const String _url = 'http://localhost:1337';

  static String get baseUrl => _url;

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get refreshEndpoint => '$baseUrl/auth/refresh';

  static String get socketUrl => baseUrl;
}
