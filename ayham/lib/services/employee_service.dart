// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8000/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ));
    
    // إضافة interceptor لإضافة التوكن
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // الحصول على التوكن
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ==================== الموظفين ====================

  // جلب الموظفين
  Future<Map<String, dynamic>> getEmployees({String? search, int page = 1}) async {
    try {
      final response = await _dio.get('/admin/employees', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      });
      return response.data;
    } catch (e) {
      print('❌ Error getting employees: $e');
      rethrow;
    }
  }

  // إنشاء موظف جديد
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      print('📤 Sending employee data: $data');
      final response = await _dio.post('/admin/employees', data: data);
      return response.data;
    } catch (e) {
      print('❌ Error creating employee: $e');
      rethrow;
    }
  }

  // تحديث موظف
    // حذف جماعي للموظفين
  Future<Map<String, dynamic>> batchDeleteEmployees(List<int> ids) async {
    try {
      print('📤 Batch delete request for IDs: $ids');
      
      final response = await _dio.post(
        '/admin/employees/batch-delete',
        data: {'ids': ids},
      );

      print('✅ Batch delete response: ${response.data}');
      return {
        'success': true,
        'message': response.data['message'] ?? 'تم الحذف الجماعي بنجاح',
        'data': response.data,
      };
    } on DioException catch (e) {
      print('❌ Batch delete error: ${e.response?.statusCode} - ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'فشل في الحذف الجماعي',
      };
    } catch (e) {
      print('🔴 Unexpected batch delete error: $e');
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع',
      };
    }
  }

  // تحديث السكن جماعي للموظفين
  Future<Map<String, dynamic>> batchUpdateHousing(List<int> ids, String housingName) async {
    try {
      print('📤 Batch update housing for IDs: $ids → $housingName');
      
      final response = await _dio.post(
        '/admin/employees/batch-update-housing',
        data: {
          'ids': ids,
          'housing_name': housingName,
        },
      );

      print('✅ Batch update housing response: ${response.data}');
      return {
        'success': true,
        'message': response.data['message'] ?? 'تم تحديث السكن الجماعي بنجاح',
        'data': response.data,
      };
    } on DioException catch (e) {
      print('❌ Batch update housing error: ${e.response?.statusCode} - ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'فشل في تحديث السكن الجماعي',
      };
    } catch (e) {
      print('🔴 Unexpected batch update error: $e');
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع',
      };
    }
  }

  // ==================== استيراد Excel ====================

  Future<Map<String, dynamic>> importExcel(File file) async {
    try {
      print('📤 ApiService: Importing Excel file: ${file.path}');
      print('📏 File size: ${await file.length()} bytes');
      
      // إنشاء FormData
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: path.basename(file.path),
        ),
      });

      // ⭐⭐ **محاولة عدة عناوين للويندوز** ⭐⭐
      List<String> baseUrls = [
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://0.0.0.0:8000',
      ];

      Response? response;
      String lastError = '';

      for (var baseUrl in baseUrls) {
        try {
          print('🔄 Trying URL: $baseUrl/api');
          
          Dio tempDio = Dio(BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Accept': 'application/json',
              'Authorization': await _getToken() != null ? 'Bearer ${await _getToken()}' : null,
            },
          ));

          response = await tempDio.post(
            '/api/admin/employees/import',
            data: formData,
            options: Options(
              contentType: 'multipart/form-data',
              headers: {
                'Accept': 'application/json',
              },
            ),
          );

          print('✅ Success with URL: $baseUrl');
          break;
        } catch (e) {
          lastError = e.toString();
          print('❌ Failed with URL $baseUrl: ${e.toString()}');
          continue;
        }
      }

      if (response == null) {
        throw Exception('All URLs failed. Last error: $lastError');
      }

      print('📥 Import API Response Status: ${response.statusCode}');
      print('📥 Import API Data: ${response.data}');

      return response.data;
      
    } catch (e) {
      print('🔥 ApiService Import Error: $e');
      return {
        'status': 'error',
        'message': 'Import failed: ${e.toString()}',
        'success': false,
      };
    }
  }

  // ==================== التصدير ====================
Future<File?> exportEmployees({String? search}) async {
  try {
    final Dio exportDio = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        headers: _dio.options.headers,
        connectTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 15),
        sendTimeout: const Duration(minutes: 15),
      ),
    );

    print('📤 Calling export API');

    final response = await exportDio.get(
      '/admin/employees/export',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
      options: Options(responseType: ResponseType.bytes),
    );

    final dir = Directory.systemTemp;
    final file = File(
      '${dir.path}/employees_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    await file.writeAsBytes(response.data);
    return file;
  } catch (e) {
    print('❌ Export failed: $e');
    throw Exception('فشل في التصدير: $e');
  }
}


  // ==================== المرفقات ====================

  Future<Map<String, dynamic>> getAttachments(int employeeId) async {
    try {
      final response = await _dio.get('/admin/employees/$employeeId/attachments');
      return response.data;
    } catch (e) {
      print('❌ Error getting attachments: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(int employeeId, File file) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: path.basename(file.path),
        ),
      });

      final response = await _dio.post(
        '/admin/employees/$employeeId/attachments',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return response.data;
    } catch (e) {
      print('❌ Error uploading attachment: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteAttachment(int attachmentId) async {
    try {
      final response = await _dio.delete('/admin/attachments/$attachmentId');
      return response.data;
    } catch (e) {
      print('❌ Error deleting attachment: $e');
      rethrow;
    }
  }

  Future<File?> downloadAttachment(int attachmentId) async {
    try {
      final response = await _dio.get(
        '/admin/attachments/$attachmentId/download',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        final directory = Directory.systemTemp;
        final file = File('${directory.path}/attachment_$attachmentId');
        await file.writeAsBytes(response.data as List<int>);
        return file;
      }
      
      return null;
    } catch (e) {
      print('❌ Error downloading attachment: $e');
      return null;
    }
  }

  // ==================== مساعدات ====================

  String getAttachmentUrl(String filePath) {
    return 'http://localhost:8000/storage/$filePath';
  }

  // اختبار الاتصال بالخادم
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/admin/employees', queryParameters: {'page': 1});
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}