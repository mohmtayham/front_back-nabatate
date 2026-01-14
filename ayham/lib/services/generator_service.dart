import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as path;
import '../models/generator.dart';

class GeneratorService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/admin';

  GeneratorService();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 1. Get all generators
  Future<List<Generator>> getGenerators() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generators'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> generatorsData = data['data'];
          return generatorsData.map((json) => Generator.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch generators');
        }
      } else {
        throw Exception('Failed to fetch generators: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching generators: $e');
      rethrow;
    }
  }

  // 2. Create new generator - FIXED VERSION
  Future<Generator> createGenerator(
    Generator generator, {
    List<String>? filePaths,
  }) async {
    try {
      print('➕ Creating new generator...');
      print('📊 Data: building_id=${generator.buildingId}, housing_id=${generator.housingId}');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/generators'),
      );

      // Add required fields
      request.fields['supplier_name'] = generator.supplierName;
      request.fields['generator_name'] = generator.generatorName;
      request.fields['power_capacity'] = generator.powerCapacity;
      request.fields['monthly_rent'] = generator.monthlyRent.toString();
      request.fields['status'] = generator.status;
      
      // Add optional fields if they exist
      if (generator.yearlyTotal != null) {
        request.fields['yearly_total'] = generator.yearlyTotal!.toString();
      }
      
      if (generator.dieselConsumptionLitersPerHour != null) {
        request.fields['diesel_consumption_liters_per_hour'] = 
            generator.dieselConsumptionLitersPerHour!.toString();
      }
      
      if (generator.monthlyDieselCost != null) {
        request.fields['monthly_diesel_cost'] = generator.monthlyDieselCost!.toString();
      }
      
      // ⭐⭐⭐ FIX: Handle building_id and housing_id properly ⭐⭐⭐
      if (generator.buildingId != null && generator.buildingId! > 0) {
        request.fields['building_id'] = generator.buildingId.toString();
      } else {
        request.fields['building_id'] = ''; // Send empty string instead of null
      }
      
      if (generator.housingId != null && generator.housingId! > 0) {
        request.fields['housing_id'] = generator.housingId.toString();
      } else {
        request.fields['housing_id'] = ''; // Send empty string instead of null
      }
      
      if (generator.installationDate != null) {
        request.fields['installation_date'] = 
            generator.installationDate!.toIso8601String().split('T')[0];
      }
      
      if (generator.nextMaintenanceDate != null) {
        request.fields['next_maintenance_date'] = 
            generator.nextMaintenanceDate!.toIso8601String().split('T')[0];
      }
      
      if (generator.maintenanceIntervalDays != null) {
        request.fields['maintenance_interval_days'] = 
            generator.maintenanceIntervalDays!.toString();
      }
      
      request.fields['operating_hours'] = generator.operatingHours.toString();
      
      if (generator.notes != null && generator.notes!.isNotEmpty) {
        request.fields['notes'] = generator.notes!;
      }

      // Add files
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

      print('🚀 Sending request with building_id: ${request.fields['building_id']}');
      print('🚀 Sending request with housing_id: ${request.fields['housing_id']}');
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📡 Create status: ${response.statusCode}');
      print('📦 Create response: $responseBody');
      
      final Map<String, dynamic> responseData = json.decode(responseBody);

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          print('✅ Generator created successfully');
          return Generator.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create generator');
        }
      } else if (response.statusCode == 422) {
        final errors = responseData['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(", ")}')
            .join("\n");
        throw Exception('Invalid data:\n$errorMessages');
      } else {
        throw Exception('Failed to create generator: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error creating generator: $e');
      rethrow;
    }
  }

  // 3. Update generator - FIXED VERSION
  Future<Generator> updateGenerator(
    int id,
    Generator generator, {
    List<String>? newFilePaths,
    List<String>? filesToDelete,
  }) async {
    try {
      print('✏️ Updating generator ID: $id');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/generators/$id'),
      );

      request.fields['_method'] = 'PUT';
      request.fields['supplier_name'] = generator.supplierName;
      request.fields['generator_name'] = generator.generatorName;
      request.fields['power_capacity'] = generator.powerCapacity;
      request.fields['monthly_rent'] = generator.monthlyRent.toString();
      request.fields['status'] = generator.status;
      
      if (generator.yearlyTotal != null) {
        request.fields['yearly_total'] = generator.yearlyTotal!.toString();
      }
      
      if (generator.dieselConsumptionLitersPerHour != null) {
        request.fields['diesel_consumption_liters_per_hour'] = 
            generator.dieselConsumptionLitersPerHour!.toString();
      }
      
      if (generator.monthlyDieselCost != null) {
        request.fields['monthly_diesel_cost'] = generator.monthlyDieselCost!.toString();
      }
      
      // ⭐⭐⭐ FIX: Handle building_id and housing_id properly ⭐⭐⭐
      if (generator.buildingId != null && generator.buildingId! > 0) {
        request.fields['building_id'] = generator.buildingId.toString();
      } else {
        request.fields['building_id'] = '';
      }
      
      if (generator.housingId != null && generator.housingId! > 0) {
        request.fields['housing_id'] = generator.housingId.toString();
      } else {
        request.fields['housing_id'] = '';
      }
      
      if (generator.installationDate != null) {
        request.fields['installation_date'] = 
            generator.installationDate!.toIso8601String().split('T')[0];
      }
      
      if (generator.nextMaintenanceDate != null) {
        request.fields['next_maintenance_date'] = 
            generator.nextMaintenanceDate!.toIso8601String().split('T')[0];
      }
      
      if (generator.maintenanceIntervalDays != null) {
        request.fields['maintenance_interval_days'] = 
            generator.maintenanceIntervalDays!.toString();
      }
      
      request.fields['operating_hours'] = generator.operatingHours.toString();
      
      if (generator.notes != null && generator.notes!.isNotEmpty) {
        request.fields['notes'] = generator.notes!;
      }

      // Add new files
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

      // Add files to delete
      if (filesToDelete != null && filesToDelete.isNotEmpty) {
        request.fields['delete_attachments'] = json.encode(filesToDelete);
      }

      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      final Map<String, dynamic> responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Generator updated successfully');
          return Generator.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update generator');
        }
      } else if (response.statusCode == 422) {
        final errors = responseData['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(", ")}')
            .join("\n");
        throw Exception('Invalid data:\n$errorMessages');
      } else if (response.statusCode == 404) {
        throw Exception('Generator not found');
      } else {
        throw Exception('Failed to update generator: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error updating generator: $e');
      rethrow;
    }
  }

  // 4. Get specific generator
  Future<Generator> getGenerator(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generators/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return Generator.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch generator');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Generator not found');
      } else {
        throw Exception('Failed to fetch generator: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching generator: $e');
      rethrow;
    }
  }

  // 5. Delete generator
  Future<bool> deleteGenerator(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/generators/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 404) {
        throw Exception('Generator not found');
      } else {
        throw Exception('Failed to delete generator: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting generator: $e');
      rethrow;
    }
  }

  // 6. Get generators by building
  Future<List<Generator>> getGeneratorsByBuilding(int buildingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generators/building/$buildingId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> generatorsData = data['data'];
          return generatorsData.map((json) => Generator.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch generators');
        }
      } else {
        throw Exception('Failed to fetch generators: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching generators by building: $e');
      rethrow;
    }
  }

  // 7. Get generators by housing
  Future<List<Generator>> getGeneratorsByHousing(int housingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generators/housing/$housingId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> generatorsData = data['data'];
          return generatorsData.map((json) => Generator.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch generators');
        }
      } else {
        throw Exception('Failed to fetch generators: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching generators by housing: $e');
      rethrow;
    }
  }

  // 8. Get generators by status
  Future<List<Generator>> getGeneratorsByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generators/status/$status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> generatorsData = data['data'];
          return generatorsData.map((json) => Generator.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch generators');
        }
      } else {
        throw Exception('Failed to fetch generators: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching generators by status: $e');
      rethrow;
    }
  }

  // 9. Get generators needing maintenance
  Future<List<Generator>> getGeneratorsNeedingMaintenance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generators/needing-maintenance'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> generatorsData = data['data'];
          return generatorsData.map((json) => Generator.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch generators');
        }
      } else {
        throw Exception('Failed to fetch generators: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching generators needing maintenance: $e');
      rethrow;
    }
  }

  // 10. Upload additional attachments
  Future<Generator> uploadAttachments(
    int id,
    List<String> filePaths,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/generators/$id/upload-attachments'),
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
        if (responseData['success'] == true) {
          return Generator.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to upload files');
        }
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
      print('Error uploading files: $e');
      rethrow;
    }
  }

  // 11. Delete attachments
  Future<Generator> deleteAttachments(
    int id,
    List<String> fileNames,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generators/$id/delete-attachments'),
        headers: _headers,
        body: json.encode({'file_names': fileNames}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          return Generator.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to delete files');
        }
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
      print('Error deleting files: $e');
      rethrow;
    }
  }

  // 12. Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generators/statistics'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch statistics');
        }
      } else {
        throw Exception('Failed to fetch statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      rethrow;
    }
  }

  // 13. Mark generator for maintenance
  Future<Generator> markForMaintenance(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generators/$id/mark-maintenance'),
        headers: _headers,
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          return Generator.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to mark for maintenance');
        }
      } else {
        throw Exception('Failed to mark for maintenance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking for maintenance: $e');
      rethrow;
    }
  }

  // 14. Complete maintenance
  Future<Generator> completeMaintenance(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generators/$id/complete-maintenance'),
        headers: _headers,
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          return Generator.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to complete maintenance');
        }
      } else {
        throw Exception('Failed to complete maintenance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error completing maintenance: $e');
      rethrow;
    }
  }
}