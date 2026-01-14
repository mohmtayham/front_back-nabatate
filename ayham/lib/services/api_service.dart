import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint
import 'package:nabtatcompany/services/notification_service.dart';
import 'package:open_filex/open_filex.dart';


class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000/api/admin',
    connectTimeout: const Duration(seconds: 300),
    receiveTimeout: const Duration(seconds: 300),
  ));

  // Constructor - إضافة interceptor للتحقق من التوكن
  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        // إذا كان الخطأ بسبب انتهاء صلاحية التوكن
        if (error.response?.statusCode == 401) {
          await _saveToken('');
        }
        handler.next(error);
      },
    ));
  }

    // Normalize permissions coming from various backend shapes into List<String>
    List<String> _normalizePermissions(dynamic rawPermissions) {
      try {
        if (rawPermissions == null) return [];
        // Already a list of strings
        if (rawPermissions is List) {
          return rawPermissions.map((e) => e.toString()).toList();
        }

        // If it's a JSON string
        if (rawPermissions is String) {
          final decoded = jsonDecode(rawPermissions);
          return _normalizePermissions(decoded);
        }

        // If it's a map/object
        if (rawPermissions is Map) {
          final List<String> out = [];
          // If map is flat like {"index_employees": true}
          rawPermissions.forEach((k, v) {
            if (v == true) {
              out.add(k.toString());
            }
          });

          // Also handle nested map like {"employees": {"index": true, "view": true}}
          rawPermissions.forEach((module, actions) {
            if (actions is Map) {
              actions.forEach((action, allowed) {
                if (allowed == true) {
                  out.add('${action}_${module}');
                }
              });
            }
          });

          return out;
        }

        return [];
      } catch (e) {
        debugPrint('ApiService._normalizePermissions error: $e');
        return [];
      }
    }
  /// تسجيل الخروج - إبطال التوكن على الخادم ومسح البيانات محليًا
Future<void> logout() async {
  try {
    // إرسال طلب logout إلى الباك اند (عادةً POST إلى /logout)
    await _dio.post('/logout');
    print('✅ تم تسجيل الخروج من الخادم بنجاح');
  } on DioException catch (e) {
    // حتى لو فشل الطلب (مثل 401 أو انقطاع الشبكة)، نمسح البيانات محليًا على أي حال
    print('⚠️ فشل طلب logout من الخادم: ${e.response?.statusCode} - ${e.message}');
    // لا نوقف التنفيذ، لأننا بنمسح البيانات محليًا برضو
  } catch (e) {
    print('⚠️ خطأ غير متوقع أثناء logout: $e');
  } finally {
    // في كل الأحوال: نمسح التوكن والبيانات المحلية
    await _saveToken('');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // أو احذف المفاتيح المحددة فقط إذا أردت
    print('🧹 تم مسح جميع البيانات المحلية');
  }
}
// lib/services/auth_service.dart
 static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString == null) return null;
    return jsonDecode(userString);
  }
static Future<bool> can(String module, String action) async {
  final user = await getUser();
  if (user == null) return false;

  // 🔥 FIX: If user is Admin, allow everything immediately!
  if (user['type'] == 'admin') {
    return true;
  }

  final permissions = user['permissions'];
  
  // If permissions is a List
  if (permissions is List) {
    return permissions.contains('${action}_${module}') ||
           permissions.contains('${module}_${action}') ||
           permissions.contains(action);
  }

  // If permissions is a Map
  if (permissions is Map) {
    // Check if the specific module exists
    final modulePermissions = permissions[module];
    // If modulePermissions is a Map, check the action
    if (modulePermissions is Map) {
      return modulePermissions[action] == true;
    }
    // Handle case where permissions might be: {"users": {"view": true}}
    // or flat map logic if needed.
  }

  return false;
}
  
Future<void> updateReminder(int id, Map<String, dynamic> data) async {
  await _dio.put('/payment-reminders/$id', data: data);

  // إلغاء الإشعار القديم
  await NotificationService().cancelNotification(id);

  // لو لسه غير مدفوع
  if (data['payment_status'] == false) {
    final dueDate = DateTime.parse(data['due_date']);

    await NotificationService().scheduleReminderNotification(
      id: id,
      title: '🔔 تذكير دفع',
      body: 'باقي 10 أيام على موعد الدفع',
      dueDate: dueDate, // ✅ الاسم الصحيح
    );
  }
}


