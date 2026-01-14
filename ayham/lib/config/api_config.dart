class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String loginEndpoint = '/admin/login';
  static const String logoutEndpoint = '/admin/logout';
  static const String usersEndpoint = '/admin/users';
  
  static Map<String, String> headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}