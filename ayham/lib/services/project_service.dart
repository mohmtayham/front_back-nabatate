import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';

class ProjectService {
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

  static Future<List<Project>> getProjects({String? search}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/admin/projects';
      
      if (search != null && search.isNotEmpty) {
        url += '?search=${Uri.encodeQueryComponent(search)}';
      }
      
      print('Fetching projects from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Get Projects Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> projectList = data['projects'] ?? data['data'] ?? [];
        
        print('Successfully fetched ${projectList.length} projects');
        
        return projectList.map((projectJson) {
          return Project.fromJson(projectJson);
        }).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('فشل في جلب المشاريع: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProjects: $e');
      throw Exception('خطأ في الاتصال بالخادم: $e');
    }
  }

  static Future<Project> addProject({
    required String name,
    required String code,
    String? location,
    String? managerName,
    required String status,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'name': name,
        'code': code,
        'status': status,
      };
      
      if (location != null && location.isNotEmpty) {
        body['location'] = location;
      }
      
      if (managerName != null && managerName.isNotEmpty) {
        body['manager_name'] = managerName;
      }
      
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      
      print('Adding project with data: $body');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/projects'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Add Project Status: ${response.statusCode}');
      print('Add Project Body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Project.fromJson(data['project']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'فشل في إضافة المشروع');
      }
    } catch (e) {
      print('Error in addProject: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<Project> updateProject({
    required int id,
    required String name,
    required String code,
    String? location,
    String? managerName,
    required String status,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'name': name,
        'code': code,
        'status': status,
      };
      
      if (location != null && location.isNotEmpty) {
        body['location'] = location;
      }
      
      if (managerName != null && managerName.isNotEmpty) {
        body['manager_name'] = managerName;
      }
      
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      
      print('Updating project $id with data: $body');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/projects/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Update Project Status: ${response.statusCode}');
      print('Update Project Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Project.fromJson(data['project']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في تحديث المشروع');
      }
    } catch (e) {
      print('Error in updateProject: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<void> deleteProject(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/projects/$id'),
        headers: headers,
      );

      print('Delete Project Status: ${response.statusCode}');
      print('Delete Project Body: ${response.body}');
      
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في حذف المشروع');
      }
    } catch (e) {
      print('Error in deleteProject: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }
}