Future<File> printEmployeesZip() async {
  // صلاحية التخزين
  final status = await Permission.storage.request();
  if (!status.isGranted) {
    throw Exception('تم رفض إذن التخزين');
  }

  final dir = await getApplicationDocumentsDirectory();
  final filePath =
      '${dir.path}/employees_${DateTime.now().millisecondsSinceEpoch}.zip';

  try {
    final response = await _dio.download(
      '/employees/print',
      filePath,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'application/zip',
        },
      ),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          debugPrint('⬇️ ${(received / total * 100).toStringAsFixed(0)}%');
        }
      },
    );

    debugPrint('printEmployeesZip: download completed, status=${response.statusCode}');

    final file = File(filePath);
    await OpenFilex.open(file.path); // يفتح ZIP

    return file;
  } on DioException catch (e) {
    // Log detailed info for debugging
    debugPrint('printEmployeesZip: DioException status=${e.response?.statusCode}');
    debugPrint('printEmployeesZip: response data=${e.response?.data}');
    debugPrint('printEmployeesZip: request url=${e.requestOptions.uri}');

    String message = 'خطأ أثناء طباعة الموظفين';
    if (e.response != null) {
      final code = e.response?.statusCode;
      if (code == 403) {
        message = 'مرفوض: ليس لديك صلاحية طباعة الموظفين (403)';
      } else if (code == 401) {
        message = 'غير مصرح: تأكد من تسجيل الدخول (401)';
      } else {
        message = 'خطأ في السيرفر: ${e.response?.statusCode}';
      }
    }

    throw Exception('$message — ${e.message} — ${e.response?.data}');
  } catch (e) {
    debugPrint('printEmployeesZip: unexpected error: $e');
    rethrow;
  }
}

/// Delete all employees (calls backend route: DELETE /employees/delete-all)
Future<Map<String, dynamic>> deleteAllEmployees() async {
  try {
    final response = await _dio.delete('/employees/delete-all');

    // backend returns success flag and message
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return {
        'success': data['success'] == true || response.statusCode == 200,
        'message': data['message'] ?? 'All employees deleted',
      };
    }

    return {
      'success': response.statusCode == 200,
      'message': 'All employees deleted',
    };
  } on DioException catch (e) {
    debugPrint('deleteAllEmployees: DioException status=${e.response?.statusCode}');
    final code = e.response?.statusCode;
    String message = 'Failed to delete all employees';
    if (code == 403) {
      message = 'Forbidden: you do not have permission to delete employees (403)';
    } else if (e.response?.data != null && e.response?.data is Map) {
      message = (e.response?.data as Map)['message']?.toString() ?? message;
    } else {
      message = e.message ?? message;
    }

    return {'success': false, 'message': message};
  } catch (e) {
    debugPrint('deleteAllEmployees: unexpected error: $e');
    return {'success': false, 'message': e.toString()};
  }
}


Future<void> markAsPaid(int id) async {
  await _dio.post('/payment-reminders/$id/pay');

  await NotificationService().cancelNotification(id);
}



 Future<void> createReminder(Map<String, dynamic> data) async {
  final response = await _dio.post(
    '/payment-reminders',
    data: data,
  );

  if (response.data['data'] != null) {
    final reminder = response.data['data'];
    final dueDate = DateTime.parse(reminder['due_date']);

    await NotificationService().scheduleReminderNotification(
      id: reminder['id'],
      title: '🔔 تذكير دفع',
      body: 'باقي 10 أيام على موعد الدفع',
      dueDate: dueDate, // ✅ فقط dueDate
    );
  }
}


  

  ///
