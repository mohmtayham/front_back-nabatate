import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/project_model.dart';
import 'package:nabtatcompany/services/auth_service.dart';
import 'package:nabtatcompany/services/project_service.dart';

import 'login_screen.dart';
import 'admin_dashboard.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool _loading = true;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final projects = await ProjectService.getProjects(search: _filterText.isNotEmpty ? _filterText : null);
      setState(() {
        _projects = projects;
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

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProjectDialog(
        onProjectAdded: () {
          _loadProjects();
          _showSuccess('تم إضافة المشروع بنجاح');
        },
      ),
    );
  }

  void _showEditProjectDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => EditProjectDialog(
        project: project,
        onProjectUpdated: () {
          _loadProjects();
          _showSuccess('تم تحديث المشروع بنجاح');
        },
      ),
    );
  }

  Future<void> _deleteProject(int projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المشروع'),
        content: const Text('هل أنت متأكد من حذف هذا المشروع؟'),
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
        await ProjectService.deleteProject(projectId);
        await _loadProjects();
        _showSuccess('تم حذف المشروع بنجاح');
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  List<Project> get _filteredProjects {
    if (_filterText.isEmpty) return _projects;
    
    final filter = _filterText.toLowerCase();
    
    return _projects.where((project) {
      final name = project.name.toLowerCase();
      final code = project.code.toLowerCase();
      final managerName = project.managerName?.toLowerCase() ?? '';
      
      return name.contains(filter) || 
             code.contains(filter) ||
             managerName.contains(filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المشاريع'),
        backgroundColor: const Color(0xFF2C3E50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToDashboard,
          tooltip: 'العودة للوحة التحكم',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
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
                      'بحث في المشاريع:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم المشروع أو الكود أو المدير',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _filterText.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _filterText = '');
                                  _loadProjects();
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() => _filterText = value);
                        // بحث تلقائي بعد تأخير
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_filterText == value) {
                            _loadProjects();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'عدد المشاريع: ${_filteredProjects.length}',
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
                : _projects.isEmpty
                    ? _buildEmptyState()
                    : _buildProjectList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
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
          const Icon(Icons.work_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'لا يوجد مشاريع بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'اضغط على زر (+) لإضافة مشروع جديد',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showAddProjectDialog,
            child: const Text('إضافة أول مشروع'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProjects.length,
        itemBuilder: (context, index) {
          final project = _filteredProjects[index];
          return _buildProjectCard(project);
        },
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showEditProjectDialog(project),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: project.statusColor.withOpacity(0.2),
                radius: 25,
                child: Icon(
                  project.statusIcon,
                  color: project.statusColor,
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
                            project.name,
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
                            color: project.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: project.statusColor),
                          ),
                          child: Text(
                            project.status,
                            style: TextStyle(
                              color: project.statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    _buildInfoRow('الكود:', project.code),
                    
                    if (project.location != null && project.location!.isNotEmpty)
                      _buildInfoRow('الموقع:', project.location!),
                    
                    if (project.managerName != null && project.managerName!.isNotEmpty)
                      _buildInfoRow('مدير المشروع:', project.managerName!),
                    
                    if (project.notes != null && project.notes!.isNotEmpty)
                      _buildInfoRow('ملاحظات:', project.notes!),
                  ],
                ),
              ),
              
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditProjectDialog(project),
                    tooltip: 'تعديل المشروع',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProject(project.id),
                    tooltip: 'حذف المشروع',
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

class AddProjectDialog extends StatefulWidget {
  final VoidCallback onProjectAdded;

  const AddProjectDialog({
    super.key,
    required this.onProjectAdded,
  });

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedStatus = 'قائم';
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'منتهي',
    'قائم',
    'سلم',
    'يتمدد'
  ];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ProjectService.addProject(
          name: _nameController.text,
          code: _codeController.text,
          location: _locationController.text.isNotEmpty ? _locationController.text : null,
          managerName: _managerNameController.text.isNotEmpty ? _managerNameController.text : null,
          status: _selectedStatus,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        Navigator.pop(context);
        widget.onProjectAdded();
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
                    'إضافة مشروع جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المشروع *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم المشروع'),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'كود المشروع *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'كود المشروع'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة المشروع *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: _statusOptions.map((status) {
                    Color statusColor;
                    switch (status) {
                      case 'منتهي':
                        statusColor = Colors.green;
                        break;
                      case 'قائم':
                        statusColor = Colors.blue;
                        break;
                      case 'سلم':
                        statusColor = Colors.orange;
                        break;
                      case 'يتمدد':
                        statusColor = Colors.purple;
                        break;
                      default:
                        statusColor = Colors.grey;
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
                
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'الموقع',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _managerNameController,
                  decoration: const InputDecoration(
                    labelText: 'مدير المشروع',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
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
                            : const Text('إضافة المشروع'),
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
    _codeController.dispose();
    _locationController.dispose();
    _managerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class EditProjectDialog extends StatefulWidget {
  final Project project;
  final VoidCallback onProjectUpdated;

  const EditProjectDialog({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.project.name);
  late final _codeController = TextEditingController(text: widget.project.code);
  late final _locationController = TextEditingController(text: widget.project.location ?? '');
  late final _managerNameController = TextEditingController(text: widget.project.managerName ?? '');
  late final _notesController = TextEditingController(text: widget.project.notes ?? '');
  late String _selectedStatus = widget.project.status;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'منتهي',
    'قائم',
    'سلم',
    'يتمدد'
  ];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ProjectService.updateProject(
          id: widget.project.id,
          name: _nameController.text,
          code: _codeController.text,
          location: _locationController.text.isNotEmpty ? _locationController.text : null,
          managerName: _managerNameController.text.isNotEmpty ? _managerNameController.text : null,
          status: _selectedStatus,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        Navigator.pop(context);
        widget.onProjectUpdated();
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
                    'تعديل المشروع',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المشروع *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'اسم المشروع'),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'كود المشروع *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) => _validateRequired(value, 'كود المشروع'),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة المشروع *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: _statusOptions.map((status) {
                    Color statusColor;
                    switch (status) {
                      case 'منتهي':
                        statusColor = Colors.green;
                        break;
                      case 'قائم':
                        statusColor = Colors.blue;
                        break;
                      case 'سلم':
                        statusColor = Colors.orange;
                        break;
                      case 'يتمدد':
                        statusColor = Colors.purple;
                        break;
                      default:
                        statusColor = Colors.grey;
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
                
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'الموقع',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _managerNameController,
                  decoration: const InputDecoration(
                    labelText: 'مدير المشروع',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
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
    _codeController.dispose();
    _locationController.dispose();
    _managerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}