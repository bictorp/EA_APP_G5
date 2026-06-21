class ApiConstants {
  static const String _url = 'https://ea5-api.upc.edu';

  static String get baseUrl => _url;

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get googleLoginEndpoint => '$baseUrl/auth/google';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get refreshEndpoint => '$baseUrl/auth/refresh';

  static String get socketUrl => baseUrl;
}