Future<Map<String, dynamic>> changePassword({
  required String currentPassword,
  required String newPassword,
  required String newPasswordConfirmation,
}) async {
  try {
    print('🔄 Sending change password request...');
    final response = await _dio.post(
      '/change-password',  // ← FIXED: Remove extra /api/admin/
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );

    print('✅ SUCCESS: ${response.statusCode}');
    print('✅ Response: ${response.data}');

    String message = 'تم تغيير كلمة المرور بنجاح';
    if (response.data is Map<String, dynamic>) {
      message = response.data['message'] ?? message;
    } else if (response.data is String) {
      message = response.data;
    }

    return {'success': true, 'message': message};

  } on DioException catch (e) {
    print('❌ ERROR: ${e.response?.statusCode}');
    print('❌ Response data: ${e.response?.data}');
    print('❌ Request URL: ${e.requestOptions.uri}');  // ← IMPROVED: Print full URI for debugging

    String message = 'فشل في تغيير كلمة المرور';

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
      } else if (data is String) {
        if (data.contains('Method Not Allowed')) {
          message = 'خطأ في عنوان الطلب - تأكد من إضافة /api/';
        } else if (data.contains('<title>Laravel</title>')) {  // ← NEW: Detect welcome page HTML
          message = 'عنوان خاطئ: تأكد من أن الـ URL لا يحتوي على تكرار (/api/admin)';
        } else {
          message = data.substring(0, 100) + '...';  // Truncate huge HTML for snackbar
        }
      }
    }

    return {'success': false, 'message': message};
  } catch (e) {
    print('❌ Unexpected: $e');
    return {'success': false, 'message': 'حدث خطأ غير متوقع'};
  }



}

  // ==============================
  // توكن وحفظ التوكن
  // ==============================
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ==============================
  // Saved accounts (quick login)
  // ==============================
  static const String _savedAccountsKey = 'saved_accounts';

  Future<List<Map<String, dynamic>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedAccountsKey);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('getSavedAccounts: failed to decode: $e');
      return [];
    }
  }

  Future<void> _addSavedAccount(Map<String, dynamic> userWithToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getSavedAccounts();
      // remove existing by email if present
      list.removeWhere((u) => (u['email'] ?? '') == (userWithToken['email'] ?? ''));
      // push new at front
      list.insert(0, userWithToken);
      // keep limited history (10)
      final limited = list.take(10).toList();
      await prefs.setString(_savedAccountsKey, jsonEncode(limited));
      debugPrint('Saved accounts updated: ${limited.map((e) => e['email']).toList()}');
    } catch (e) {
      debugPrint('addSavedAccount error: $e');
    }
  }

  Future<void> removeSavedAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedAccounts();
    list.removeWhere((u) => (u['email'] ?? '') == email);
    await prefs.setString(_savedAccountsKey, jsonEncode(list));
  }

  /// Quick login using previously saved account (must include stored token)
  Future<Map<String, dynamic>> quickLogin(String email) async {
    final list = await getSavedAccounts();
    final acc = list.firstWhere((a) => (a['email'] ?? '') == email, orElse: () => {});
    if (acc.isEmpty) return {'success': false, 'message': 'No saved account'};

    final token = acc['token']?.toString() ?? '';
    if (token.isEmpty) return {'success': false, 'message': 'No token stored for this account'};

    // Set token and user locally
    await _saveToken(token);
    // After restoring token, fetch latest user info from server to ensure
    // permissions are current (saved quick-account may be stale or incomplete).
    try {
      final authResult = await checkAuth();
      if (authResult['authenticated'] == true && authResult['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final freshUser = Map<String, dynamic>.from(authResult['user']);
        await prefs.setString('user', jsonEncode(freshUser));
        await prefs.setBool('is_logged_in', true);
        return {'success': true, 'user': freshUser};
      }
    } catch (e) {
      debugPrint('quickLogin: checkAuth failed: $e');
    }

    // Fallback: if checkAuth failed, use stored account (without token field)
    final prefs = await SharedPreferences.getInstance();
    final userMap = Map<String, dynamic>.from(acc);
    userMap.remove('token');
    await prefs.setString('user', jsonEncode(userMap));
    await prefs.setBool('is_logged_in', true);

    return {'success': true, 'user': userMap};
  }

  // ==============================
  // تسجيل الدخول
  // ==============================
// Replace ONLY the login function in your ApiService class

// In lib/services/api_service.dart

Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final response = await _dio.post('/login', data: {
      'email': email.trim(),
      'password': password,
    });

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      debugPrint('ApiService.login: response.data => $data');
      final String token = data['token']?.toString() ?? '';

      if (token.isEmpty) return {'success': false, 'message': 'فشل الحصول على التوكن'};

      await _saveToken(token);


      // تأمين تحويل الصلاحيات (Permissions)
      dynamic rawPermissions = data['permissions'];
      debugPrint('ApiService.login: rawPermissions => $rawPermissions');
        final List<String> formattedPermissions = _normalizePermissions(rawPermissions);
        debugPrint('ApiService.login: normalized permissions => $formattedPermissions');

      final user = {
        'id': data['id'],
        'name': data['name'] ?? 'مستخدم',
        'email': data['email'] ?? '',
        'type': data['type'] ?? 'user',
        'permissions': formattedPermissions,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user));
      await prefs.setBool('is_logged_in', true); // حفظ حالة الدخول

      // Save to quick-login list with token so user can login without password later
      final userWithToken = Map<String, dynamic>.from(user);
      userWithToken['token'] = token;
      await _addSavedAccount(userWithToken);

      return {'success': true, 'user': user};
    }
    return {'success': false, 'message': 'بيانات الدخول غير صحيحة'};
  } on DioException catch (e) {
    return {'success': false, 'message': e.response?.data?['message'] ?? 'خطأ في الاتصال بالخادم'};
  }
}
    Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }


  // التحقق من حالة المصادقة
