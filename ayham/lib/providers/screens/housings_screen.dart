// lib/screens/housings_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nabtatcompany/models/housing_model.dart';
import 'package:nabtatcompany/services/auth_service.dart';
import 'package:nabtatcompany/services/housing_service.dart';
import 'dart:io';

import 'login_screen.dart';
import 'admin_dashboard.dart';

class HousingsScreen extends StatefulWidget {
  const HousingsScreen({super.key});

  @override
  State<HousingsScreen> createState() => _HousingsScreenState();
}

class _HousingsScreenState extends State<HousingsScreen> {
  List<Housing> _housings = [];
  bool _loading = true;
  String _userName = 'الأدمن';
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHousings();
  }

  Future<void> _loadUserData() async {
    try {
      final name = await AuthService.getUserName();
      setState(() => _userName = name);
    } catch (e) {
      setState(() => _userName = 'الأدمن');
    }
  }

  Future<void> _loadHousings() async {
    setState(() => _loading = true);
    try {
      final housings = await HousingService.getHousings();
      setState(() {
        _housings = housings;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goBackToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboard()),
    );
  }

  void _showAddHousingDialog() {
    showDialog(
      context: context,
      builder: (context) => AddHousingDialog(
        onHousingAdded: () {
          _loadHousings();
          _showSuccess('تم إضافة السكن بنجاح');
        },
      ),
    );
  }

  void _showEditHousingDialog(Housing housing) {
    showDialog(
      context: context,
      builder: (context) => EditHousingDialog(
        housing: housing,
        onHousingUpdated: () {
          _loadHousings();
          _showSuccess('تم تحديث السكن بنجاح');
        },
      ),
    );
  }

  Future<void> _deleteHousing(int housingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السكن'),
        content: const Text('هل أنت متأكد من حذف هذا السكن؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await HousingService.deleteHousing(housingId);
        await _loadHousings();
        _showSuccess('تم حذف السكن بنجاح');
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  List<Housing> get _filteredHousings {
    if (_filterText.isEmpty) return _housings;
    
    final filter = _filterText.toLowerCase();
    
    return _housings.where((housing) {
      final name = housing.name.toLowerCase();
      final housingNumber = housing.housingNumber?.toLowerCase() ?? '';
      final housingType = housing.housingType.toLowerCase();
      final address = housing.address?.toLowerCase() ?? '';
      
      return name.contains(filter) ||
             housingNumber.contains(filter) ||
             housingType.contains(filter) ||
             address.contains(filter);
    }).toList();
  }

  Color _getHousingTypeColor(String type) {
    switch (type) {
      case 'ملك':
        return Colors.green;
      case 'إيجار':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getHousingTypeIcon(String type) {
    switch (type) {
      case 'ملك':
        return Icons.home;
      case 'إيجار':
        return Icons.business;
      default:
        return Icons.house;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السكن'),
        backgroundColor: const Color(0xFF2C3E50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToDashboard,
          tooltip: 'العودة للوحة التحكم',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHousings,
            tooltip: 'تحديث القائمة',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بحث في السكن:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم السكن أو رقمه أو نوعه أو العنوان',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _filterText.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _filterText = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() => _filterText = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'عدد السكن: ${_filteredHousings.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _housings.isEmpty
                    ? _buildEmptyState()
                    : _buildHousingList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHousingDialog,
        backgroundColor: const Color(0xFF4A90E2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'لا يوجد سكن بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'اضغط على زر (+) لإضافة سكن جديد',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showAddHousingDialog,
            child: const Text('إضافة أول سكن'),
          ),
        ],
      ),
    );
  }

  Widget _buildHousingList() {
    return RefreshIndicator(
      onRefresh: _loadHousings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredHousings.length,
        itemBuilder: (context, index) {
          final housing = _filteredHousings[index];
          return _buildHousingCard(housing);
        },
      ),
    );
  }

  Widget _buildHousingCard(Housing housing) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showEditHousingDialog(housing),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getHousingTypeColor(housing.housingType),
                radius: 25,
                child: Icon(
                  _getHousingTypeIcon(housing.housingType),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      housing.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    if (housing.housingNumber != null)
                      _buildInfoRow('رقم السكن:', housing.housingNumber!),
                    
                    if (housing.address != null)
                      _buildInfoRow('العنوان:', housing.address!),
                    
                    _buildInfoRow('النوع:', housing.housingType),
                    
                    if (housing.buildingsCount != null)
                      _buildInfoRow('المباني:', housing.buildingsCount.toString()),
                    
                    if (housing.roomsCount != null)
                      _buildInfoRow('الغرف:', housing.roomsCount.toString()),
                    
                    if (housing.hasLicense)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'مرخص',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    if (housing.rentDue)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          'إيجار مستحق',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditHousingDialog(housing),
                    tooltip: 'تعديل السكن',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteHousing(housing.id),
                    tooltip: 'حذف السكن',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class AddHousingDialog extends StatefulWidget {
  final VoidCallback onHousingAdded;

  const AddHousingDialog({
    super.key,
    required this.onHousingAdded,
  });

  @override
  State<AddHousingDialog> createState() => _AddHousingDialogState();
}

class _AddHousingDialogState extends State<AddHousingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _housingNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingsCountController = TextEditingController();
  final _roomsCountController = TextEditingController();
  final _housingValueController = TextEditingController();
  final _rentDueDateController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _housingType = 'ملك';
  bool _rentDue = false;
  bool _rentPaid = false;
  bool _isLoading = false;
  File? _licenseFile;

  Future<void> _pickLicenseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _licenseFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('Error picking license file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار ملف الرخصة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeLicenseFile() {
    setState(() {
      _licenseFile = null;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await HousingService.addHousing(
          name: _nameController.text,
          housingType: _housingType,
          housingNumber: _housingNumberController.text.isNotEmpty 
              ? _housingNumberController.text 
              : null,
          address: _addressController.text.isNotEmpty 
              ? _addressController.text 
              : null,
          buildingsCount: _buildingsCountController.text.isNotEmpty
              ? int.tryParse(_buildingsCountController.text)
              : null,
          roomsCount: _roomsCountController.text.isNotEmpty
              ? int.tryParse(_roomsCountController.text)
              : null,
          housingLicense: _licenseFile,
          housingValue: _housingValueController.text.isNotEmpty
              ? double.tryParse(_housingValueController.text)
              : null,
          rentDue: _rentDue,
          rentDueDate: _rentDueDateController.text.isNotEmpty
              ? _rentDueDateController.text
              : null,
          rentPaid: _rentPaid,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

        Navigator.pop(context);
        widget.onHousingAdded();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return const Icon(Icons.image, color: Colors.green);
    } else if (['pdf'].contains(extension)) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else {
      return const Icon(Icons.insert_drive_file);
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    if (int.tryParse(value) == null) {
      return 'يرجى إدخال $fieldName بشكل صحيح';
    }
    return null;
  }

  String? _validateDouble(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return 'يرجى إدخال $fieldName بشكل صحيح';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'إضافة سكن جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم السكن *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم السكن'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: _housingType,
                  decoration: const InputDecoration(
                    labelText: 'نوع السكن *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: ['ملك', 'إيجار']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _housingType = value!;
                    });
                  },
                  validator: (v) => _validateRequired(v, 'نوع السكن'),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _housingNumberController,
                  decoration: const InputDecoration(
                    labelText: 'رقم السكن',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buildingsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد المباني',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد المباني'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _roomsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد الغرف',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد الغرف'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _housingValueController,
                  decoration: const InputDecoration(
                    labelText: 'قيمة السكن',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _validateDouble(value, 'قيمة السكن'),
                ),
                const SizedBox(height: 15),
                
                Card(
                  child: CheckboxListTile(
                    title: const Text('إيجار مستحق'),
                    value: _rentDue,
                    onChanged: (value) => setState(() => _rentDue = value ?? false),
                  ),
                ),
                
                if (_rentDue) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _rentDueDateController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ استحقاق الإيجار',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: CheckboxListTile(
                      title: const Text('تم دفع الإيجار'),
                      value: _rentPaid,
                      onChanged: (value) => setState(() => _rentPaid = value ?? false),
                    ),
                  ),
                ],
                
                const SizedBox(height: 15),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'رخصة السكن',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickLicenseFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('اختر ملف الرخصة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                Text(
                  'الأنواع المسموحة: PDF, JPG, JPEG, PNG',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                if (_licenseFile != null) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: _getFileIcon(_licenseFile!.path.split('/').last),
                      title: Text(
                        _licenseFile!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: _removeLicenseFile,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'لم يتم اختيار ملف الرخصة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : const Text('إضافة السكن'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _housingNumberController.dispose();
    _addressController.dispose();
    _buildingsCountController.dispose();
    _roomsCountController.dispose();
    _housingValueController.dispose();
    _rentDueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class EditHousingDialog extends StatefulWidget {
  final Housing housing;
  final VoidCallback onHousingUpdated;

  const EditHousingDialog({
    super.key,
    required this.housing,
    required this.onHousingUpdated,
  });

  @override
  State<EditHousingDialog> createState() => _EditHousingDialogState();
}

class _EditHousingDialogState extends State<EditHousingDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.housing.name);
  late final _housingNumberController = TextEditingController(
      text: widget.housing.housingNumber ?? '');
  late final _addressController = TextEditingController(
      text: widget.housing.address ?? '');
  late final _buildingsCountController = TextEditingController(
      text: widget.housing.buildingsCount?.toString() ?? '');
  late final _roomsCountController = TextEditingController(
      text: widget.housing.roomsCount?.toString() ?? '');
  late final _housingValueController = TextEditingController(
      text: widget.housing.housingValue?.toString() ?? '');
  late final _rentDueDateController = TextEditingController(
      text: widget.housing.rentDueDate ?? '');
  late final _notesController = TextEditingController(
      text: widget.housing.notes ?? '');
  
  late String _housingType = widget.housing.housingType;
  late bool _rentDue = widget.housing.rentDue;
  late bool _rentPaid = widget.housing.rentPaid;
  bool _isLoading = false;
  
  File? _newLicenseFile;
  bool _deleteExistingLicense = false;

  Future<void> _pickLicenseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _newLicenseFile = File(result.files.single.path!);
          _deleteExistingLicense = false; // عند اختيار ملف جديد، لا نحذف الملف القديم
        });
      }
    } catch (e) {
      print('Error picking license file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار ملف الرخصة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeNewLicenseFile() {
    setState(() {
      _newLicenseFile = null;
    });
  }

  void _deleteLicense() {
    setState(() {
      _deleteExistingLicense = true;
      _newLicenseFile = null;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await HousingService.updateHousing(
          id: widget.housing.id,
          name: _nameController.text,
          housingType: _housingType,
          housingNumber: _housingNumberController.text.isNotEmpty 
              ? _housingNumberController.text 
              : null,
          address: _addressController.text.isNotEmpty 
              ? _addressController.text 
              : null,
          buildingsCount: _buildingsCountController.text.isNotEmpty
              ? int.tryParse(_buildingsCountController.text)
              : null,
          roomsCount: _roomsCountController.text.isNotEmpty
              ? int.tryParse(_roomsCountController.text)
              : null,
          housingLicense: _newLicenseFile,
          housingValue: _housingValueController.text.isNotEmpty
              ? double.tryParse(_housingValueController.text)
              : null,
          rentDue: _rentDue,
          rentDueDate: _rentDueDateController.text.isNotEmpty
              ? _rentDueDateController.text
              : null,
          rentPaid: _rentPaid,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

        Navigator.pop(context);
        widget.onHousingUpdated();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return const Icon(Icons.image, color: Colors.green);
    } else if (['pdf'].contains(extension)) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else {
      return const Icon(Icons.insert_drive_file);
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    if (int.tryParse(value) == null) {
      return 'يرجى إدخال $fieldName بشكل صحيح';
    }
    return null;
  }

  String? _validateDouble(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return 'يرجى إدخال $fieldName بشكل صحيح';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingLicense = widget.housing.hasLicense;

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'تعديل السكن',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم السكن *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم السكن'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: _housingType,
                  decoration: const InputDecoration(
                    labelText: 'نوع السكن *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: ['ملك', 'إيجار']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _housingType = value!;
                    });
                  },
                  validator: (v) => _validateRequired(v, 'نوع السكن'),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _housingNumberController,
                  decoration: const InputDecoration(
                    labelText: 'رقم السكن',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buildingsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد المباني',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد المباني'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _roomsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد الغرف',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد الغرف'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _housingValueController,
                  decoration: const InputDecoration(
                    labelText: 'قيمة السكن',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _validateDouble(value, 'قيمة السكن'),
                ),
                const SizedBox(height: 15),
                
                Card(
                  child: CheckboxListTile(
                    title: const Text('إيجار مستحق'),
                    value: _rentDue,
                    onChanged: (value) => setState(() => _rentDue = value ?? false),
                  ),
                ),
                
                if (_rentDue) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _rentDueDateController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ استحقاق الإيجار',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: CheckboxListTile(
                      title: const Text('تم دفع الإيجار'),
                      value: _rentPaid,
                      onChanged: (value) => setState(() => _rentPaid = value ?? false),
                    ),
                  ),
                ],
                
                const SizedBox(height: 15),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'رخصة السكن',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickLicenseFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('اختر ملف جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                Text(
                  'الأنواع المسموحة: PDF, JPG, JPEG, PNG',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                if (hasExistingLicense && !_deleteExistingLicense) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.green),
                      title: const Text(
                        'رخصة موجودة حالياً',
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.housing.housingLicenseUrl != null)
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                              onPressed: () {
                                // يمكنك فتح الرابط في متصفح أو عرض الصورة
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: _deleteLicense,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                if (_newLicenseFile != null) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: _getFileIcon(_newLicenseFile!.path.split('/').last),
                      title: Text(
                        _newLicenseFile!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: _removeNewLicenseFile,
                      ),
                    ),
                  ),
                ],
                
                if (!hasExistingLicense && _newLicenseFile == null) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'لا توجد رخصة حالياً',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : const Text('حفظ التعديلات'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _housingNumberController.dispose();
    _addressController.dispose();
    _buildingsCountController.dispose();
    _roomsCountController.dispose();
    _housingValueController.dispose();
    _rentDueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}