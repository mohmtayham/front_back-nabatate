class Constants {
  static const String appName = 'نظام الإدارة';
  
  // عنوان خادم Laravel
  static const String baseUrl = 'http://localhost:8000';
  
  // نهايات API
  static const String loginUrl = '$baseUrl/api/admin/login';
  static const String logoutUrl = '$baseUrl/api/admin/logout';
}