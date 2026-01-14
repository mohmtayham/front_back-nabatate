
import '../models/housing_model.dart';
import '../models/building_model.dart';
import '../models/room_model.dart';
import '../models/project_model.dart';
import 'housing_service.dart';
import 'building_service.dart';
import 'room_service.dart';
import 'project_service.dart';
class RelationService {
 
  static Future<List<Housing>> getAllHousings() async {
    try {
      print('📡 جلب المساكن عبر HousingService');
      return await HousingService.getHousings();
    } catch (e) {
      print('❌ خطأ في جلب المساكن: $e');
      return [];
    }
  }

  static Future<List<Building>> getAllBuildings() async {
    try {
      print('📡 جلب المباني عبر BuildingService');
      return await BuildingService.getBuildings();
    } catch (e) {
      print('❌ خطأ في جلب المباني: $e');
      return [];
    }
  }

  static Future<List<Building>> getBuildingsByHousing(int housingId) async {
    try {
      print('📡 جلب مباني السكن $housingId');

      final allBuildings = await BuildingService.getBuildings();
      final filteredBuildings = allBuildings
          .where((building) => building.housingId == housingId)
          .toList();
      
      print('✅ تم تصفية ${filteredBuildings.length} مبنى للسكن $housingId');
      return filteredBuildings;
      
    } catch (e) {
      print('❌ خطأ في جلب مباني السكن: $e');
      return [];
    }
  }
  static Future<List<Room>> getAllRooms() async {
    try {
      print('📡 جلب الغرف عبر RoomService');
      return await RoomService.getRooms();
    } catch (e) {
      print('❌ خطأ في جلب الغرف: $e');
      return [];
    }
  }

  static Future<List<Room>> getRoomsByBuilding(int buildingId) async {
    try {
      print('📡 جلب غرف المبنى $buildingId عبر RoomService');
      return await RoomService.getRooms(buildingId: buildingId);
    } catch (e) {
      print('❌ خطأ في جلب غرف المبنى: $e');
      return [];
    }
  }

  static Future<List<Project>> getAllProjects() async {
    try {
      print('📡 جلب المشاريع عبر ProjectService');
 
      return await ProjectService.getProjects();
    } catch (e) {
      print('❌ خطأ في جلب المشاريع: $e');
      return [];
    }
  }
}