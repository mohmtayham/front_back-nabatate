// lib/services/housing_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../models/housing_model.dart';

class HousingService {
  static const String baseUrl = 'http://localhost:8000/api';
  // للإستخدام على الهاتف المحمول:
  // static const String baseUrl = 'http://192.168.1.X:8000/api';

  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      if (isMultipart) {
        return {
          'Authorization': 'Bearer $token',
        };
      }
      
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

  static Future<List<Housing>> getHousings() async {
    try {
      final headers = await _getHeaders();
      print('Fetching housings from: $baseUrl/admin/housings');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/housings'),
        headers: headers,
      );

      print('Get Housings Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> housingList = data['housings'] ?? data['data'] ?? [];
        
        print('Successfully fetched ${housingList.length} housings');
        
        return housingList.map((housingJson) {
          return Housing.fromJson(housingJson);
        }).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('فشل في جلب السكن: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getHousings: $e');
      throw Exception('خطأ في الاتصال بالخادم: $e');
    }
  }

  static Future<Housing> addHousing({
    required String name,
    required String housingType,
    String? housingNumber,
    String? address,
    int? buildingsCount,
    int? roomsCount,
    File? housingLicense,
    double? housingValue,
    bool? rentDue,
    String? rentDueDate,
    bool? rentPaid,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders(isMultipart: true);
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/housings'),
      );
      
      request.headers.addAll(headers);
      
      // إضافة الحقول الإلزامية
      request.fields['name'] = name;
      request.fields['housing_type'] = housingType;
      
      // إضافة الحقول الاختيارية النصية
      _addOptionalField(request, 'housing_number', housingNumber);
      _addOptionalField(request, 'address', address);
      _addOptionalField(request, 'buildings_count', buildingsCount);
      _addOptionalField(request, 'rooms_count', roomsCount);
      _addOptionalField(request, 'housing_value', housingValue);
      _addOptionalField(request, 'rent_due', rentDue);
      _addOptionalField(request, 'rent_due_date', rentDueDate);
      _addOptionalField(request, 'rent_paid', rentPaid);
      _addOptionalField(request, 'notes', notes);
      
      // إضافة رخصة السكن إذا وجدت
      if (housingLicense != null) {
        try {
          if (!await housingLicense.exists()) {
            print('License file does not exist: ${housingLicense.path}');
          } else {
            var fileName = housingLicense.path.split('/').last;
            var extension = fileName.split('.').last.toLowerCase();
            
            String contentType;
            switch (extension) {
              case 'jpg':
              case 'jpeg':
                contentType = 'image/jpeg';
                break;
              case 'png':
                contentType = 'image/png';
                break;
              case 'pdf':
                contentType = 'application/pdf';
                break;
              default:
                contentType = 'application/octet-stream';
            }
            
            var multipartFile = await http.MultipartFile.fromPath(
              'housing_license',
              housingLicense.path,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            );
            
            request.files.add(multipartFile);
            print('Added housing license: $fileName');
          }
        } catch (e) {
          print('Error adding housing license: $e');
        }
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Add Housing Status: ${response.statusCode}');
      print('Add Housing Body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Housing.fromJson(data['housing']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'فشل في إضافة السكن');
      }
    } catch (e) {
      print('Error in addHousing: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<Housing> updateHousing({
    required int id,
    required String name,
    required String housingType,
    String? housingNumber,
    String? address,
    int? buildingsCount,
    int? roomsCount,
    File? housingLicense,
    double? housingValue,
    bool? rentDue,
    String? rentDueDate,
    bool? rentPaid,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders(isMultipart: true);
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/housings/$id'),
      );
      
      request.headers.addAll(headers);
      
      // إضافة الحقول الإلزامية
      request.fields['_method'] = 'PUT';
      request.fields['name'] = name;
      request.fields['housing_type'] = housingType;
      
      // إضافة الحقول الاختيارية النصية
      _addOptionalField(request, 'housing_number', housingNumber);
      _addOptionalField(request, 'address', address);
      _addOptionalField(request, 'buildings_count', buildingsCount);
      _addOptionalField(request, 'rooms_count', roomsCount);
      _addOptionalField(request, 'housing_value', housingValue);
      _addOptionalField(request, 'rent_due', rentDue);
      _addOptionalField(request, 'rent_due_date', rentDueDate);
      _addOptionalField(request, 'rent_paid', rentPaid);
      _addOptionalField(request, 'notes', notes);
      
      // إضافة رخصة السكن الجديدة إذا وجدت
      if (housingLicense != null) {
        try {
          if (!await housingLicense.exists()) {
            print('New license file does not exist: ${housingLicense.path}');
          } else {
            var fileName = housingLicense.path.split('/').last;
            var extension = fileName.split('.').last.toLowerCase();
            
            String contentType;
            switch (extension) {
              case 'jpg':
              case 'jpeg':
                contentType = 'image/jpeg';
                break;
              case 'png':
                contentType = 'image/png';
                break;
              case 'pdf':
                contentType = 'application/pdf';
                break;
              default:
                contentType = 'application/octet-stream';
            }
            
            var multipartFile = await http.MultipartFile.fromPath(
              'housing_license',
              housingLicense.path,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            );
            
            request.files.add(multipartFile);
            print('Added new housing license: $fileName');
          }
        } catch (e) {
          print('Error adding new housing license: $e');
        }
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Update Housing Status: ${response.statusCode}');
      print('Update Housing Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Housing.fromJson(data['housing']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في تحديث السكن');
      }
    } catch (e) {
      print('Error in updateHousing: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<void> deleteHousing(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/housings/$id'),
        headers: headers,
      );

      print('Delete Housing Status: ${response.statusCode}');
      print('Delete Housing Body: ${response.body}');
      
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في حذف السكن');
      }
    } catch (e) {
      print('Error in deleteHousing: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // دالة مساعدة لإضافة الحقول الاختيارية
  static void _addOptionalField(http.MultipartRequest request, String fieldName, dynamic value) {
    if (value != null) {
      if (value is String && value.isNotEmpty) {
        request.fields[fieldName] = value;
      } else if (value is int || value is double) {
        request.fields[fieldName] = value.toString();
      } else if (value is bool) {
        request.fields[fieldName] = value.toString();
      }
    }
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }
}