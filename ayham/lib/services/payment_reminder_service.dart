import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as path;
import 'package:nabtatcompany/models/payment_reminder.dart';

class PaymentReminderService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/admin';

  PaymentReminderService();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 1. جلب جميع التذكيرات
  Future<List<PaymentReminder>> getReminders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-reminders'),
        headers: _headers,
      );

      print('📡 GET status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} reminders');
        return data.map((json) => PaymentReminder.fromJson(json)).toList();
      } else {
        print('❌ Failed to fetch reminders: ${response.body}');
        throw Exception('Failed to fetch reminders: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error fetching reminders: $e');
      rethrow;
    }
  }

  // 2. إنشاء تذكير جديد - الإصدار المصحح
  Future<PaymentReminder> createReminder(
    PaymentReminder reminder, {
    List<String>? filePaths,
  }) async {
    try {
      print('➕ Creating new reminder...');
      print('📊 Data: payment_status=${reminder.paymentStatus}, paidAt will be auto-set if paid');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/payment-reminders'),
      );

      // ✅ إضافة الحقول
      request.fields['housing_id'] = reminder.housingId.toString();
      
      if (reminder.buildingId != null) {
        request.fields['building_id'] = reminder.buildingId.toString();
      }
      
      request.fields['payment_type'] = reminder.paymentType;
      request.fields['due_date'] = reminder.dueDate.toIso8601String().split('T')[0];
      request.fields['amount'] = reminder.amount.toString();
      
      // ✅ إرسال payment_status كـ true/false مباشرة
      request.fields['payment_status'] = reminder.paymentStatus.toString();
      print('✅ Sending payment_status as: ${reminder.paymentStatus.toString()}');
      
      if (reminder.notes != null && reminder.notes!.isNotEmpty) {
        request.fields['notes'] = reminder.notes!;
      }

      // إضافة الملفات
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          var file = await http.MultipartFile.fromPath(
            'attachments[]',
            filePath,
            contentType: MediaType.parse(mime(path.basename(filePath)) ?? 'application/octet-stream'),
          );
          request.files.add(file);
        }
      }

      request.headers['Accept'] = 'application/json';

      print('🚀 Sending request...');
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📡 Create status: ${response.statusCode}');
      print('📦 Create response: $responseBody');
      
      final Map<String, dynamic> responseData = json.decode(responseBody);

      if (response.statusCode == 201) {
        print('✅ Reminder created successfully');
        print('📊 Response data includes paid_at: ${responseData['data']['paid_at']}');
        return PaymentReminder.fromJson(responseData['data']);
      } else if (response.statusCode == 422) {
        final errors = responseData['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(", ")}')
            .join("\n");
        throw Exception('Invalid data:\n$errorMessages');
      } else {
        throw Exception('Failed to create reminder: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error creating reminder: $e');
      rethrow;
    }
  }

  // 3. تحديث تذكير - الإصدار المصحح
  Future<PaymentReminder> updateReminder(
    int id,
    PaymentReminder reminder, {
    List<String>? newFilePaths,
    List<String>? filesToDelete,
  }) async {
    try {
      print('✏️ Updating reminder ID: $id');
      print('📊 Data: payment_status=${reminder.paymentStatus}');
      
      var request = http.MultipartRequest(
        'POST', // استخدام POST مع _method=PUT
        Uri.parse('$baseUrl/payment-reminders/$id'),
      );

      request.fields['_method'] = 'PUT';
      request.fields['housing_id'] = reminder.housingId.toString();
      
      if (reminder.buildingId != null) {
        request.fields['building_id'] = reminder.buildingId.toString();
      }
      
      request.fields['payment_type'] = reminder.paymentType;
      request.fields['due_date'] = reminder.dueDate.toIso8601String().split('T')[0];
      request.fields['amount'] = reminder.amount.toString();
      
      // ✅ إرسال payment_status كـ true/false
      request.fields['payment_status'] = reminder.paymentStatus.toString();
      print('✅ Sending payment_status as: ${reminder.paymentStatus.toString()}');
      
      if (reminder.notes != null && reminder.notes!.isNotEmpty) {
        request.fields['notes'] = reminder.notes!;
      }

      // إضافة الملفات الجديدة
      if (newFilePaths != null && newFilePaths.isNotEmpty) {
        for (var filePath in newFilePaths) {
          var file = await http.MultipartFile.fromPath(
            'attachments[]',
            filePath,
            contentType: MediaType.parse(mime(path.basename(filePath)) ?? 'application/octet-stream'),
          );
          request.files.add(file);
        }
      }

      // إضافة الملفات المراد حذفها
      if (filesToDelete != null && filesToDelete.isNotEmpty) {
        request.fields['delete_attachments'] = json.encode(filesToDelete);
      }

      request.headers['Accept'] = 'application/json';

      print('🚀 Sending update request...');
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📡 Update status: ${response.statusCode}');
      print('📦 Update response: $responseBody');
      
      final Map<String, dynamic> responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        print('✅ Reminder updated successfully');
        print('📊 Response includes paid_at: ${responseData['data']['paid_at']}');
        return PaymentReminder.fromJson(responseData['data']);
      } else if (response.statusCode == 422) {
        final errors = responseData['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(", ")}')
            .join("\n");
        throw Exception('Invalid data:\n$errorMessages');
      } else if (response.statusCode == 404) {
        throw Exception('Reminder not found');
      } else {
        throw Exception('Failed to update reminder: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error updating reminder: $e');
      rethrow;
    }
  }

  // 4. جلب تذكير معين
  Future<PaymentReminder> getReminder(int id) async {
    try {
      print('🔍 Fetching reminder ID: $id');
      
      final response = await http.get(
        Uri.parse('$baseUrl/payment-reminders/$id'),
        headers: _headers,
      );

      print('📡 Get reminder status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Received reminder with paid_at: ${data['paid_at']}');
        return PaymentReminder.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Reminder not found');
      } else {
        throw Exception('Failed to fetch reminder: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error fetching reminder: $e');
      rethrow;
    }
  }

  // 5. حذف تذكير
  Future<bool> deleteReminder(int id) async {
    try {
      print('🗑️ Deleting reminder ID: $id');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/payment-reminders/$id'),
        headers: _headers,
      );

      print('📡 Delete status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Reminder deleted successfully');
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Reminder not found');
      } else {
        throw Exception('Failed to delete reminder: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error deleting reminder: $e');
      rethrow;
    }
  }

  // 6. رفع ملفات إضافية
  Future<PaymentReminder> uploadAttachments(
    int id,
    List<String> filePaths,
  ) async {
    try {
      print('📎 Uploading additional files for reminder: $id');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/payment-reminders/$id/upload-attachments'),
      );

      for (var filePath in filePaths) {
        var file = await http.MultipartFile.fromPath(
          'attachments[]',
          filePath,
          contentType: MediaType.parse(mime(path.basename(filePath)) ?? 'application/octet-stream'),
        );
        request.files.add(file);
      }

      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      final Map<String, dynamic> responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        print('✅ Files uploaded successfully');
        return PaymentReminder.fromJson(responseData['data']);
      } else if (response.statusCode == 422) {
        final errors = responseData['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(", ")}')
            .join("\n");
        throw Exception('Invalid data:\n$errorMessages');
      } else {
        throw Exception('Failed to upload files: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error uploading files: $e');
      rethrow;
    }
  }

  // 7. حذف ملفات معينة
  Future<PaymentReminder> deleteAttachments(
    int id,
    List<String> fileNames,
  ) async {
    try {
      print('🗑️ Deleting files from reminder: $id');
      
      final response = await http.post(
        Uri.parse('$baseUrl/payment-reminders/$id/delete-attachments'),
        headers: _headers,
        body: json.encode({'file_names': fileNames}),
      );

      print('📡 Delete attachments status: ${response.statusCode}');
      
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Files deleted successfully');
        return PaymentReminder.fromJson(responseData['data']);
      } else if (response.statusCode == 422) {
        final errors = responseData['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(", ")}')
            .join("\n");
        throw Exception('Invalid data:\n$errorMessages');
      } else {
        throw Exception('Failed to delete files: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error deleting files: $e');
      rethrow;
    }
  }

  // 8. تحميل ملف معين
  Future<String> downloadAttachment(
    int id,
    String fileName,
    String savePath,
  ) async {
    try {
      print('⬇️ Downloading file: $fileName from reminder: $id');
      
      final response = await http.get(
        Uri.parse('$baseUrl/payment-reminders/$id/download/$fileName'),
      );

      if (response.statusCode == 200) {
        print('✅ File downloaded successfully');
        return savePath;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error downloading file: $e');
      rethrow;
    }
  }

  // 9. الحصول على الملفات المرفقة
  Future<List<Map<String, dynamic>>> getAttachments(int id) async {
    try {
      print('📎 Fetching attachments for reminder: $id');
      
      final response = await http.get(
        Uri.parse('$baseUrl/payment-reminders/$id/attachments'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Fetched ${(data['attachments'] as List).length} files');
        return List<Map<String, dynamic>>.from(data['attachments'] ?? []);
      } else {
        throw Exception('Failed to fetch files: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error fetching attachments: $e');
      rethrow;
    }
  }

  // 10. ✅ طريقة بديلة باستخدام JSON مباشرة
  Future<PaymentReminder> createReminderJson(PaymentReminder reminder) async {
    try {
      print('➕ Creating reminder using JSON...');
      
      Map<String, dynamic> data = {
        'housing_id': reminder.housingId,
        'building_id': reminder.buildingId,
        'payment_type': reminder.paymentType,
        'due_date': reminder.dueDate.toIso8601String().split('T')[0],
        'amount': reminder.amount,
        'payment_status': reminder.paymentStatus,
        'notes': reminder.notes,
      };

      print('📤 Sending JSON data: ${json.encode(data)}');

      final response = await http.post(
        Uri.parse('$baseUrl/payment-reminders'),
        headers: _headers,
        body: json.encode(data),
      );

      print('📡 JSON Create status: ${response.statusCode}');
      print('📦 JSON Create response: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ Reminder created successfully via JSON');
        return PaymentReminder.fromJson(responseData['data']);
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final errors = errorData['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(", ")}')
            .join("\n");
        throw Exception('Invalid data:\n$errorMessages');
      } else {
        throw Exception('Failed to create reminder: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 JSON Error: $e');
      rethrow;
    }
  }

  // 11. ✅ جلب التذكيرات المدفوعة
  Future<List<PaymentReminder>> getPaidReminders() async {
    try {
      print('💰 Fetching paid reminders...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/payment-reminders/status/paid'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} paid reminders');
        return data.map((json) => PaymentReminder.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch paid reminders: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error fetching paid reminders: $e');
      rethrow;
    }
  }

  // 12. ✅ جلب التذكيرات غير المدفوعة
  Future<List<PaymentReminder>> getUnpaidReminders() async {
    try {
      print('💸 Fetching unpaid reminders...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/payment-reminders/status/unpaid'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} unpaid reminders');
        return data.map((json) => PaymentReminder.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch unpaid reminders: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error fetching unpaid reminders: $e');
      rethrow;
    }
  }

  // 13. ✅ وضع علامة دفع على تذكير
  Future<PaymentReminder> markAsPaid(int id) async {
    try {
      print('✅ Marking reminder $id as paid...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/payment-reminders/$id/mark-paid'),
        headers: _headers,
      );

      print('📡 Mark as paid status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Reminder marked as paid with paid_at: ${data['data']['paid_at']}');
        return PaymentReminder.fromJson(data['data']);
      } else {
        throw Exception('Failed to mark as paid: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error marking as paid: $e');
      rethrow;
    }
  }

  // 14. ✅ إزالة علامة الدفع من تذكير
  Future<PaymentReminder> markAsUnpaid(int id) async {
    try {
      print('❌ Marking reminder $id as unpaid...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/payment-reminders/$id/mark-unpaid'),
        headers: _headers,
      );

      print('📡 Mark as unpaid status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Reminder marked as unpaid');
        return PaymentReminder.fromJson(data['data']);
      } else {
        throw Exception('Failed to mark as unpaid: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error marking as unpaid: $e');
      rethrow;
    }
  }
}