// ✅ التعديل المطلوب داخل كلاس ApiService في ملف api_service.dart

Future<Map<String, dynamic>> checkAuth() async {
  try {
    print('🔍 بدء التحقق من حالة الجلسة...');

    final token = await _getToken();
    if (token.isEmpty) {
      return {'authenticated': false, 'message': 'لا يوجد توكن محفوظ'};
    }

    // تأكد من وجود Route في لاراول باسم api/admin/user يعيد بيانات المستخدم الحالي
    // إذا لم يتوفر، استخدم مساراً يعيد بيانات المستخدم المسجل
    final response = await _dio.get('/user'); 

    if (response.statusCode == 200 && response.data != null) {
      final userData = response.data;
      debugPrint('ApiService.checkAuth: response.data => $userData');
      debugPrint('ApiService.checkAuth: permissions => ${userData['permissions']}');
      
      // ✅ بناء كائن المستخدم بنفس هيكلة الـ Login لضمان التوافق
      final userMap = {
        'id': userData['id'],
        'name': userData['name'] ?? 'مستخدم',
        'email': userData['email'] ?? '',
        'type': userData['type'] ?? 'user', // هام جداً للتوجيه
        'permissions': userData['permissions'] ?? {},
      };

      // تحديث البيانات محلياً لضمان تحديث الصلاحيات
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(userMap));

      print('✅ تم التحقق: المستخدم هو ${userMap['type']}');

      return {
        'authenticated': true,
        'user': userMap,
      };
    }
    return {'authenticated': false};
  } on DioException catch (e) {
    print('🔴 خطأ في التحقق من التوكن: ${e.response?.statusCode}');
    // إذا كان التوكن منتهياً (401)، نمسح البيانات
    if (e.response?.statusCode == 401) {
       await _saveToken('');
       final prefs = await SharedPreferences.getInstance();
       await prefs.remove('user');
    }
    return {
      'authenticated': false,
      'message': 'انتهت صلاحية الجلسة',
    };
  } catch (e) {
    return {'authenticated': false, 'message': 'حدث خطأ غير متوقع'};
  }
}
  // ==============================
  // الموظفين
  // ==============================
