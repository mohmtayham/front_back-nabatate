import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/building_model.dart';
import 'package:nabtatcompany/models/room_model.dart';
import 'package:nabtatcompany/services/auth_service.dart';
import 'package:nabtatcompany/services/building_service.dart';
import 'package:nabtatcompany/services/room_service.dart';

import 'login_screen.dart';
import 'admin_dashboard.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<Room> _rooms = [];
  List<Building> _buildings = [];
  bool _loading = true;
  String _filterText = '';
  int? _selectedBuildingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        RoomService.getRooms(buildingId: _selectedBuildingId),
        BuildingService.getBuildings(),
      ]);
      
      setState(() {
        _rooms = results[0] as List<Room>;
        _buildings = results[1] as List<Building>;
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

  void _showAddRoomDialog() {
    if (_buildings.isEmpty) {
      _showError('لا يوجد مباني متاحة. الرجاء إضافة مبنى أولاً.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddRoomDialog(
        buildings: _buildings,
        onRoomAdded: () {
          _loadData();
          _showSuccess('تم إضافة الغرفة بنجاح');
        },
      ),
    );
  }

  void _showEditRoomDialog(Room room) {
    if (_buildings.isEmpty) {
      _showError('لا يوجد مباني متاحة.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EditRoomDialog(
        room: room,
        buildings: _buildings,
        onRoomUpdated: () {
          _loadData();
          _showSuccess('تم تحديث الغرفة بنجاح');
        },
      ),
    );
  }

  Future<void> _deleteRoom(int roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الغرفة'),
        content: const Text('هل أنت متأكد من حذف هذه الغرفة؟'),
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
        await RoomService.deleteRoom(roomId);
        await _loadData();
        _showSuccess('تم حذف الغرفة بنجاح');
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  List<Room> get _filteredRooms {
    if (_filterText.isEmpty && _selectedBuildingId == null) return _rooms;
    
    final filter = _filterText.toLowerCase();
    
    return _rooms.where((room) {
      final name = room.name.toLowerCase();
      final buildingName = room.buildingName.toLowerCase();
      final status = room.status.toLowerCase();
      
      if (_selectedBuildingId != null && room.buildingId != _selectedBuildingId) {
        return false;
      }
      
      if (_filterText.isNotEmpty) {
        return name.contains(filter) || 
               buildingName.contains(filter) ||
               status.contains(filter);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الغرف'),
        backgroundColor: const Color(0xFF2C3E50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToDashboard,
          tooltip: 'العودة للوحة التحكم',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                      'تصفية الغرف:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    DropdownButtonFormField<int?>(
                      value: _selectedBuildingId,
                      decoration: const InputDecoration(
                        labelText: 'تصفية حسب المبنى',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('جميع المباني'),
                        ),
                        ..._buildings.map((building) {
                          return DropdownMenuItem<int?>(
                            value: building.id,
                            child: Text(building.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBuildingId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم الغرفة أو المبنى أو الحالة',
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
                      'عدد الغرف: ${_filteredRooms.length}',
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
                : _rooms.isEmpty
                    ? _buildEmptyState()
                    : _buildRoomList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
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
          const Icon(Icons.meeting_room_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'لا يوجد غرف بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'اضغط على زر (+) لإضافة غرفة جديدة',
            style: TextStyle(color: Colors.grey),
          ),
          if (_buildings.isEmpty)
            Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'يجب إضافة مبنى أولاً',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboard()),
                    );
                  },
                  child: const Text('الذهاب إلى المباني'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRooms.length,
        itemBuilder: (context, index) {
          final room = _filteredRooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showEditRoomDialog(room),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: room.statusColor.withOpacity(0.2),
                radius: 25,
                child: Icon(
                  room.statusIcon,
                  color: room.statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: room.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: room.statusColor),
                          ),
                          child: Text(
                            room.status,
                            style: TextStyle(
                              color: room.statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    if (room.buildingName.isNotEmpty)
                      _buildInfoRow('المبنى:', room.buildingName),
                    
                    Row(
                      children: [
                        if (room.bedsCount != null)
                          Expanded(
                            child: _buildInfoRow('عدد الأسرة:', '${room.bedsCount}'),
                          ),
                        if (room.residentsCount != null)
                          Expanded(
                            child: _buildInfoRow('المقيمين:', '${room.residentsCount}'),
                          ),
                      ],
                    ),
                    
                    if (room.notes != null && room.notes!.isNotEmpty)
                      _buildInfoRow('ملاحظات:', room.notes!),
                  ],
                ),
              ),
              
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditRoomDialog(room),
                    tooltip: 'تعديل الغرفة',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRoom(room.id),
                    tooltip: 'حذف الغرفة',
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

class AddRoomDialog extends StatefulWidget {
  final List<Building> buildings;
  final VoidCallback onRoomAdded;

  const AddRoomDialog({
    super.key,
    required this.buildings,
    required this.onRoomAdded,
  });

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bedsCountController = TextEditingController();
  final _residentsCountController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedBuildingId;
  String _selectedStatus = 'فارغة';
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'مشغولة',
    'فارغة',
    'تحت الصيانة',
    'مغلقة'
  ];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBuildingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار مبنى'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await RoomService.addRoom(
          name: _nameController.text,
          buildingId: _selectedBuildingId!,
          bedsCount: _bedsCountController.text.isNotEmpty
              ? int.tryParse(_bedsCountController.text)
              : null,
          residentsCount: _residentsCountController.text.isNotEmpty
              ? int.tryParse(_residentsCountController.text)
              : null,
          status: _selectedStatus,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        Navigator.pop(context);
        widget.onRoomAdded();
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
                    'إضافة غرفة جديدة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الغرفة *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم الغرفة'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<int>(
                  value: _selectedBuildingId,
                  decoration: const InputDecoration(
                    labelText: 'المبنى *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: widget.buildings.map((building) {
                    return DropdownMenuItem<int>(
                      value: building.id,
                      child: Text(building.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBuildingId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'يرجى اختيار مبنى';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة الغرفة *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: _statusOptions.map((status) {
                    Color statusColor;
                    switch (status) {
                      case 'مشغولة':
                        statusColor = Colors.red;
                        break;
                      case 'فارغة':
                        statusColor = Colors.green;
                        break;
                      case 'تحت الصيانة':
                        statusColor = Colors.orange;
                        break;
                      case 'مغلقة':
                        statusColor = Colors.grey;
                        break;
                      default:
                        statusColor = Colors.blue;
                    }
                    
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(status),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد الأسرة',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد الأسرة'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _residentsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد المقيمين',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد المقيمين'),
                      ),
                    ),
                  ],
                ),
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
                            : const Text('إضافة الغرفة'),
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
    _bedsCountController.dispose();
    _residentsCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class EditRoomDialog extends StatefulWidget {
  final Room room;
  final List<Building> buildings;
  final VoidCallback onRoomUpdated;

  const EditRoomDialog({
    super.key,
    required this.room,
    required this.buildings,
    required this.onRoomUpdated,
  });

  @override
  State<EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.room.name);
  late final _bedsCountController = TextEditingController(
      text: widget.room.bedsCount?.toString() ?? '');
  late final _residentsCountController = TextEditingController(
      text: widget.room.residentsCount?.toString() ?? '');
  late final _notesController = TextEditingController(text: widget.room.notes ?? '');
  late int? _selectedBuildingId = widget.room.buildingId;
  late String _selectedStatus = widget.room.status;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'مشغولة',
    'فارغة',
    'تحت الصيانة',
    'مغلقة'
  ];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBuildingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار مبنى'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await RoomService.updateRoom(
          id: widget.room.id,
          name: _nameController.text,
          buildingId: _selectedBuildingId!,
          bedsCount: _bedsCountController.text.isNotEmpty
              ? int.tryParse(_bedsCountController.text)
              : null,
          residentsCount: _residentsCountController.text.isNotEmpty
              ? int.tryParse(_residentsCountController.text)
              : null,
          status: _selectedStatus,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        Navigator.pop(context);
        widget.onRoomUpdated();
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
                    'تعديل الغرفة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الغرفة *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم الغرفة'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<int>(
                  value: _selectedBuildingId,
                  decoration: const InputDecoration(
                    labelText: 'المبنى *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: widget.buildings.map((building) {
                    return DropdownMenuItem<int>(
                      value: building.id,
                      child: Text(building.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBuildingId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'يرجى اختيار مبنى';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة الغرفة *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: _statusOptions.map((status) {
                    Color statusColor;
                    switch (status) {
                      case 'مشغولة':
                        statusColor = Colors.red;
                        break;
                      case 'فارغة':
                        statusColor = Colors.green;
                        break;
                      case 'تحت الصيانة':
                        statusColor = Colors.orange;
                        break;
                      case 'مغلقة':
                        statusColor = Colors.grey;
                        break;
                      default:
                        statusColor = Colors.blue;
                    }
                    
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(status),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد الأسرة',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد الأسرة'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _residentsCountController,
                        decoration: const InputDecoration(
                          labelText: 'عدد المقيمين',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'عدد المقيمين'),
                      ),
                    ),
                  ],
                ),
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
    _bedsCountController.dispose();
    _residentsCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}