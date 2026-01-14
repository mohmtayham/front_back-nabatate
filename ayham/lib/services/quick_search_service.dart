import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuickSearchService {
  static const String baseUrl = 'http://localhost:8000/api';

  static Future<Map<String, dynamic>> searchEmployees({
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      Map<String, String> queryParams = {};
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }
      
      // تحديد عدد النتائج المحدودة
      queryParams['per_page'] = '10';
      
      String url = '$baseUrl/admin/employees/filter';
      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['employees']['data'] ?? [],
          'total': data['total'] ?? 0,
          'active_count': data['active_count'] ?? 0,
          'left_count': data['left_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': 'فشل في البحث',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getFilterOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/employees/filter-options'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'filters': data['filters'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': 'فشل في جلب خيارات الفلاتر',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<bool> exportEmployees(Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      Map<String, String> queryParams = {};
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
      
      String url = '$baseUrl/admin/employees/export/filter';
      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }
}