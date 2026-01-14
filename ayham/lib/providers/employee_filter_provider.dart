// lib/providers/employee_filter_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/filter_service.dart';

class EmployeeFilterProvider extends ChangeNotifier {
  // البيانات الأساسية
  Map<String, dynamic> _filterOptions = {};
  List<dynamic> _filteredEmployees = [];
  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedBuilding;
  Map<String, dynamic>? _selectedHousing;
  Map<String, dynamic>? _selectedContractType;
  String? _searchQuery;
  String? _sortBy;
  String? _sortOrder = 'desc';
  bool _isDisposed = false;
  // حالات التحميل
  bool _loading = false;
  bool _loadingOptions = false;
  bool _loadingRealData = false;
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = 20;
  int _totalEmployees = 0;
  
  // الإحصائيات
  Map<String, dynamic> _contractStats = {};
  
  // البيانات الحقيقية من قاعدة البيانات
  List<Map<String, dynamic>> _realProjects = [];
  List<Map<String, dynamic>> _realBuildings = [];
  List<Map<String, dynamic>> _realHousings = [];
  List<Map<String, dynamic>> _realJobTitles = [];
  List<Map<String, dynamic>> _realContractTypes = [];

  // ==================== Getters ====================
  Map<String, dynamic> get filterOptions => _filterOptions;
  List<dynamic> get filteredEmployees => _filteredEmployees;
  bool get loading => _loading;
  bool get loadingOptions => _loadingOptions;
  bool get loadingRealData => _loadingRealData;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get perPage => _perPage;
  int get totalEmployees => _totalEmployees;
  Map<String, dynamic> get contractStats => _contractStats;
  
  List<Map<String, dynamic>> get realProjects => _realProjects;
  List<Map<String, dynamic>> get realBuildings => _realBuildings;
  List<Map<String, dynamic>> get realHousings => _realHousings;
  List<Map<String, dynamic>> get realJobTitles => _realJobTitles;
  List<Map<String, dynamic>> get realContractTypes => _realContractTypes;
  
  Map<String, dynamic>? get selectedProject => _selectedProject;
  Map<String, dynamic>? get selectedBuilding => _selectedBuilding;
  Map<String, dynamic>? get selectedHousing => _selectedHousing;
  Map<String, dynamic>? get selectedContractType => _selectedContractType;
  String? get searchQuery => _searchQuery;
  
