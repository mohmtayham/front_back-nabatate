import 'package:flutter/material.dart';
import 'package:nabtatcompany/dialogs/attachments_dialog.dart';
import 'package:nabtatcompany/dialogs/employee_form_dialog.dart';
import 'package:provider/provider.dart';
import 'package:nabtatcompany/providers/employee_provider.dart';
import 'package:nabtatcompany/providers/employee_case_provider.dart';
import 'package:nabtatcompany/providers/screens/employees/employee_cases.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:nabtatcompany/services/auth_service.dart';
import 'package:nabtatcompany/providers/auth_provider.dart';

import 'package:nabtatcompany/services/api_service.dart';
class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _searchController = TextEditingController();
  bool _showSearchBar = false;

  // متغيرات الاختيار المتعدد
  Set<int> _selectedEmployeeIds = <int>{}; // مجموعة لتخزين IDs الموظفين المختارين
  bool _isSelectionMode = false; // هل نحن في وضع الاختيار المتعدد؟

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      provider.fetchEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _requirePermission(BuildContext context, String permissionKey, String message) {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.can(permissionKey)) return true;
    } catch (e) {
      // ignore
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    return false;
  }

  // تبديل وضع الاختيار المتعدد
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEmployeeIds.clear();
      }
    });
  }

  // اختيار/إلغاء اختيار موظف واحد
  void _toggleEmployeeSelection(int id) {
    setState(() {
      if (_selectedEmployeeIds.contains(id)) {
        _selectedEmployeeIds.remove(id);
      } else {
        _selectedEmployeeIds.add(id);
      }

      // إذا ما بقي موظف مختار → نخرج من وضع الاختيار
      if (_selectedEmployeeIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  // اختيار الكل في الصفحة الحالية
  void _selectAllOnPage(List<Map<String, dynamic>> employees) {
    setState(() {
      _selectedEmployeeIds.clear();
      for (var e in employees) {
        _selectedEmployeeIds.add(e['id']);
      }
    });
  }

  // إلغاء الاختيار للكل
  void _clearSelection() {
    setState(() {
      _selectedEmployeeIds.clear();
      _isSelectionMode = false;
    });
  }

  // حذف الموظفين المختارين (batch delete)
  Future<void> _batchDeleteEmployees() async {
    if (_selectedEmployeeIds.isEmpty) return;
    if (!_requirePermission(context, 'destroy_employees', 'غير مسموح: ليس لديك صلاحية الحذف')) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف ${_selectedEmployeeIds.length} موظف؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
        if (!_requirePermission(context, 'destroy_employees', 'غير مسموح: ليس لديك صلاحية الحذف')) return;
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.batchDeleteEmployees(_selectedEmployeeIds.toList());

      _clearSelection();
    }
  }

  // تحديث السكن للموظفين المختارين (batch update housing)
  Future<void> _batchUpdateHousing() async {
    if (_selectedEmployeeIds.isEmpty) return;

    String? newHousing;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحديث السكن'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'اسم السكن الجديد',
            hintText: 'مثال: المزاحمية',
          ),
          onChanged: (value) => newHousing = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );

    if (newHousing != null && newHousing!.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تأكيد التحديث'),
          content: Text('تحديث السكن لـ ${_selectedEmployeeIds.length} موظف إلى "$newHousing"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تحديث')),
          ],
        ),
      );

      if (confirmed == true) {
        final provider = Provider.of<EmployeeProvider>(context, listen: false);
        await provider.batchUpdateHousing(_selectedEmployeeIds.toList(), newHousing!);

        _clearSelection();
      }
    }
  }

  void _showEmployeeForm({Map? employee}) async {
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    await showDialog(
      context: context,
      builder: (_) => EmployeeFormDialog(
        employee: employee,
        onSaved: () => provider.fetchEmployees(),
        
      ),
    );
  }

  void _deleteEmployee(int id, String name) async {
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    if (!_requirePermission(context, 'destroy_employees', 'غير مسموح: ليس لديك صلاحية الحذف')) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الموظف "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteEmployee(id, name);
    }
  }

  void _showAttachments(int employeeId, String employeeName) async {
    await showDialog(
      context: context,
      builder: (_) => AttachmentsDialog(
        employeeId: employeeId,
        employeeName: employeeName,
      ),
    );
  }

 void _showEmployeeDetails(Map employee) async {
    // Permission guard: ensure user can view details
    if (!_requirePermission(context, 'show_employees', 'غير مسموح: ليس لديك صلاحية العرض')) return;
    // 👈 نستخدم نفس الديالوج الخاص بالتعديل ولكن مع تمرير isReadOnly: true
    await showDialog(
      context: context,
      builder: (_) => EmployeeFormDialog(
        employee: employee,
        isReadOnly: true, // 👈 هذا هو السطر السحري الذي سيمنع التعديل
        onSaved: () {},  
      
        
         // لن نحتاج لتحديث القائمة لأنه لا يوجد تعديل
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final provider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? 'مختار: ${_selectedEmployeeIds.length}'
              : 'إدارة الموظفين',
        ),
        actions: [
          if (provider.exporting || provider.importing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
  icon: const Icon(Icons.print),
  tooltip: 'طباعة الموظفين',
  onPressed: () async {
    // Permission check
    if (!_requirePermission(context, 'print_employees', 'غير مسموح: ليس لديك صلاحية الطباعة')) return;

    try {
      final file = await ApiService().printEmployeesZip();

      await OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الطباعة: $e')),
      );
    }

  },
),

          // Delete All employees (requires delete_employees permission)
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'حذف جميع الموظفين',
            onPressed: () async {
              if (!_requirePermission(context, 'destroy_employees', 'غير مسموح: ليس لديك صلاحية حذف الكل')) return;

              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('تأكيد حذف الكل'),
                  content: const Text('هل أنت متأكد من حذف جميع الموظفين؟ هذا الإجراء لا يمكن التراجع عنه.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('حذف الكل'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final res = await ApiService().deleteAllEmployees();
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? 'تم حذف جميع الموظفين'), backgroundColor: Colors.green),
                    );
                    final provider = Provider.of<EmployeeProvider>(context, listen: false);
                    provider.fetchEmployees();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? 'فشل حذف الموظفين'), backgroundColor: Colors.red),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ أثناء حذف الكل: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),

          IconButton(
            onPressed: provider.importing
                ? null
                : () {
                    if (!_requirePermission(context, 'import_employees', 'غير مسموح: ليس لديك صلاحية الاستيراد')) return;
                    provider.importExcel();
                  },
            icon: const Icon(Icons.file_upload),
            tooltip: 'استيراد Excel',
          ),
          IconButton(
            onPressed: provider.exporting
                ? null
                : () {
                    if (!_requirePermission(context, 'export_employees', 'غير مسموح: ليس لديك صلاحية التصدير')) return;
                    provider.exportExcel();
                  },
            icon: const Icon(Icons.file_download),
            tooltip: 'تصدير Excel',
          ),
          IconButton(
            onPressed: () {
              if (!_requirePermission(context, 'add_employees', 'غير مسموح: ليس لديك صلاحية الإضافة')) return;
              _showEmployeeForm();
            },
            icon: const Icon(Icons.add),
            tooltip: 'إضافة موظف',
          ),
          IconButton(
            onPressed: () {
              setState(() => _showSearchBar = !_showSearchBar);
              if (!_showSearchBar) {
                _searchController.clear();
                provider.clearSearch();
              }
            },
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            tooltip: _showSearchBar ? 'إغلاق البحث' : 'بحث',
          ),

          // زر الاختيار المتعدد
          IconButton(
            onPressed: _toggleSelectionMode,
            icon: Icon(_isSelectionMode ? Icons.close : Icons.check_box_outlined),
            tooltip: _isSelectionMode ? 'إلغاء الاختيار' : 'اختيار متعدد',
            color: _isSelectionMode ? Colors.blue : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          if (_showSearchBar)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'البحث بالاسم أو الإقامة أو الرقم',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => provider.searchEmployees(value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => provider.searchEmployees(_searchController.text),
                    child: const Text('بحث'),
                  ),
                ],
              ),
            ),

          // أزرار الإجراءات الجماعية (تظهر فقط في وضع الاختيار)
          if (_isSelectionMode)
            Container(
              width: double.infinity,
              color: Colors.blue[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Text('مختار: ${_selectedEmployeeIds.length} موظف'),
                  const Spacer(),
                  if (_selectedEmployeeIds.length == provider.employees.length)
                    TextButton(
                      onPressed: _clearSelection,
                      child: const Text('إلغاء الكل'),
                    )
                  else
                    TextButton(
                      onPressed: () => _selectAllOnPage(provider.employees),
                      child: const Text('اختيار الكل في الصفحة'),
                    ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _batchUpdateHousing,
                    icon: const Icon(Icons.home),
                    label: const Text('تحديث السكن'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _batchDeleteEmployees,
                    icon: const Icon(Icons.delete),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ),

          // جدول الموظفين
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.employees.isEmpty
                    ? const Center(child: Text('لا يوجد موظفين', style: TextStyle(fontSize: 18, color: Colors.grey)))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              // عمود الاختيار (يظهر فقط في وضع الاختيار)
                              if (_isSelectionMode)
                                DataColumn(
                                  label: Checkbox(
                                    value: _selectedEmployeeIds.length == provider.employees.length,
                                    onChanged: (val) {
                                      if (val == true) {
                                        _selectAllOnPage(provider.employees);
                                      } else {
                                        _clearSelection();
                                      }
                                    },
                                  ),
                                ),
                              const DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('الإقامة', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('رقم الهوية', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: provider.employees.map<DataRow>((e) {
                              final isSelected = _selectedEmployeeIds.contains(e['id']);

                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: _isSelectionMode
                                    ? (selected) {
                                        if (selected == true) {
                                          _toggleEmployeeSelection(e['id']);
                                        }
                                      }
                                    : null,
                                cells: [
                                  if (_isSelectionMode)
                                    DataCell(
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) => _toggleEmployeeSelection(e['id']),
                                      ),
                                    ),
                                  DataCell(Text(e['id'].toString())),
                                  DataCell(Text(e['id_name'] ?? 'غير معروف')),
                                  DataCell(Text(e['iqamah_number'] ?? '')),
                                  DataCell(Text(e['id_number'] ?? '')),
                                  DataCell(Text(e['phone_number'] ?? '')),
                                  
                                  DataCell(
                                Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (!_requirePermission(context, 'update_employees', 'غير مسموح: ليس لديك صلاحية التعديل')) return;
                                          _showEmployeeForm(employee: e);
                                        },
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: Colors.blue,
                                        tooltip: 'تعديل',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteEmployee(e['id'], e['id_name'] ?? 'غير معروف'),
                                        icon: const Icon(Icons.delete, size: 20),
                                        color: Colors.red,
                                        tooltip: 'حذف',
                                      ),
                                      IconButton(
                                        onPressed: () => _showAttachments(e['id'], e['id_name'] ?? 'غير معروف'),
                                        icon: const Icon(Icons.attach_file, size: 20),
                                        color: Colors.green,
                                        tooltip: 'المرفقات',
                                      ),
                                         //["view_all","add_employees","delete_employees","print_employees","update_employees"]
                                      // ✅ CASES BUTTON (NEW)
                                      IconButton(
                                        icon: const Icon(Icons.folder_open, size: 20),
                                        color: Colors.purple,
                                        tooltip: 'قضايا الموظف',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChangeNotifierProvider(
                                                create: (_) => EmployeeCaseProvider(),
                                                child: EmployeeCasesScreen(
                                                  employeeId: e['id'],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      IconButton(
                                        onPressed: () {
                                          if (!_requirePermission(context, 'view_employees', 'غير مسموح: ليس لديك صلاحية العرض')) return;
                                          _showEmployeeDetails(e);
                                        },
                                        icon: const Icon(Icons.visibility, size: 20),
                                        color: Colors.orange,
                                        tooltip: 'عرض التفاصيل',
                                      ),
                                    ],
                                  ),

                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (provider.employees.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('إجمالي الموظفين: ${provider.totalItems}', style: TextStyle(color: Colors.grey[600])),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: provider.currentPage > 1 ? () => provider.fetchEmployees(page: provider.currentPage - 1) : null,
                        color: provider.currentPage > 1 ? Colors.blue : Colors.grey,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                        child: Text('صفحة ${provider.currentPage} من ${provider.lastPage}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: provider.currentPage < provider.lastPage ? () => provider.fetchEmployees(page: provider.currentPage + 1) : null,
                        color: provider.currentPage < provider.lastPage ? Colors.blue : Colors.grey,
                      ),
                    ],
                  ),
                  OutlinedButton(onPressed: () => provider.fetchEmployees(), child: const Text('تحديث')),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!_requirePermission(context, 'add_employees', 'غير مسموح: ليس لديك صلاحية الإضافة')) return;
          _showEmployeeForm();
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة موظف جديد',
      ),
    );
  }

  // باقي الدوال (_showEmployeeDetails, _copyEmployeeDetailsToClipboard, _buildLanguageSelector, إلخ) تبقى كما هي
}