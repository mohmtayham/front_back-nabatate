// lib/screens/employees/employee_filter_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nabtatcompany/providers/employee_filter_provider.dart';
import 'package:nabtatcompany/services/auth_service.dart';  // غيّر المسار حسب موقع الملف الفعلي
import 'package:nabtatcompany/providers/auth_provider.dart';
import 'package:nabtatcompany/generated/l10n.dart';

class EmployeeFilterScreen extends StatefulWidget {
  const EmployeeFilterScreen({super.key});

  @override
  State<EmployeeFilterScreen> createState() => _EmployeeFilterScreenState();
}

class _EmployeeFilterScreenState extends State<EmployeeFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSortBy;
  final ScrollController _scrollController = ScrollController();
  bool _isAuthorized = false;
bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _checkAccess();
  }
  Future<void> _checkAccess() async {
  // Check permission once before doing anything else
  final hasAccess = await AuthService.can('employee', 'read');
  
  if (!mounted) return;

  setState(() {
    _isAuthorized = hasAccess;
    _isLoading = false;
  });

  if (hasAccess) {
    _initializeFilters();
  }
}




 // lib/screens/employees/employee_filter_screen.dart

void _initializeFilters() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Check if mounted before starting
    if (!mounted) return; 

    final provider = Provider.of<EmployeeFilterProvider>(context, listen: false);
    await provider.fetchAllData();

    // 🔥 FIX: Check if mounted AGAIN after the await
    if (mounted) {
      provider.searchWithFilters();
    }
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeeFilterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).filterEmployeesTitle),
        centerTitle: true,
        actions: [
          if (provider.hasActiveFilters)
            IconButton(
              onPressed: () {
                provider.clearFilters();
                _searchController.clear();
                setState(() => _selectedSortBy = null);
              },
              icon: const Icon(Icons.filter_alt_off),
              tooltip: S.of(context).clearFilters,
            ),
          IconButton(
            onPressed: () => provider.searchWithFilters(reset: true),
            icon: const Icon(Icons.search),
            tooltip: S.of(context).search,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // شريط البحث
            _buildSearchBar(provider),
            
            // الفلاتر
            _buildFiltersRow(provider),
            
            // الفلاتر النشطة
            if (provider.activeFilters.isNotEmpty)
              _buildActiveFilters(provider),
            
            // الإحصائيات
            _buildStatistics(provider),
            
            // قائمة الموظفين
            Expanded(
              child: _buildEmployeeList(provider),
            ),
            
            // الباجناشن
            if (provider.filteredEmployees.isNotEmpty && provider.lastPage > 1)
              _buildPagination(provider),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => provider.searchWithFilters(reset: true),
        child: const Icon(Icons.search),
        tooltip: S.of(context).search,
      ),
    );
  }

  // ==================== مكونات الواجهة ====================

  Widget _buildSearchBar(EmployeeFilterProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: S.of(context).searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: () {
              _searchController.clear();
              provider.updateFilter(searchQuery: null);
              provider.searchWithFilters(reset: true);
            },
            icon: const Icon(Icons.clear),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          provider.updateFilter(searchQuery: value);
          Future.delayed(const Duration(milliseconds: 800), () {
            if (_searchController.text == value) {
              provider.searchWithFilters(reset: true);
            }
          });
        },
        onSubmitted: (value) => provider.searchWithFilters(reset: true),
      ),
    );
  }

  Widget _buildFiltersRow(EmployeeFilterProvider provider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Row(
          children: [
            const SizedBox(width: 8),
            
            // فلتر المشروع - من البيانات الحقيقية
            if (provider.realProjects.isNotEmpty)
              _buildProjectFilter(provider),
            
            const SizedBox(width: 8),
            
            // فلتر المبنى - من البيانات الحقيقية
            if (provider.realBuildings.isNotEmpty)
              _buildBuildingFilter(provider),
            
            const SizedBox(width: 8),
            
            // فلتر السكن - من البيانات الحقيقية
            if (provider.realHousings.isNotEmpty)
              _buildHousingFilter(provider),
            
            const SizedBox(width: 8),
            
            // فلتر نوع العقد - من البيانات الحقيقية
            if (provider.realContractTypes.isNotEmpty)
              _buildContractTypeFilter(provider),
            
            const SizedBox(width: 8),
            
            // فلتر الترتيب
            _buildSortFilter(),
            
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(EmployeeFilterProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                provider.activeFilters,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(EmployeeFilterProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('إجمالي', provider.totalEmployees.toString(), Colors.blue),
          _buildStatCard('الصفحة', '${provider.currentPage}/${provider.lastPage}', Colors.red),
          if (provider.contractStats.isNotEmpty)
            ..._buildContractStatsCards(provider),
        ],
      ),
    );
  }

  List<Widget> _buildContractStatsCards(EmployeeFilterProvider provider) {
    final stats = provider.contractStats;
    final widgets = <Widget>[];
    
    if (stats['original'] != null && stats['original'] > 0) {
      widgets.add(_buildStatCard('أصلي', stats['original'].toString(), Colors.green));
    }
    if (stats['rental'] != null && stats['rental'] > 0) {
      widgets.add(_buildStatCard('إيجار', stats['rental'].toString(), Colors.orange));
    }
    if (stats['external'] != null && stats['external'] > 0) {
      widgets.add(_buildStatCard('خارجي', stats['external'].toString(), Colors.purple));
    }
    
    return widgets;
  }

  Widget _buildEmployeeList(EmployeeFilterProvider provider) {
    if (provider.loadingOptions || provider.loadingRealData) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.filteredEmployees.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await provider.searchWithFilters(reset: true);
      },
      child: ListView.builder(
        itemCount: provider.filteredEmployees.length,
        itemBuilder: (context, index) {
          final employee = provider.filteredEmployees[index];
          return _buildEmployeeCard(employee);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            'جرب تغيير معايير البحث',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(EmployeeFilterProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: provider.currentPage > 1
                ? () => provider.changePage(provider.currentPage - 1)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'الصفحة ${provider.currentPage} من ${provider.lastPage}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: provider.currentPage < provider.lastPage
                ? () => provider.changePage(provider.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  // ==================== الفلاتر ====================

  Widget _buildProjectFilter(EmployeeFilterProvider provider) {
    dynamic selectedValue;
    if (provider.selectedProject != null && provider.realProjects.isNotEmpty) {
      for (var project in provider.realProjects) {
        if (project['value']?.toString() == provider.selectedProject?['value']?.toString()) {
          selectedValue = project;
          break;
        }
      }
    }

    return _buildDropdownFilter(
      label: 'المشروع',
      value: selectedValue,
      items: provider.realProjects,
      onChanged: (value) {
        provider.updateFilter(project: value);
        provider.searchWithFilters(reset: true);
      },
      width: 160,
    );
  }

  Widget _buildBuildingFilter(EmployeeFilterProvider provider) {
    dynamic selectedValue;
    if (provider.selectedBuilding != null && provider.realBuildings.isNotEmpty) {
      for (var building in provider.realBuildings) {
        if (building['value']?.toString() == provider.selectedBuilding?['value']?.toString()) {
          selectedValue = building;
          break;
        }
      }
    }

    return _buildDropdownFilter(
      label: 'المبنى',
      value: selectedValue,
      items: provider.realBuildings,
      onChanged: (value) {
        provider.updateFilter(building: value);
        provider.searchWithFilters(reset: true);
      },
      width: 160,
    );
  }

  Widget _buildHousingFilter(EmployeeFilterProvider provider) {
    dynamic selectedValue;
    if (provider.selectedHousing != null && provider.realHousings.isNotEmpty) {
      for (var housing in provider.realHousings) {
        if (housing['value']?.toString() == provider.selectedHousing?['value']?.toString()) {
          selectedValue = housing;
          break;
        }
      }
    }

    return _buildDropdownFilter(
      label: 'السكن',
      value: selectedValue,
      items: provider.realHousings,
      onChanged: (value) {
        provider.updateFilter(housing: value);
        provider.searchWithFilters(reset: true);
      },
      width: 160,
    );
  }

  Widget _buildContractTypeFilter(EmployeeFilterProvider provider) {
    dynamic selectedValue;
    if (provider.selectedContractType != null && provider.realContractTypes.isNotEmpty) {
      for (var contract in provider.realContractTypes) {
        if (contract['value']?.toString() == provider.selectedContractType?['value']?.toString()) {
          selectedValue = contract;
          break;
        }
      }
    }

    return _buildDropdownFilter(
      label: 'نوع العقد',
      value: selectedValue,
      items: provider.realContractTypes,
      onChanged: (value) {
        provider.updateFilter(contractType: value);
        provider.searchWithFilters(reset: true);
      },
      width: 160,
    );
  }

  Widget _buildSortFilter() {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<String>(
        value: _selectedSortBy,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'ترتيب حسب',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('الترتيب', style: TextStyle(color: Colors.grey)),
          ),
          const DropdownMenuItem<String>(
            value: 'id_name',
            child: Text('الاسم'),
          ),
          const DropdownMenuItem<String>(
            value: 'joining_date',
            child: Text('تاريخ الالتحاق'),
          ),
          const DropdownMenuItem<String>(
            value: 'created_at',
            child: Text('تاريخ الإنشاء'),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedSortBy = value);
          final provider = Provider.of<EmployeeFilterProvider>(context, listen: false);
          provider.updateFilter(sortBy: value);
          provider.searchWithFilters(reset: true);
        },
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required dynamic value,
    required List<Map<String, dynamic>> items,
    required Function(dynamic?) onChanged,
    double? width,
  }) {
    return Container(
      width: width ?? 150,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<dynamic>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map<DropdownMenuItem<dynamic>>((item) {
          final displayName = item['display_name'] ?? item['name'] ?? '';
          
          return DropdownMenuItem<dynamic>(
            value: item,
            child: Text(
              displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: item['value']?.toString().isEmpty == true ? Colors.grey : Colors.black,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== كارت الموظف ====================

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContractColor(employee['contract_id']),
          child: Text(
            _getInitials(employee['id_name'] ?? ''),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          employee['id_name']?.toString() ?? 'بدون اسم',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasValidData(employee['iqamah_number']))
              Text('الإقامة: ${employee['iqamah_number']}'),
            if (_hasValidData(employee['job_title']))
              Text('الوظيفة: ${employee['job_title']}'),
            if (_hasValidData(employee['project_name']))
              Text('المشروع: ${employee['project_name']}'),
            if (_hasValidData(employee['building_id']))
              Text('المبنى: ${employee['building_id']}'),
            if (_hasValidData(employee['housing_name']))
              Text('السكن: ${employee['housing_name']}'),
            if (_hasValidData(employee['contract_id']))
              Text('العقد: ${employee['contract_id']}',
                  style: TextStyle(
                    color: _getContractColor(employee['contract_id']),
                    fontWeight: FontWeight.bold,
                  )),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Permission: require view_employees to open details
          try {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (!auth.can('view_employees')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('غير مسموح: ليس لديك صلاحية العرض')),
              );
              return;
            }
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('غير مسموح: ليس لديك صلاحية العرض')),
            );
            return;
          }

          _showEmployeeDetails(employee);
        },
      ),
    );
  }

  bool _hasValidData(dynamic value) {
    if (value == null) return false;
    final strValue = value.toString();
    return strValue.isNotEmpty && strValue != 'يحتاج لتعبئة';
  }

  Color _getContractColor(String? contractType) {
    if (!_hasValidData(contractType)) return Colors.grey;
    
    final type = contractType!.toLowerCase();
    if (type.contains('أصلي') || type.contains('original')) return Colors.green;
    if (type.contains('إيجار') || type.contains('rental')) return Colors.orange;
    if (type.contains('خارجي') || type.contains('external')) return Colors.purple;
    return Colors.blue;
  }

  String _getInitials(String name) {
    if (!_hasValidData(name)) return '??';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getContractColor(employee['contract_id']),
              child: Text(
                _getInitials(employee['id_name'] ?? ''),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                employee['id_name']?.toString() ?? 'تفاصيل الموظف',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasValidData(employee['id']))
                _buildDetailRow('الرقم التسلسلي', employee['id'].toString()),
              if (_hasValidData(employee['id_name']))
                _buildDetailRow('الاسم', employee['id_name']),
              if (_hasValidData(employee['iqamah_number']))
                _buildDetailRow('رقم الإقامة', employee['iqamah_number']),
              if (_hasValidData(employee['id_number']))
                _buildDetailRow('رقم الهوية', employee['id_number']),
              if (_hasValidData(employee['nationality']))
                _buildDetailRow('الجنسية', employee['nationality']),
              if (_hasValidData(employee['job_title']))
                _buildDetailRow('الوظيفة', employee['job_title']),
              if (_hasValidData(employee['project_name']))
                _buildDetailRow('المشروع', employee['project_name']),
              if (_hasValidData(employee['housing_name']))
                _buildDetailRow('السكن', employee['housing_name']),
              if (_hasValidData(employee['building_id']))
                _buildDetailRow('المبنى', employee['building_id']),
              if (_hasValidData(employee['contract_id']))
                _buildDetailRow('نوع العقد', employee['contract_id']),
              if (_hasValidData(employee['phone_number']))
                _buildDetailRow('رقم الهاتف', employee['phone_number']),
              if (_hasValidData(employee['email']))
                _buildDetailRow('البريد الإلكتروني', employee['email']),
              if (_hasValidData(employee['joining_date']))
                _buildDetailRow('تاريخ الالتحاق', employee['joining_date']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}