  String get activeFilters {
    final filters = <String>[];
    if (_selectedProject != null && _selectedProject!['name'] != null) {
      filters.add('المشروع: ${_selectedProject!['name']}');
    }
    if (_selectedBuilding != null && _selectedBuilding!['name'] != null) {
      filters.add('المبنى: ${_selectedBuilding!['name']}');
    }
    if (_selectedHousing != null && _selectedHousing!['name'] != null) {
      filters.add('السكن: ${_selectedHousing!['name']}');
    }
    if (_selectedContractType != null && _selectedContractType!['name'] != null) {
      filters.add('العقد: ${_selectedContractType!['name']}');
    }
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filters.add('بحث: $_searchQuery');
    }
    return filters.join(' | ');
  }

  // ==================== جلب البيانات ====================
  
  Future<void> fetchAllData() async {
    try {
      print('🔄 جلب جميع البيانات...');
      
      // جلب البيانات بالتوازي
      await Future.wait([
        fetchFilterOptions(),
        fetchRealData(),
      ]);
      
      print('✅ تم جلب جميع البيانات بنجاح');
    } catch (e) {
      print('❌ خطأ في جلب البيانات: $e');
    }
  }
  
  Future<void> fetchFilterOptions() async {
    try {
      _loadingOptions = true;
      notifyListeners();
      
      final result = await FilterService.getEnhancedFilterOptions();
      
      if (result['status'] == 'success') {
        _filterOptions = result['filters'];
        print('✅ تم جلب خيارات الفلترة: ${_filterOptions.keys}');
      }
      
      _loadingOptions = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في جلب خيارات الفلترة: $e');
      _loadingOptions = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> fetchRealData() async {
    try {
      _loadingRealData = true;
      notifyListeners();
      
      print('🔄 جلب البيانات الحقيقية...');
      
      // جلب البيانات الحقيقية بالتوازي
      final results = await Future.wait([
        FilterService.getRealFilterData('project_name'),
        FilterService.getRealFilterData('building_id'),
        FilterService.getRealFilterData('housing_name'),
        FilterService.getRealFilterData('job_title'),
        FilterService.getRealFilterData('contract_id'),
      ]);
      
      _realProjects = results[0];
      _realBuildings = results[1];
      _realHousings = results[2];
      _realJobTitles = results[3];
      _realContractTypes = results[4];
      
      // إضافة خيار "الكل" لكل قائمة
      _addAllOptionToLists();
      
      print('✅ البيانات الحقيقية:');
      print('   - المشاريع: ${_realProjects.length}');
      print('   - المباني: ${_realBuildings.length}');
      print('   - المساكن: ${_realHousings.length}');
      
      _loadingRealData = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في جلب البيانات الحقيقية: $e');
      _loadingRealData = false;
      notifyListeners();
    }
  }
  
  void _addAllOptionToLists() {
    // إضافة خيار "الكل" لكل قائمة
    if (_realProjects.isNotEmpty) {
      _realProjects.insert(0, {
        'id': null,
        'name': 'كل المشاريع',
        'value': '',
        'display_name': 'كل المشاريع'
      });
    }
    
    if (_realBuildings.isNotEmpty) {
      _realBuildings.insert(0, {
        'id': null,
        'name': 'كل المباني',
        'value': '',
        'display_name': 'كل المباني'
      });
    }
    
    if (_realHousings.isNotEmpty) {
      _realHousings.insert(0, {
        'id': null,
        'name': 'كل المساكن',
        'value': '',
        'display_name': 'كل المساكن'
      });
    }
    
    if (_realContractTypes.isNotEmpty) {
      _realContractTypes.insert(0, {
        'id': null,
        'name': 'كل أنواع العقود',
        'value': '',
        'display_name': 'كل أنواع العقود'
      });
    }
  }
  
  // ==================== البحث ====================
  
  Future<void> searchWithFilters({
    int? page,
    bool reset = false,
  }) async {
    try {
      _loading = true;
      if (reset) _currentPage = 1;
      final currentPage = page ?? _currentPage;
      
      notifyListeners();
      
      print('🔍 البحث مع الفلاتر:');
      print('   - بحث: $_searchQuery');
      print('   - مشروع: ${_selectedProject?['value']}');
      print('   - مبنى: ${_selectedBuilding?['value']}');
      print('   - سكن: ${_selectedHousing?['value']}');
      print('   - عقد: ${_selectedContractType?['value']}');
      print('   - ترتيب: $_sortBy');
      print('   - صفحة: $currentPage');
      
      final result = await FilterService.searchWithFilters(
        search: _searchQuery,
        projectName: _selectedProject?['value']?.toString(),
        buildingId: _selectedBuilding?['value']?.toString(),
        housingName: _selectedHousing?['value']?.toString(),
        contractId: _selectedContractType?['value']?.toString(),
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        page: currentPage,
        perPage: _perPage,
      );
      
      print('📊 استجابة الـ API: ${jsonEncode(result).substring(0, 200)}...');
      
      if (result['status'] == 'success') {
        _filteredEmployees = result['employees']['data'] ?? [];
        _totalEmployees = result['total'] ?? 0;
        _contractStats = result['contract_stats'] ?? {};
        _currentPage = result['current_page'] ?? 1;
        _lastPage = result['last_page'] ?? 1;
        _perPage = result['per_page'] ?? 20;
        
        print('✅ تم تحميل ${_filteredEmployees.length} موظف');
        print('   - الإجمالي: $_totalEmployees');
        print('   - الصفحات: $_lastPage');
        
        if (_filteredEmployees.isNotEmpty) {
          print('   - عينة: ${_filteredEmployees.first['id_name']}');
        }
      } else {
        print('❌ الـ API أرجع خطأ: ${result['message']}');
      }
      
      _loading = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // ==================== إدارة الفلاتر ====================
  
  void updateFilter({
    Map<String, dynamic>? project,
    Map<String, dynamic>? building,
    Map<String, dynamic>? housing,
    Map<String, dynamic>? contractType,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
  }) {
    if (project != null) _selectedProject = project;
    if (building != null) _selectedBuilding = building;
    if (housing != null) _selectedHousing = housing;
    if (contractType != null) _selectedContractType = contractType;
    if (searchQuery != null) _searchQuery = searchQuery;
    if (sortBy != null) _sortBy = sortBy;
    if (sortOrder != null) _sortOrder = sortOrder;
    
    print('🔄 تحديث الفلاتر:');
    print('   المشروع: ${_selectedProject?['name']}');
    print('   المبنى: ${_selectedBuilding?['name']}');
    print('   السكن: ${_selectedHousing?['name']}');
    print('   العقد: ${_selectedContractType?['name']}');
    print('   البحث: $_searchQuery');
    
    notifyListeners();
  }
  
  void clearFilters() {
    _selectedProject = null;
    _selectedBuilding = null;
    _selectedHousing = null;
    _selectedContractType = null;
    _searchQuery = null;
    _sortBy = null;
    _sortOrder = 'desc';
    _currentPage = 1;
    
    print('🧹 تم مسح جميع الفلاتر');
    
    notifyListeners();
  }
  @override
void dispose() {
  _isDisposed = true;
  super.dispose();
}

@override
void notifyListeners() {
  if (!_isDisposed) {
    super.notifyListeners();
  }
}
  
  void changePage(int page) {
    if (page >= 1 && page <= _lastPage) {
      _currentPage = page;
      searchWithFilters(page: page);
    }
  }
  
  bool get hasActiveFilters {
    return _selectedProject != null ||
           _selectedBuilding != null ||
           _selectedHousing != null ||
           _selectedContractType != null ||
           (_searchQuery != null && _searchQuery!.isNotEmpty);
  }
  
  void resetPagination() {
    _currentPage = 1;
    notifyListeners();
  }
}