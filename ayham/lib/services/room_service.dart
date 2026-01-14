import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room_model.dart';

class RoomService {
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

  static Future<List<Room>> getRooms({int? buildingId}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/admin/rooms';
      
      if (buildingId != null) {
        url += '?building_id=$buildingId';
      }
      
      print('Fetching rooms from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Get Rooms Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> roomList = data['rooms'] ?? data['data'] ?? [];
        
        print('Successfully fetched ${roomList.length} rooms');
        
        return roomList.map((roomJson) {
          return Room.fromJson(roomJson);
        }).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('فشل في جلب الغرف: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getRooms: $e');
      throw Exception('خطأ في الاتصال بالخادم: $e');
    }
  }

  static Future<Room> addRoom({
    required String name,
    required int buildingId,
    int? bedsCount,
    int? residentsCount,
    required String status,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'name': name,
        'building_id': buildingId,
        'status': status,
      };
      
      if (bedsCount != null) {
        body['beds_count'] = bedsCount;
      }
      
      if (residentsCount != null) {
        body['residents_count'] = residentsCount;
      }
      
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      
      print('Adding room with data: $body');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/rooms'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Add Room Status: ${response.statusCode}');
      print('Add Room Body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Room.fromJson(data['room']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'فشل في إضافة الغرفة');
      }
    } catch (e) {
      print('Error in addRoom: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<Room> updateRoom({
    required int id,
    required String name,
    required int buildingId,
    int? bedsCount,
    int? residentsCount,
    required String status,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'name': name,
        'building_id': buildingId,
        'status': status,
      };
      
      if (bedsCount != null) {
        body['beds_count'] = bedsCount;
      }
      
      if (residentsCount != null) {
        body['residents_count'] = residentsCount;
      }
      
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      
      print('Updating room $id with data: $body');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/rooms/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Update Room Status: ${response.statusCode}');
      print('Update Room Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Room.fromJson(data['room']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في تحديث الغرفة');
      }
    } catch (e) {
      print('Error in updateRoom: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<void> deleteRoom(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/rooms/$id'),
        headers: headers,
      );

      print('Delete Room Status: ${response.statusCode}');
      print('Delete Room Body: ${response.body}');
      
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في حذف الغرفة');
      }
    } catch (e) {
      print('Error in deleteRoom: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }
}