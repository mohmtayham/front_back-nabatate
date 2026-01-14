import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nabtatcompany/models/meter.dart';

class MeterService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/admin';
  // أو http://10.0.2.2:8000 للاندرويد
  // أو http://localhost:8000 للويب

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer your_token', // إذا كان هناك مصادقة
  };

  // الحصول على جميع العدادات
  Future<List<Meter>> getMeters() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meters'),
        headers: _headers,
      );

      print('GET Meters Status: ${response.statusCode}');
      print('GET Meters Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<Meter> meters = [];
        
        if (data['meters'] != null) {
          for (var meterData in data['meters']) {
            meters.add(Meter.fromJson(meterData));
          }
        }
        return meters;
      } else {
        throw Exception('فشل في جلب البيانات: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMeters: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // الحصول على عداد معين
  Future<Meter> getMeter(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meters/$id'),
        headers: _headers,
      );

      print('GET Meter Status: ${response.statusCode}');
      print('GET Meter Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Meter.fromJson(data['meter']);
      } else {
        throw Exception('فشل في جلب العداد: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMeter: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // إنشاء عداد جديد - استخدام POST
  Future<Meter> createMeter(Meter meter) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meters'),
        headers: _headers,
        body: json.encode(meter.toCreateJson()),
      );

      print('POST Create Status: ${response.statusCode}');
      print('POST Create Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Meter.fromJson(data['meter'] ?? data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في إنشاء العداد: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createMeter: $e');
      throw Exception('خطأ في إنشاء العداد: $e');
    }
  }

  // تحديث عداد - استخدام PUT أو PATCH
  Future<Meter> updateMeter(int id, Meter meter) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/meters/$id'),
        headers: _headers,
        body: json.encode(meter.toUpdateJson()),
      );

      print('PUT Update Status: ${response.statusCode}');
      print('PUT Update Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Meter.fromJson(data['meter'] ?? data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في تحديث العداد: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateMeter: $e');
      throw Exception('خطأ في تحديث العداد: $e');
    }
  }

  // حذف عداد
  Future<bool> deleteMeter(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/meters/$id'),
        headers: _headers,
      );

      print('DELETE Status: ${response.statusCode}');
      print('DELETE Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['status'] == 'success' || data['success'] == true;
      } else {
        throw Exception('فشل في حذف العداد: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteMeter: $e');
      throw Exception('خطأ في حذف العداد: $e');
    }
  }
}