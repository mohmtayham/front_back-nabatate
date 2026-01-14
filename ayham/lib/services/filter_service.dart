// lib/services/filter_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FilterService {
  static const String _baseUrl = 'http://localhost:8000/api/admin';
  
  // جلب جميع خيارات الفلترة المحسنة
  static Future<Map<String, dynamic>> getEnhancedFilterOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/employees/filter-options'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load filter options: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // جلب القيم المميزة لحقل معين
  static Future<Map<String, dynamic>> getDistinctValues(String field) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/employees/distinct-values?field=$field'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get distinct values: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // البحث مع الفلاتر
  static Future<Map<String, dynamic>> searchWithFilters({
    String? search,
    String? projectId,
    String? projectName,
    String? buildingId,
    String? housingId,
    String? housingName,
    String? contractType,
    String? contractId,
    String? sortBy,
    String? sortOrder = 'desc',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final params = <String, String>{};
      
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (projectId != null && projectId.isNotEmpty) params['project_id'] = projectId;
      if (projectName != null && projectName.isNotEmpty) params['project_name'] = projectName;
      if (buildingId != null && buildingId.isNotEmpty) params['building_id'] = buildingId;
      if (housingId != null && housingId.isNotEmpty) params['housing_id'] = housingId;
      if (housingName != null && housingName.isNotEmpty) params['housing_name'] = housingName;
      if (contractType != null && contractType.isNotEmpty) params['contract_type'] = contractType;
      if (contractId != null && contractId.isNotEmpty) params['contract_id'] = contractId;
      if (sortBy != null && sortBy.isNotEmpty) params['sort_by'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) params['sort_order'] = sortOrder;
      params['page'] = page.toString();
      params['per_page'] = perPage.toString();
      
      final uri = Uri.parse('$_baseUrl/employees/filter').replace(queryParameters: params);
      
      print('🔍 Filter API URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Filter service error: $e');
      rethrow;
    }
  }

  // جلب بيانات حقيقية من قاعدة البيانات
  static Future<List<Map<String, dynamic>>> getRealFilterData(String field) async {
    try {
      final result = await getDistinctValues(field);
      if (result['status'] == 'success') {
        final values = List<Map<String, dynamic>>.from(result['values'] ?? []);
        
        // تحويل إلى التنسيق المطلوب مع استبعاد القيم الفارغة
        return values
            .where((item) => item['value'] != null && item['value'].toString().isNotEmpty)
            .map((item) {
          return {
            'id': item['value'],
            'name': item['name'],
            'value': item['value'],
            'display_name': item['display_name'] ?? item['name'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting real data for $field: $e');
      return [];
    }
  }
}