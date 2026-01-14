import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeCaseService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/admin';


  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // 'Authorization': 'Bearer YOUR_TOKEN',
      };

  /// GET cases
  Future<List<EmployeeCase>> fetchCases(int employeeId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/employees/$employeeId/cases'),
      headers: headers,
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return (data['cases']['data'] as List)
          .map((e) => EmployeeCase.fromJson(e))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load cases');
    }
  }

  /// CREATE
  Future<EmployeeCase> createCase(
      int employeeId, EmployeeCase employeeCase) async {
    final res = await http.post(
      Uri.parse('$baseUrl/employees/$employeeId/cases'),
      headers: headers,
      body: jsonEncode(employeeCase.toJson()),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      return EmployeeCase.fromJson(data['case']);
    } else {
      throw Exception(data['message'] ?? 'Failed to create case');
    }
  }

  /// UPDATE
  Future<EmployeeCase> updateCase(
      int caseId, EmployeeCase employeeCase) async {
    final res = await http.put(
      Uri.parse('$baseUrl/employee-cases/$caseId'),
      headers: headers,
      body: jsonEncode(employeeCase.toJson()),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return EmployeeCase.fromJson(data['case']);
    } else {
      throw Exception(data['message'] ?? 'Failed to update case');
    }
  }
  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// DELETE
Future<void> deleteCase(int id) async {
    final url = Uri.parse('$baseUrl/cases/$id');
    final headers = await getHeaders();

    print('🚀 Calling Delete Case...');
    print('📍 URL: $url');
    print('🔑 Headers Sent: $headers');

    try {
      final response = await http.delete(url, headers: headers);

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Case deleted successfully');
      } else {
        // If it's not 200, we catch the backend error message here
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete case');
      }
    } catch (e) {
      print('❌ Error in deleteCase: $e');
      rethrow;
    }
  }

}
