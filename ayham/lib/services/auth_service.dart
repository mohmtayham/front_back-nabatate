import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabtatcompany/services/api_service.dart';
import 'package:flutter/foundation.dart'; // ✅ هذا السطر يحل مشكلة الخط الأحمر

class AuthService {
  
  // تسجيل الدخول
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await ApiService().login(email, password);
    
    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      // حفظ بيانات المستخدم كاملة
      await prefs.setString('user', jsonEncode(result['user']));
      await prefs.setString('user_name', result['user']['name'] ?? 'Admin');
      await prefs.setString('user_email', result['user']['email'] ?? '');
    }
    return result;
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    try {
      await ApiService().logout();
    } catch (e) {
      if (kDebugMode) print('Logout error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // جلب بيانات المستخدم
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString == null) return null;
    return jsonDecode(userString);
  }
static Future<bool> can(String module, String action) async {
  return true; // 🔥 اجبار التطبيق على فتح كل الصفحات
}


  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'مستخدم';
  }


}