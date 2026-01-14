import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nabtatcompany/providers/employee_provider.dart';
import 'package:nabtatcompany/services/api_service.dart';

class EmployeeFormDialog extends StatefulWidget {
  final Map? employee;
  final VoidCallback onSaved;
  final bool isReadOnly; 

  const EmployeeFormDialog({
    this.employee,
    required this.onSaved,
    this.isReadOnly = false,
    super.key,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  late String _selectedGender;
  bool _isSaving = false;
  late Map<String, dynamic> _employeeData;

  // Helper to try multiple candidate keys and nested maps
  String? _getEmpValue(List<String> candidates) {
    if (_employeeData.isEmpty) return null;
    for (var key in candidates) {
      if (key.contains('.')) {
        final parts = key.split('.');
        dynamic cur = _employeeData;
        for (var p in parts) {
          if (cur is Map && cur.containsKey(p)) {
            cur = cur[p];
          } else {
            cur = null;
            break;
          }
        }
        if (cur != null && cur.toString().isNotEmpty) return cur.toString();
      } else {
        final v = _employeeData[key];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Use a mutable local copy so we can replace it after fetching full details
    _employeeData = widget.employee != null ? Map<String, dynamic>.from(widget.employee!) : <String, dynamic>{};
    _initializeControllers();

    // If the provided payload looks minimal, try fetching full employee details
    if (_employeeData.isNotEmpty && _employeeData.keys.length < 8) {
      // fire-and-forget - when full data arrives we'll re-init controllers
      _fetchFullEmployee();
    }
  }

  Future<void> _fetchFullEmployee() async {
    try {
      final id = _employeeData['id'];
      if (id == null) return;
      final api = ApiService();
      final res = await api.getEmployee(id);

      // Detect returned payload shape
      Map<String, dynamic>? full;
      if (res.containsKey('employee')) full = Map<String, dynamic>.from(res['employee']);
      else if (res.containsKey('data')) full = Map<String, dynamic>.from(res['data']);
      else if (res.containsKey('id') || res.containsKey('id_name')) full = Map<String, dynamic>.from(res);

      if (full != null && full.isNotEmpty) {
        debugPrint('🧾 Fetched full employee: $full');
        setState(() {
          _employeeData = full!;
          // dispose old controllers
          _controllers.values.forEach((c) => c.dispose());
          _initializeControllers();
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch full employee: $e');
    }
  }
void _initializeControllers() {
  // Debug: print incoming employee payload to inspect available keys
  debugPrint('🧾 EmployeeFormDialog.employee payload: ${widget.employee}');

  // Normalize gender from several possible representations
  final apiGender = _getEmpValue(['gender', 'sex', 'g']);
  if (apiGender != null) {
    final g = apiGender.toLowerCase();
    if (g == 'ذكر' || g == 'male' || g == 'm') _selectedGender = 'Male';
    else if (g == 'أنثى' || g == 'female' || g == 'f') _selectedGender = 'Female';
    else _selectedGender = 'Male';
  } else {
    _selectedGender = 'Male';
  }

  _controllers = {
    'sn': TextEditingController(text: _getEmpValue(['sn', 'serial_number', 'serial']) ?? ''),
    'id_name': TextEditingController(text: _getEmpValue(['id_name', 'name', 'full_name']) ?? ''),
    'iqamah_number': TextEditingController(text: _getEmpValue(['iqamah_number', 'iqama', 'iqama_number']) ?? ''),
    'id_number': TextEditingController(text: _getEmpValue(['id_number', 'national_id', 'nid']) ?? ''),
    'nationality': TextEditingController(text: _getEmpValue(['nationality', 'country']) ?? ''),
    'passport_number': TextEditingController(text: _getEmpValue(['passport_number', 'passport']) ?? ''),
    'job_title': TextEditingController(text: _getEmpValue(['job_title', 'position', 'job']) ?? ''),
    'housing_name': TextEditingController(text: _getEmpValue(['housing.name', 'housing_name', 'housing']) ?? ''),
    'building_id': TextEditingController(text: _getEmpValue(['building_id', 'building']) ?? ''),
    'floor_id': TextEditingController(text: _getEmpValue(['floor_id', 'floor']) ?? ''),
    'room_id': TextEditingController(text: _getEmpValue(['room_id', 'room']) ?? ''),
    'project_name': TextEditingController(text: _getEmpValue(['project_name', 'project']) ?? ''),
    'project_code': TextEditingController(text: _getEmpValue(['project_code']) ?? ''),
    'contract_id': TextEditingController(text: _getEmpValue(['contract_id', 'contract']) ?? ''),
    'phone_number': TextEditingController(text: _getEmpValue(['phone_number', 'phone', 'mobile']) ?? ''),
    'email': TextEditingController(text: _getEmpValue(['email']) ?? ''),
    'joining_date': TextEditingController(
        text: (_getEmpValue(['joining_date', 'joined_at']) != null)
            ? _getEmpValue(['joining_date', 'joined_at'])!.split(' ')[0]
            : ''),
    'left_date': TextEditingController(
        text: (_getEmpValue(['left_date', 'left_at']) != null)
            ? _getEmpValue(['left_date', 'left_at'])!.split(' ')[0]
            : ''),
    'cases_issues': TextEditingController(text: _getEmpValue(['cases_issues', 'cases', 'issues']) ?? ''),
    'note': TextEditingController(text: _getEmpValue(['note', 'notes']) ?? ''),
  };

  // Debug: print resolved controller initial values
  debugPrint('🔎 Resolved employee fields:');
  _controllers.forEach((k, c) => debugPrint('  $k => "${c.text}"'));
}

  // --- Helper Widgets ---

Widget _buildTextField(
  TextEditingController controller, 
  String label, 
  {bool required = false, TextInputType? keyboardType, int maxLines = 1} // Added parameters
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: TextFormField(
      controller: controller,
      enabled: !widget.isReadOnly,
      keyboardType: keyboardType, // Use keyboard type
      maxLines: maxLines, // Allow multi-line for notes
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
        filled: widget.isReadOnly,
        fillColor: widget.isReadOnly ? Colors.grey[100] : null,
      ),
      validator: required ? (v) => v!.isEmpty ? 'This field is required' : null : null,
    ),
  );
}
  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        // ✅ Fix: Disable interaction if readOnly
        onChanged: widget.isReadOnly ? null : (value) {
          setState(() => _selectedGender = value ?? 'Male');
        },
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
        ],
        decoration: InputDecoration(
          labelText: 'Gender *',
          border: const OutlineInputBorder(),
          filled: widget.isReadOnly,
          fillColor: widget.isReadOnly ? Colors.grey[100] : null,
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: true, // Dates should always be readOnly to force picker
        enabled: !widget.isReadOnly,
        onTap: widget.isReadOnly ? null : () => _selectDate(controller, label),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: widget.isReadOnly ? null : const Icon(Icons.calendar_today),
          filled: widget.isReadOnly,
          fillColor: widget.isReadOnly ? Colors.grey[100] : null,
        ),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller, String label) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toString().split(' ')[0];
      });
    }
  }