Future<Map<String, dynamic>> getEmployees({String? search, int page = 1}) async {
  try {
    final response = await _dio.get(
      '/employees',
      queryParameters: {
        'search': search ?? '',
        'page': page,
        'per_page': 50,
      },
    );

    // ✅ IMPORTANT: Check if response.data is actually a Map
    if (response.data is Map<String, dynamic>) {
      return response.data;
    } else if (response.data is String) {
      return jsonDecode(response.data);
    }
    
    return response.data;
  } on DioException catch (e) {
    debugPrint('❌ getEmployees Error: ${e.response?.data}');
    return {
      'status': 'error',
      'message': 'فشل في جلب بيانات الموظفين',
      'employees': {'data': [], 'current_page': 1, 'last_page': 1, 'total': 0},
    };
  }
}

  Future<Map<String, dynamic>> getEmployee(int id) async {
    try {
      final response = await _dio.get('/employees/$id');
      if (response.data is Map<String, dynamic>) return response.data;
      if (response.data is String) return jsonDecode(response.data);
      return {'status': 'error', 'message': 'فشل في جلب بيانات الموظف'};
    } on DioException catch (e) {
      debugPrint('getEmployee error: ${e.response?.data}');
      return {'status': 'error', 'message': 'فشل في جلب الموظف'};
    }
  }

  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/employees', data: data);
      return response.data;
    } on DioException catch (e) {
      String errorMessage = 'فشل في إضافة الموظف';
      if (e.response?.data != null) {
        if (e.response!.data['errors'] != null) {
          final errors = e.response!.data['errors'];
          errorMessage = errors.values.first[0] ?? errorMessage;
        } else if (e.response!.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
      }
      return {'status': 'error', 'message': errorMessage};
    }
  }
  ///////////////////////this for batch update and batchemployees///////////////////
   // حذف جماعي للموظفين
Future<Map<String, dynamic>> batchDeleteEmployees(List<int> ids) async {
  try {
    debugPrint('📤 Sending batch delete request for IDs: $ids');

    final response = await _dio.post(
      '/employees/batch-delete', // ← بدون /admin لأن baseUrl فيها /api/admin
      data: {'ids': ids},
    );

    debugPrint('✅ Batch delete response: ${response.data}');
    return response.data;
  } on DioException catch (e) {
    debugPrint('❌ Batch delete error: ${e.response?.statusCode} - ${e.response?.data}');
    return {
      'success': false,
      'message': 'فشل في الحذف الجماعي',
    };
  }
}

  // تحديث السكن جماعي للموظفين
Future<Map<String, dynamic>> batchUpdateHousing(List<int> ids, String housingName) async {
  try {
    debugPrint('📤 Batch update housing for IDs: $ids → $housingName');
    
    final response = await _dio.post(
      '/employees/batch-update-housing', // تأكد إن البادئة /admin موجودة في baseUrl
      data: {
        'ids': ids,
        'housing_name': housingName,
      },
    );

    debugPrint('✅ Batch update housing response: ${response.data}');
    
    var message = 'تم تحديث السكن الجماعي بنجاح';
    if (response.data is Map<String, dynamic>) {
      message = response.data['message'] ?? message;
    } else if (response.data is String) {
      message = response.data.substring(0, 200); // لاختصار الـ HTML في الرسالة
      debugPrint('⚠️ رد الخادم نص HTML: $message');
    }
    
    return {
      'success': true,
      'message': message,
      'data': response.data,
    };
  } on DioException catch (e) {
    debugPrint('❌ Batch update housing error: ${e.response?.statusCode} - ${e.response?.data}');
    
    var message = 'فشل في تحديث السكن الجماعي';
    if (e.response?.data is Map<String, dynamic>) {
      message = e.response!.data['message'] ?? message;
    } else if (e.response?.data is String) {
      message = e.response!.data.substring(0, 200); // لاختصار الـ HTML
      debugPrint('⚠️ رد خطأ HTML: $message');
    }
    
    return {
      'success': false,
      'message': message,
    };
  } catch (e) {
    debugPrint('🔴 Unexpected batch update error: $e');
    return {
      'success': false,
      'message': 'حدث خطأ غير متوقع',
    };
  }
}
////////////////////this for batch update employees///////////////////

