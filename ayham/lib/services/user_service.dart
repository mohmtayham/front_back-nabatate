
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://localhost:8000/api';


  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
      );

      print('Get Users Status: ${response.statusCode}');
      print('Get Users Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true, 
          'users': data['data'] ?? data['users'] ?? []
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false, 
          'message': error['message'] ?? 'فشل في جلب المستخدمين'
        };
      }
    } catch (e) {
      print('Error in getUsers: $e');
      return {
        'success': false, 
        'message': 'خطأ في الاتصال: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> addUser({
    required String name,
    required String email,
    required String password,
    required List<String> permissions,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'permissions': permissions,
        }),
      );

      print('Add User Status: ${response.statusCode}');
      print('Add User Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'تم إضافة المستخدم بنجاح'};
      } else {
        final error = jsonDecode(response.body);
        final errors = error['errors'] ?? {};
        String errorMessage = error['message'] ?? 'فشل في إضافة المستخدم';
        
        if (errors.containsKey('email')) {
          errorMessage = 'البريد الإلكتروني مستخدم مسبقاً';
        } else if (errors.containsKey('password')) {
          errorMessage = 'كلمة المرور غير صالحة';
        }
        
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error in addUser: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String name,
    required String email,
    String? password,
    required List<String> permissions,
  }) async {
    try {
      final headers = await _getHeaders();
      
      Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'permissions': permissions,
        '_method': 'PUT', // لإرسال PUT عبر POST
      };
      
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
        body['password_confirmation'] = password;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Update User Status: ${response.statusCode}');
      print('Update User Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم تحديث المستخدم بنجاح'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false, 
          'message': error['message'] ?? 'فشل في تحديث المستخدم'
        };
      }
    } catch (e) {
      print('Error in updateUser: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      print('Delete User Status: ${response.statusCode}');
      print('Delete User Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم حذف المستخدم بنجاح'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false, 
          'message': error['message'] ?? 'فشل في حذف المستخدم'
        };
      }
    } catch (e) {
      print('Error in deleteUser: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
}