@override
  Widget build(BuildContext context) {
    String title = widget.isReadOnly 
        ? 'Employee Details' 
        : (widget.employee == null ? 'Add New Employee' : 'Edit Employee');

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Personal Information ---
                const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),
                
               Row(
  children: [
    Expanded(
      child: _buildTextField(_controllers['id_name']!, 'Full Name', required: true),
    ),
    const SizedBox(width: 10), // Add some space between them
    Expanded(
      child: _buildTextField(_controllers['iqamah_number']!, 'Iqamah Number', required: true),
    ),
  ],
),

                Row(
                  children: [
                    Expanded(child: _buildGenderDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_controllers['nationality']!, 'Nationality')),
                  ],
                ),

                Row(
                  children: [
                     Expanded(child: _buildTextField(_controllers['passport_number']!, 'Passport Number')), // Added
                     const SizedBox(width: 10),
                     Expanded(child: _buildTextField(_controllers['phone_number']!, 'Phone')),
                  ],
                ),
                _buildTextField(_controllers['email']!, 'Email Address'), // Added

                const Divider(height: 30),

                // --- 2. Job & Contract Details ---
                const Text("Job Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),

                _buildTextField(_controllers['job_title']!, 'Job Title'),
                
                Row(
                  children: [
                    Expanded(child: _buildTextField(_controllers['project_name']!, 'Project Name')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_controllers['project_code']!, 'Project Code')), // Added
                  ],
                ),

                _buildTextField(_controllers['contract_id']!, 'Contract ID'), // Added

                Row(
                  children: [
                    Expanded(child: _buildDateField(_controllers['joining_date']!, 'Joining Date')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDateField(_controllers['left_date']!, 'Left Date')), // Added
                  ],
                ),

                const Divider(height: 30),

                // --- 3. Housing Details ---
                const Text("Housing Location", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),

                _buildTextField(_controllers['housing_name']!, 'Housing Complex Name'),
                
                Row(
                  children: [
                    Expanded(child: _buildTextField(_controllers['building_id']!, 'Building ID')), // Added
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_controllers['floor_id']!, 'Floor ID')), // Added
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_controllers['room_id']!, 'Room ID')), // Added
                  ],
                ),

                const Divider(height: 30),

                // --- 4. Other Info ---
                const Text("Additional Info", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),
                
               _buildTextField(_controllers['cases_issues']!, 'Cases / Issues', maxLines: 3),
            _buildTextField(_controllers['note']!, 'Notes', maxLines: 3),
            
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isReadOnly ? 'Close' : 'Cancel'),
        ),
        if (!widget.isReadOnly)
          ElevatedButton(
            onPressed: _isSaving ? null : _saveEmployee,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Employee'),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

 Future<void> _saveEmployee() async {
  FocusScope.of(context).unfocus(); // This hides the keyboard
    // 1. Validate form fields first
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    setState(() => _isSaving = true);

    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    
    // 2. Convert Gender to Arabic for API [cite: 342-343]
    String genderForApi = _selectedGender == 'Male' ? 'ذكر' : 'أنثى';

    // Helper to handle empty strings as nulls for optional DB fields
    String? nullIfEmpty(String key) {
      final val = _controllers[key]!.text.trim();
      return val.isEmpty ? null : val;
    }

    // 3. Prepare the data map [cite: 343-346]
    // Ensure these keys match your backend column names exactly
    final Map<String, dynamic> data = {
      'sn': nullIfEmpty('sn'),
      'id_name': _controllers['id_name']!.text.trim(),
      'iqamah_number': _controllers['iqamah_number']!.text.trim(),
      'id_number': nullIfEmpty('id_number'),
      'nationality': nullIfEmpty('nationality'),
      'passport_number': nullIfEmpty('passport_number'),
      'gender': genderForApi,
      'job_title': nullIfEmpty('job_title'),
      'housing_name': nullIfEmpty('housing_name'), // Fixed: now handles empty correctly
      'building_id': nullIfEmpty('building_id'),
      'floor_id': nullIfEmpty('floor_id'),
      'room_id': nullIfEmpty('room_id'),
      'project_name': nullIfEmpty('project_name'),
      'project_code': nullIfEmpty('project_code'),
      'contract_id': nullIfEmpty('contract_id'),
      'phone_number': nullIfEmpty('phone_number'),
      'email': nullIfEmpty('email'),
      'joining_date': nullIfEmpty('joining_date'),
      'left_date': nullIfEmpty('left_date'),
      'cases_issues': nullIfEmpty('cases_issues'),
      'note': nullIfEmpty('note'),
    };

    debugPrint('📤 Sending data to API: $data');

    try {
      Map<String, dynamic> result;
      
      if (widget.employee == null) {
        // CREATE MODE [cite: 349]
        debugPrint('➕ Creating new employee...');
        result = await provider.createEmployee(data);
      } else {
        // UPDATE MODE [cite: 350]
      final int id = int.tryParse(widget.employee!['id'].toString()) ?? 0;
        debugPrint('✏️ Updating employee with ID: $id');
        result = await provider.updateEmployee(id, data);
      }
      
      debugPrint('📥 API Response: $result');
      
      if (result['success'] == true) {
        debugPrint('✅ Employee saved successfully');
        widget.onSaved(); // Refresh list [cite: 352]
        Navigator.pop(context); // Close dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Handle API-side error messages
        debugPrint('❌ Failed to save: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔥 Critical Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Critical Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