///
  // ==============================
  // تحديث موظف - الكود المعدل
  // ==============================
  Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> data) async {
    print('📤 API: Updating employee $id');
    print('📤 Original data: $data');
    
    try {
      // نسخ البيانات لمنع التعديل على البيانات الأصلية
      Map<String, dynamic> dataToSend = Map<String, dynamic>.from(data);
      
      // معالجة حقل الجنس بشكل خاص
      if (dataToSend.containsKey('gender')) {
        final genderValue = dataToSend['gender'];
        print('📤 Gender value: $genderValue (type: ${genderValue.runtimeType})');
        
        // إذا كان الجنس نصاً إنجليزياً، حوله إلى عربي
        if (genderValue == 'Male') {
          dataToSend['gender'] = 'ذكر';
          print('📤 Converted Male to ذكر');
        } else if (genderValue == 'Female') {
          dataToSend['gender'] = 'أنثى';
          print('📤 Converted Female to أنثى');
        }
      }
      
      print('📤 Final data to send: $dataToSend');
      
      final response = await _dio.put(
        '/employees/$id',
        data: dataToSend,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      print('📥 API Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        Map<String, dynamic> result;
        
        if (response.data is Map<String, dynamic>) {
          result = response.data;
        } else if (response.data is String) {
          try {
            result = json.decode(response.data);
          } catch (e) {
            result = {'data': response.data};
          }
        } else {
          result = {'data': response.data};
        }
        
        print('📥 Parsed response: $result');
        
        if (result.containsKey('status') || result.containsKey('success')) {
          print('✅ API update successful');
          return result;
        } else {
          print('⚠️ Unexpected response structure, normalizing...');
          return {
            'status': 'success',
            'message': 'تم تحديث بيانات الموظف بنجاح',
            'employee': dataToSend,
            ...result,
          };
        }
        
      } else {
        print('❌ API update failed with status: ${response.statusCode}');
        
        String errorMessage = 'فشل في تحديث بيانات الموظف';
        dynamic responseData = response.data;
        
        if (responseData != null) {
          print('📥 Error response: $responseData');
          
          if (responseData is Map) {
            if (responseData['message'] != null) {
              errorMessage = responseData['message'].toString();
            } else if (responseData['errors'] != null) {
              final errors = responseData['errors'];
              if (errors is Map && errors.isNotEmpty) {
                errorMessage = errors.values.first[0]?.toString() ?? errorMessage;
              }
            }
          } else if (responseData is String) {
            errorMessage = responseData;
          }
        }
        
        return {
          'status': 'error',
          'message': errorMessage,
        };
      }
      
    } on DioException catch (e) {
      print('🔥 DioException in updateEmployee: ${e.message}');
      print('📋 Error type: ${e.type}');
      
      String errorMessage = 'فشل في تحديث بيانات الموظف';
      
      if (e.response != null) {
        print('📋 Response status: ${e.response?.statusCode}');
        print('📋 Response data: ${e.response?.data}');
        
        if (e.response!.data != null) {
          final errorData = e.response!.data;
          
          if (errorData is Map) {
            if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            } else if (errorData['errors'] != null) {
              final errors = errorData['errors'];
              if (errors is Map && errors.isNotEmpty) {
                errorMessage = errors.values.first[0]?.toString() ?? errorMessage;
              }
            }
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'انتهت مهلة الاتصال بالخادم';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'خطأ في الاتصال بالخادم';
      }
      
      return {
        'status': 'error',
        'message': errorMessage,
        'error_type': e.type.toString(),
      };
      
    } catch (e) {
      print('🔥 General Exception in updateEmployee: $e');
      print('📋 Stack trace: ${e.toString()}');
      
      return {
        'status': 'error',
        'message': 'حدث خطأ غير متوقع: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await _dio.delete('/employees/$id');
      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ?? 'فشل في حذف الموظف',
      };
    }
  }

  // ==============================
  // المرفقات
  // ==============================
  Future<Map<String, dynamic>> getAttachments(int employeeId) async {
    try {
      final response = await _dio.get('/employees/$employeeId/attachments');
      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ?? 'فشل في جلب المرفقات',
        'attachments': [],
      };
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(int employeeId, File file) async {
    try {
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return {
          'status': 'error',
          'message': 'حجم الملف كبير جداً (الحد الأقصى 10MB)'
        };
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/employees/$employeeId/attachments',
        data: formData,
      );
      
      return response.data;
    } on DioException catch (e) {
      String errorMessage = 'فشل في رفع الملف';
      if (e.response?.data != null) {
        if (e.response!.data['errors'] != null) {
          final errors = e.response!.data['errors'];
          errorMessage = errors.values.first[0] ?? errorMessage;
        } else if (e.response!.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
      }
      return {'status': 'error', 'message': errorMessage};
    } catch (e) {
      return {'status': 'error', 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAttachment(int attachmentId) async {
    try {
      final response = await _dio.delete('/attachments/$attachmentId');
      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ?? 'فشل في حذف المرفق',
      };
    }
  }

  // ==============================
  // تحميل المرفق - الكود المعدل بناءً على Route الجديد
  // ==============================
  Future<File?> downloadAttachment(int attachmentId) async {
    try {
      print('📥 Downloading attachment $attachmentId');
      
      // طلب صلاحيات التخزين
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final permissionResult = await Permission.storage.request();
        if (!permissionResult.isGranted) {
          throw Exception('تم رفض إذن التخزين');
        }
      }
      
      // الحصول على دليل التنزيلات
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // الـ URL للتنزيل المباشر
      final downloadUrl = '${_dio.options.baseUrl.replaceFirst('/admin', '')}/employee/attachment/download/$attachmentId';
      print('📥 Download URL: $downloadUrl');
      
      final response = await _dio.get(
        '/employee/attachment/download/$attachmentId',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': '*/*',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('📥 Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      print('📥 Download response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        String fileName = 'attachment_$attachmentId';
        final contentDisposition = response.headers.value('content-disposition');
        
        if (contentDisposition != null) {
          final regex = RegExp(r'filename="([^"]+)"');
          final match = regex.firstMatch(contentDisposition);
          if (match != null) {
            fileName = match.group(1)!;
          } else {
            // محاولة استخراج الاسم بطريقة أخرى
            final regex2 = RegExp(r'filename=([^;]+)');
            final match2 = regex2.firstMatch(contentDisposition);
            if (match2 != null) {
              fileName = match2.group(1)!.trim();
            }
          }
        }
        
        // تنظيف اسم الملف
        fileName = fileName.replaceAll('"', '').trim();
        if (fileName.isEmpty) {
          fileName = 'attachment_$attachmentId';
        }
        
        final filePath = '${downloadsDir.path}/$fileName';
        final file = File(filePath);
        
        // حفظ الملف
        await file.writeAsBytes(response.data);
        
        print('✅ File downloaded: $filePath');
        print('📏 File size: ${(await file.length()) / 1024} KB');
        
        return file;
      } else {
        print('❌ Download failed with status: ${response.statusCode}');
        
        // محاولة قراءة رسالة الخطأ إذا كانت JSON
        if (response.data != null && response.data is Map) {
          final errorData = response.data as Map;
          if (errorData['message'] != null) {
            throw Exception(errorData['message']);
          }
        }
        
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
      
    } on DioException catch (e) {
      print('🔥 DioException in downloadAttachment: ${e.message}');
      print('📋 Error type: ${e.type}');
      
      if (e.response != null) {
        print('📋 Response status: ${e.response?.statusCode}');
        print('📋 Response data: ${e.response?.data}');
        
        // محاولة استخراج رسالة الخطأ
        if (e.response!.data != null) {
          if (e.response!.data is Map && e.response!.data['message'] != null) {
            throw Exception(e.response!.data['message']);
          } else if (e.response!.data is String) {
            throw Exception(e.response!.data);
          }
        }
      }
      
      throw Exception('Failed to download file: ${e.message}');
    } catch (e) {
      print('🔥 General Exception in downloadAttachment: $e');
      throw Exception('Failed to download file: $e');
    }
  }

  String getDownloadAttachmentUrl(int attachmentId) {
    return '${_dio.options.baseUrl.replaceFirst('/admin', '')}/employee/attachment/download/$attachmentId';
  }

  // ==============================
  // استيراد Excel
  // ==============================
 Future<Map<String, dynamic>> importExcel(File file) async {
  try {
    // 1. Validation: Check file size
    final fileSize = await file.length();
    if (fileSize > 50 * 1024 * 1024) {
      return {
        'status': 'error',
        'message': 'حجم الملف كبير جداً (الحد الأقصى 50MB)'
      };
    }

    // 2. Prepare Form Data (Using safe path separator)
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    // 3. Send Request
    final response = await _dio.post(
      '/employees/import',
      data: formData,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    // 4. ✅ FIX: Safely parse and return a Map
    if (response.data is Map<String, dynamic>) {
      return response.data;
    } else if (response.data is String) {
      // If server returns a raw string, decode it
      return jsonDecode(response.data);
    } else {
      // Fallback if data is unexpected
      return {
        'status': 'success',
        'message': 'تم استيراد الملف بنجاح',
        'data': response.data
      };
    }

  } on DioException catch (e) {
    debugPrint('❌ Import Dio Error: ${e.response?.statusCode}');
    String errorMessage = 'فشل في استيراد الملف';

    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['errors'] != null) {
          final errors = data['errors'];
          errorMessage = errors.values.first[0]?.toString() ?? errorMessage;
        } else if (data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
    }
    return {'status': 'error', 'message': errorMessage};
  } catch (e) {
    debugPrint('❌ Import General Error: $e');
    return {'status': 'error', 'message': 'حدث خطأ غير متوقع: $e'};
  }
}

  // ==============================
  // تصدير Excel
  // ==============================
  Future<File?> exportEmployees({String? search}) async {
    try {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final permissionResult = await Permission.storage.request();
        if (!permissionResult.isGranted) {
          throw Exception('تم رفض إذن التخزين');
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/employees_export_${search ?? 'all'}_$timestamp.xlsx';
      
      await _dio.download(
        '/employees/export',
        filePath,
        queryParameters: {'search': search ?? ''},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );
      
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      } else {
        throw Exception('فشل في إنشاء الملف');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('وظيفة التصدير غير متاحة في الخادم');
      }
      throw Exception('فشل في التصدير: ${e.message}');
    } catch (e) {
      throw Exception('فشل في التصدير: $e');
    }
  }

  // تحميل التصدير عبر المتصفح
  Future<String> getExportUrl({String? search}) async {
    final queryParams = search != null ? '?search=${Uri.encodeComponent(search)}' : '';
    return '${_dio.options.baseUrl}/employees/export$queryParams';
  }

  // ==============================
  // دالات مساعدة
  // ==============================
  
  String getAttachmentUrl(String filePath) {
    if (filePath.startsWith('http')) {
      return filePath;
    }
    
    if (filePath.startsWith('employee_attachments/')) {
      return '${_dio.options.baseUrl.replaceFirst('/api/admin', '')}/storage/$filePath';
    }
    
    return '${_dio.options.baseUrl.replaceFirst('/api/admin', '')}/storage/$filePath';
  }

  // إلغاء جميع الطلبات
  void cancelAllRequests() {
    _dio.close();
  }

  // تحديث التوكن
  Future<void> updateToken(String newToken) async {
    await _saveToken(newToken);
  }
}

// فئة مساعدة لمعالجة الأخطاء
class ApiErrorHandler {
  static String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال';
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة الإرسال';
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاستقبال';
      case DioExceptionType.badCertificate:
        return 'شهادة غير صالحة';
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 401) {
          return 'غير مصرح بالدخول';
        } else if (error.response?.statusCode == 403) {
          return 'غير مسموح بالوصول';
        } else if (error.response?.statusCode == 404) {
          return 'لم يتم العثور على المورد';
        } else if (error.response?.statusCode == 500) {
          return 'خطأ في الخادم';
        }
        return 'خطأ في الاستجابة: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب';
      case DioExceptionType.connectionError:
        return 'خطأ في الاتصال بالخادم';
      case DioExceptionType.unknown:
        return 'حدث خطأ غير معروف';
    }
  }
}
 

