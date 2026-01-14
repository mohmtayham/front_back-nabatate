// lib/screens/buildings_screen.dart
import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/building_model.dart';
import 'package:nabtatcompany/models/housing_model.dart';
import 'package:nabtatcompany/services/auth_service.dart';
import 'package:nabtatcompany/services/building_service.dart';
import 'package:nabtatcompany/services/housing_service.dart';

import 'login_screen.dart';
import 'admin_dashboard.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  List<Building> _buildings = [];
  List<Housing> _housings = [];
  bool _loading = true;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _loadBuildings();
    _loadHousings();
  }

  Future<void> _loadBuildings() async {
    setState(() => _loading = true);
    try {
      final buildings = await BuildingService.getBuildings();
      setState(() {
        _buildings = buildings;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _loadHousings() async {
    try {
      final housings = await HousingService.getHousings();
      setState(() {
        _housings = housings;
      });
    } catch (e) {
      print('Failed to load housings: $e');
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

  void _showAddBuildingDialog() {
    showDialog(
      context: context,
      builder: (context) => AddBuildingDialog(
        housings: _housings,
        onBuildingAdded: () {
          _loadBuildings();
          _showSuccess('تم إضافة المبنى بنجاح');
        },
      ),
    );
  }

  void _showEditBuildingDialog(Building building) {
    showDialog(
      context: context,
      builder: (context) => EditBuildingDialog(
        building: building,
        housings: _housings,
        onBuildingUpdated: () {
          _loadBuildings();
          _showSuccess('تم تحديث المبنى بنجاح');
        },
      ),
    );
  }

  Future<void> _deleteBuilding(int buildingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المبنى'),
        content: const Text('هل أنت متأكد من حذف هذا المبنى؟'),
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
        await BuildingService.deleteBuilding(buildingId);
        await _loadBuildings();
        _showSuccess('تم حذف المبنى بنجاح');
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  List<Building> get _filteredBuildings {
    if (_filterText.isEmpty) return _buildings;
    
    final filter = _filterText.toLowerCase();
    
    return _buildings.where((building) {
      final name = building.name.toLowerCase();
      final housingName = building.housing?.name.toLowerCase() ?? '';
      
      return name.contains(filter) || 
             housingName.contains(filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المباني'),
        backgroundColor: const Color(0xFF2C3E50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToDashboard,
          tooltip: 'العودة للوحة التحكم',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuildings,
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
                      'بحث في المباني:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم المبنى أو السكن التابع له',
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
                      'عدد المباني: ${_filteredBuildings.length}',
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
                : _buildings.isEmpty
                    ? _buildEmptyState()
                    : _buildBuildingList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBuildingDialog,
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
          const Icon(Icons.business_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'لا يوجد مباني بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'اضغط على زر (+) لإضافة مبنى جديد',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showAddBuildingDialog,
            child: const Text('إضافة أول مبنى'),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingList() {
    return RefreshIndicator(
      onRefresh: _loadBuildings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredBuildings.length,
        itemBuilder: (context, index) {
          final building = _filteredBuildings[index];
          return _buildBuildingCard(building);
        },
      ),
    );
  }

  Widget _buildBuildingCard(Building building) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showEditBuildingDialog(building),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.purple,
                radius: 25,
                child: Icon(
                  Icons.business,
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
                      building.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    if (building.housing != null)
                      _buildInfoRow('السكن:', building.housing!.name),
                    
                    if (building.floorsCount != null)
                      _buildInfoRow('عدد الادوار:', building.floorsCount.toString()),
                    
                    if (building.roomsCount != null)
                      _buildInfoRow('عدد الغرف:', building.roomsCount.toString()),
                    
                    if (building.rooms != null && building.rooms!.isNotEmpty)
                      _buildInfoRow('الغرف الفعلية:', '${building.rooms!.length} غرفة'),
                  ],
                ),
              ),
              
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditBuildingDialog(building),
                    tooltip: 'تعديل المبنى',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBuilding(building.id),
                    tooltip: 'حذف المبنى',
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

class AddBuildingDialog extends StatefulWidget {
  final List<Housing> housings;
  final VoidCallback onBuildingAdded;

  const AddBuildingDialog({
    super.key,
    required this.housings,
    required this.onBuildingAdded,
  });

  @override
  State<AddBuildingDialog> createState() => _AddBuildingDialogState();
}

class _AddBuildingDialogState extends State<AddBuildingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _floorsCountController = TextEditingController();
  final _roomsCountController = TextEditingController();
  int? _selectedHousingId;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHousingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار سكن'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await BuildingService.addBuilding(
          name: _nameController.text,
          housingId: _selectedHousingId!,
          floorsCount: _floorsCountController.text.isNotEmpty
              ? int.tryParse(_floorsCountController.text)
              : null,
          roomsCount: _roomsCountController.text.isNotEmpty
              ? int.tryParse(_roomsCountController.text)
              : null,
        );

        Navigator.pop(context);
        widget.onBuildingAdded();
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
                    'إضافة مبنى جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المبنى *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم المبنى'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<int>(
                  value: _selectedHousingId,
                  decoration: const InputDecoration(
                    labelText: 'السكن *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: widget.housings.map((housing) {
                    return DropdownMenuItem<int>(
                      value: housing.id,
                      child: Text(housing.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHousingId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'يرجى اختيار سكن';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _floorsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد الطوابق',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد الطوابق'),
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
                            : const Text('إضافة المبنى'),
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
    _floorsCountController.dispose();
    _roomsCountController.dispose();
    super.dispose();
  }
}

class EditBuildingDialog extends StatefulWidget {
  final Building building;
  final List<Housing> housings;
  final VoidCallback onBuildingUpdated;

  const EditBuildingDialog({
    super.key,
    required this.building,
    required this.housings,
    required this.onBuildingUpdated,
  });

  @override
  State<EditBuildingDialog> createState() => _EditBuildingDialogState();
}

class _EditBuildingDialogState extends State<EditBuildingDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.building.name);
  late final _floorsCountController = TextEditingController(
      text: widget.building.floorsCount?.toString() ?? '');
  late final _roomsCountController = TextEditingController(
      text: widget.building.roomsCount?.toString() ?? '');
  late int? _selectedHousingId = widget.building.housingId;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHousingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار سكن'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await BuildingService.updateBuilding(
          id: widget.building.id,
          name: _nameController.text,
          housingId: _selectedHousingId!,
          floorsCount: _floorsCountController.text.isNotEmpty
              ? int.tryParse(_floorsCountController.text)
              : null,
          roomsCount: _roomsCountController.text.isNotEmpty
              ? int.tryParse(_roomsCountController.text)
              : null,
        );

        Navigator.pop(context);
        widget.onBuildingUpdated();
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
                    'تعديل المبنى',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المبنى *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم المبنى'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<int>(
                  value: _selectedHousingId,
                  decoration: const InputDecoration(
                    labelText: 'السكن *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: widget.housings.map((housing) {
                    return DropdownMenuItem<int>(
                      value: housing.id,
                      child: Text(housing.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHousingId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'يرجى اختيار سكن';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _floorsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد الطوابق',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد الطوابق'),
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
    _floorsCountController.dispose();
    _roomsCountController.dispose();
    super.dispose();
  }
}