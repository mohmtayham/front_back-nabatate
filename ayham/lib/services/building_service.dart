import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/building_model.dart';

class BuildingService {
  static const String baseUrl = 'http://localhost:8000/api';

  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error getting headers: $e');
      return {};
    }
  }

  static Future<List<Building>> getBuildings() async {
    try {
      final headers = await _getHeaders();
      print('Fetching buildings from: $baseUrl/admin/buildings');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/buildings'),
        headers: headers,
      );

      print('Get Buildings Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> buildingList = data['buildings'] ?? data['data'] ?? [];
        
        print('Successfully fetched ${buildingList.length} buildings');
        
        return buildingList.map((buildingJson) {
          return Building.fromJson(buildingJson);
        }).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('فشل في جلب المباني: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getBuildings: $e');
      throw Exception('خطأ في الاتصال بالخادم: $e');
    }
  }

  static Future<Building> addBuilding({
    required String name,
    required int housingId,
    int? floorsCount,
    int? roomsCount,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'name': name,
        'housing_id': housingId,
      };
      
      if (floorsCount != null) {
        body['floors_count'] = floorsCount;
      }
      
      if (roomsCount != null) {
        body['rooms_count'] = roomsCount;
      }
      
      print('Adding building with data: $body');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/buildings'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Add Building Status: ${response.statusCode}');
      print('Add Building Body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Building.fromJson(data['building']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'فشل في إضافة المبنى');
      }
    } catch (e) {
      print('Error in addBuilding: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<Building> updateBuilding({
    required int id,
    required String name,
    required int housingId,
    int? floorsCount,
    int? roomsCount,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'name': name,
        'housing_id': housingId,
      };
      
      if (floorsCount != null) {
        body['floors_count'] = floorsCount;
      }
      
      if (roomsCount != null) {
        body['rooms_count'] = roomsCount;
      }
      
      print('Updating building $id with data: $body');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/buildings/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Update Building Status: ${response.statusCode}');
      print('Update Building Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Building.fromJson(data['building']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في تحديث المبنى');
      }
    } catch (e) {
      print('Error in updateBuilding: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<void> deleteBuilding(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/buildings/$id'),
        headers: headers,
      );

      print('Delete Building Status: ${response.statusCode}');
      print('Delete Building Body: ${response.body}');
      
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في حذف المبنى');
      }
    } catch (e) {
      print('Error in deleteBuilding: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }
}