import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:nabtatcompany/services/api_service.dart';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

class EmployeeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // غيّرنا النوع من List<dynamic> إلى List<Map<String, dynamic>> لتجنب أخطاء النوع
  List<Map<String, dynamic>> _employees = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  String _search = '';
  bool _loading = false;
  bool _exporting = false;
  bool _importing = false;

  // Getters
  List<Map<String, dynamic>> get employees => _employees;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalItems => _totalItems;
  String get search => _search;
  bool get loading => _loading;
  bool get exporting => _exporting;
  bool get importing => _importing;

  // ==============================
  // جلب الموظفين
  // ==============================
  Future<void> fetchEmployees({int page = 1}) async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    try {
      debugPrint('🔄 Fetching employees page $page, search: $_search');
      final res = await _apiService.getEmployees(search: _search, page: page);

      debugPrint('📥 API Response: $res');

      if (res['status'] == 'success' || res['success'] == true) {
        // تحويل البيانات للنوع الصحيح
        _employees = List<Map<String, dynamic>>.from(res['employees']['data'] ?? []);
        _currentPage = res['employees']['current_page'] ?? 1;
        _lastPage = res['employees']['last_page'] ?? 1;
        _totalItems = res['employees']['total'] ?? 0;

        debugPrint('✅ Loaded ${_employees.length} employees');
      } else {
        final errorMsg = res['message'] ?? 'Failed to load employees';
        debugPrint('❌ Error: $errorMsg');
        _showError(errorMsg);
      }
    } catch (e) {
      debugPrint('🔥 Exception: $e');
      _showError('Error: $e');
      _employees = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ==============================
  // البحث
  // ==============================
  void searchEmployees(String value) {
    _search = value.trim();
    fetchEmployees(page: 1);
  }

  void clearSearch() {
    _search = '';
    fetchEmployees(page: 1);
  }

  // ==============================
  // إضافة موظف
  // ==============================
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      debugPrint('➕ Creating employee with data: $data');
      final result = await _apiService.createEmployee(data);

      debugPrint('📥 Create response: $result');

      if (result['status'] == 'success' || result['success'] == true) {
        _showSuccess('Employee created successfully');
        await fetchEmployees(page: _currentPage);
        return {'success': true, 'message': 'Employee created successfully'};
      } else {
        final errorMsg = result['message'] ?? 'Failed to create employee';
        _showError(errorMsg);
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('🔥 Create error: $e');
      _showError('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================
  // تحديث موظف
  // ==============================
  Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      debugPrint('✏️ Updating employee $id with data: $data');
      final result = await _apiService.updateEmployee(id, data);

      debugPrint('📥 Update response: $result');

      if (result['status'] == 'success' || result['success'] == true) {
        _showSuccess('Employee updated successfully');

        // تحديث الموظف في القائمة المحلية
        final index = _employees.indexWhere((emp) => emp['id'] == id);
        if (index != -1) {
          _employees[index] = {
            ..._employees[index],
            ...data,
            'id': id,
          };
          notifyListeners();
          debugPrint('🔄 Updated employee in local list');
        }

        await fetchEmployees(page: _currentPage);

        return {'success': true, 'message': 'Employee updated successfully'};
      } else {
        final errorMsg = result['message'] ?? 'Failed to update employee';
        _showError(errorMsg);
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('🔥 Update error: $e');
      _showError('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================
  // حذف موظف
  // ==============================
  Future<Map<String, dynamic>> deleteEmployee(int id, String name) async {
    try {
      debugPrint('🗑️ Deleting employee $id ($name)');
      final result = await _apiService.deleteEmployee(id);

      debugPrint('📥 Delete response: $result');

      if (result['status'] == 'success' || result['success'] == true) {
        _showSuccess('Employee deleted successfully');

        _employees.removeWhere((emp) => emp['id'] == id);
        _totalItems = _totalItems > 0 ? _totalItems - 1 : 0;
        notifyListeners();

        debugPrint('🔄 Removed employee from local list');

        return {'success': true, 'message': 'Employee deleted successfully'};
      } else {
        final errorMsg = result['message'] ?? 'Failed to delete employee';
        _showError(errorMsg);
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('🔥 Delete error: $e');
      _showError('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================
  // حذف جماعي للموظفين (جديد)
  // ==============================
  Future<void> batchDeleteEmployees(List<int> ids) async {
    if (ids.isEmpty) return;

    try {
      debugPrint('📤 Sending batch delete for IDs: $ids');
      final result = await _apiService.batchDeleteEmployees(ids);

      if (result['success'] == true) {
        _showSuccess(result['message'] ?? 'تم الحذف الجماعي بنجاح');
        await fetchEmployees(page: _currentPage);
      } else {
        _showError(result['message'] ?? 'فشل في الحذف الجماعي');
      }
    } catch (e) {
      debugPrint('🔥 Batch delete error: $e');
      _showError('حدث خطأ أثناء الحذف الجماعي');
    }
  }

  // ==============================
  // تحديث السكن جماعي للموظفين (جديد)
  // ==============================
  Future<void> batchUpdateHousing(List<int> ids, String housingName) async {
    if (ids.isEmpty || housingName.trim().isEmpty) return;

    try {
      debugPrint('📤 Updating housing for IDs: $ids → $housingName');
      final result = await _apiService.batchUpdateHousing(ids, housingName);

      if (result['success'] == true) {
        _showSuccess(result['message'] ?? 'تم تحديث السكن بنجاح');
        await fetchEmployees(page: _currentPage);
      } else {
        _showError(result['message'] ?? 'فشل في تحديث السكن');
      }
    } catch (e) {
      debugPrint('🔥 Batch housing update error: $e');
      _showError('حدث خطأ أثناء تحديث السكن');
    }
  }

  // ==============================
  // المرفقات
  // ==============================
  Future<List<dynamic>> getAttachments(int employeeId) async {
    try {
      debugPrint('📎 Getting attachments for employee $employeeId');
      final result = await _apiService.getAttachments(employeeId);

      if (result['status'] == 'success' || result['success'] == true) {
        return result['attachments'] ?? [];
      } else {
        final errorMsg = result['message'] ?? 'Failed to load attachments';
        debugPrint('❌ Error: $errorMsg');
        return [];
      }
    } catch (e) {
      debugPrint('🔥 Get attachments error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(int employeeId, File file) async {
    try {
      debugPrint('📤 Uploading attachment for employee $employeeId');
      debugPrint('📄 File: ${file.path}, size: ${await file.length()} bytes');

      final result = await _apiService.uploadAttachment(employeeId, file);

      debugPrint('📥 Upload response: $result');

      if (result['status'] == 'success' || result['success'] == true) {
        _showSuccess('File uploaded successfully');
        return {'success': true, 'message': 'File uploaded successfully'};
      } else {
        final errorMsg = result['message'] ?? 'Failed to upload file';
        _showError(errorMsg);
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('🔥 Upload error: $e');
      _showError('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAttachment(int attachmentId) async {
    try {
      debugPrint('🗑️ Deleting attachment $attachmentId');
      final result = await _apiService.deleteAttachment(attachmentId);

      if (result['status'] == 'success' || result['success'] == true) {
        _showSuccess('Attachment deleted successfully');
        return {'success': true, 'message': 'Attachment deleted successfully'};
      } else {
        final errorMsg = result['message'] ?? 'Failed to delete attachment';
        _showError(errorMsg);
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('🔥 Delete attachment error: $e');
      _showError('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================
  // تحميل المرفق
  // ==============================
  Future<File> downloadAttachment(int attachmentId) async {
    try {
      debugPrint('📥 EmployeeProvider: Downloading attachment $attachmentId');

      final file = await _apiService.downloadAttachment(attachmentId);

      if (file != null) {
        debugPrint('✅ EmployeeProvider: Attachment downloaded: ${file.path}');
        _showSuccess('File downloaded successfully');
        return file;
      } else {
        debugPrint('❌ EmployeeProvider: Download failed, file is null');
        throw Exception('Failed to download file');
      }
    } catch (e) {
      debugPrint('🔥 EmployeeProvider: Download error: $e');
      _showError('Error downloading file: $e');
      rethrow;
    }
  }

  // ==============================
  // استيراد Excel
  // ==============================
  Future<void> importExcel() async {
    _importing = true;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        dialogTitle: 'Select Excel File',
        allowCompression: true,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        debugPrint('📤 Importing Excel file: ${file.path}');

        if (await file.length() > 50 * 1024 * 1024) {
          _showError('File too large (max 50MB)');
          return;
        }

        final importResult = await _apiService.importExcel(file);

        debugPrint('📥 Import response: $importResult');

        if (importResult['status'] == 'success' || importResult['success'] == true) {
          await fetchEmployees(page: _currentPage);
          _showSuccess('File imported successfully');
        } else {
          final errorMsg = importResult['message'] ?? 'Failed to import file';
          _showError(errorMsg);
        }
      }
    } catch (e) {
      debugPrint('🔥 Import error: $e');
      _showError('Error: $e');
    } finally {
      _importing = false;
      notifyListeners();
    }
  }

  // ==============================
  // تصدير Excel
  // ==============================
  Future<void> exportExcel() async {
    _exporting = true;
    notifyListeners();

    try {
      debugPrint('📤 Exporting employees (search: $_search)');

      final file = await _apiService.exportEmployees(search: _search.isEmpty ? null : _search);

      if (file != null) {
        debugPrint('✅ File downloaded: ${file.path}');
        await OpenFile.open(file.path);
        _showSuccess('Export completed successfully');
      } else {
        _showError('Export failed');
      }
    } catch (e) {
      debugPrint('🔥 Export error: $e');
      _showError('Export error');
    } finally {
      _exporting = false;
      notifyListeners();
    }
  }

  // ==============================
  // مساعدات
  // ==============================
  void _showSuccess(String message) {
    debugPrint('✅ $message');
  }

  void _showError(String message) {
    debugPrint('❌ $message');
  }

  String getAttachmentUrl(String filePath) {
    return _apiService.getAttachmentUrl(filePath);
  }
}