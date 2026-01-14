 import 'package:flutter/material.dart';
import 'package:nabtatcompany/services/auth_service.dart';
import 'package:nabtatcompany/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:nabtatcompany/providers/auth_provider.dart';

import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'package:nabtatcompany/generated/l10n.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _userName = 'Admin';
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUsers();
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

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    setState(() => _userName = name);
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final result = await UserService.getUsers();
    
    if (result['success'] == true) {
      // Remove the currently-logged-in user from the list so they cannot
      // modify their own permissions or change their password from here.
      final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
      final currentId = currentUser != null ? currentUser.id : null;

      List<dynamic> fetched = result['users'] ?? [];
      if (currentId != null) {
        fetched = fetched.where((u) => u['id'] != currentId).toList();
      }

      setState(() {
        _users = fetched;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _showError(result['message']);
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
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onUserAdded: () {
          _loadUsers();
          _showSuccess(S.of(context).userAddedSuccess);
        },
      ),
    );
  }

  void _showEditUserDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onUserUpdated: () {
          _loadUsers();
          _showSuccess(S.of(context).userUpdatedSuccess);
        },
      ),
    );
  }

  Future<void> _deleteUser(int userId) async {
      final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmDeleteUserTitle),
        content: Text(S.of(context).confirmDeleteUserContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await UserService.deleteUser(userId);
      if (result['success'] == true) {
        _loadUsers();
        _showSuccess(S.of(context).userDeletedSuccess);
      } else {
        _showError(result['message']);
      }
    }
  }

  void _goBackToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).usersManagementTitle),
        backgroundColor: const Color(0xFF2C3E50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToDashboard,
          tooltip: S.of(context).backToDashboard,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: S.of(context).addUser,
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: S.of(context).refreshList,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: S.of(context).logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      Text(S.of(context).noUsersYet),
                      const SizedBox(height: 20),
                      Text(S.of(context).pressAddToCreateUser),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF4A90E2),
                              child: Text(
                                user['name'][0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              user['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['email']),
                                const SizedBox(height: 4),
                                if (user['permissions'] != null && 
                                    (user['permissions'] as List).isNotEmpty)
                                  Text(
                                    '${(user['permissions'] as List).length} permissions',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                                    FutureBuilder<bool>(
                              future: AuthService.can('users', 'update'),
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'تعديل المستخدم', // التولتيب خاص بالأيقونة وليس بـ onPressed
                                    onPressed: () { // بداية الدالة
                                      // التحقق من الصلاحية عند الضغط
                                      if (_requirePermission(context, 'update_users', 'Forbidden: You do not have permission to update users')) {
                                        _showEditUserDialog(user);
                                      }
                                    }, // نهاية الدالة
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          //  ["view_all","add_employees","print_employees","update_employees","destroy_employees","update_users","store_users","destroy_users"]

                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user['id']),
                                  tooltip: 'حذف المستخدم',
                                ),
                              ],
                            ),
                            onTap: () => _showEditUserDialog(user),
                          ),
                        ),
                      );
                    },
                  ),
                            ),
                floatingActionButton: FutureBuilder<bool>(
              future: AuthService.can('users', 'create'),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return FloatingActionButton(
                    onPressed: _showAddUserDialog,
                    backgroundColor: const Color(0xFF4A90E2),
                    child: const Icon(Icons.add, color: Colors.white),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

                );
              }
}

// ✅ حوار إضافة مستخدم جديد - مبسط بدون مشاكل Render Box
class AddUserDialog extends StatefulWidget {
  final VoidCallback onUserAdded;

  const AddUserDialog({
    super.key,
    required this.onUserAdded,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // ✅ صلاحيات مبسطة: حذف، تعديل، إضافة، بحث، طباعة
 
// الجزء الذي يحتاج تعديل في Flutter
final Map<String, String> _simplePermissions = {
  // استخدم التسميات التي يتوقعها الـ Backend للتحويل التلقائي
  'view_all': 'view all screen', 
  'add': 'إضافة جديد',
  'update': 'تعديل',
  'destroy': 'حذف',
  
  // أو إذا أردت تخصيصاً دقيقاً لكل موديول (يفضل):
   'add_users': 'add user',
  'update_users': 'edit user',
  'destroy_users': 'delete user',
  'view_employees': 'عرض الموظفين',
  'store_employees': 'إضافة موظف',
  'update_employees': 'تعديل موظف',
  'destroy_employees': 'حذف موظف',
};

  
  final Set<String> _selectedPermissions = {};
  bool _isLoading = false;
  bool _giveAllPermissions = false;

  void _togglePermission(String permission, bool? value) {
    setState(() {
      if (value == true) {
        _selectedPermissions.add(permission);
      } else {
        _selectedPermissions.remove(permission);
      }
    });
  }

  void _toggleAllPermissions(bool? value) {
    setState(() {
      _giveAllPermissions = value ?? false;
      if (_giveAllPermissions) {
        _selectedPermissions.addAll(_simplePermissions.keys);
      } else {
        _selectedPermissions.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // ✅ تحويل الصلاحيات المبسطة إلى تنسيق Laravel
      List<String> permissions = [];
      
      if (_giveAllPermissions) {
  final List<String> allResources = [
    'users', 'employees', 'housings', 'buildings', 
    'rooms', 'projects', 'cases', 'meters', 
    'payment-reminders', 'generators'
  ];
  
  // Laravel Resource Actions
  final List<String> allActions = ['index', 'store', 'show', 'update', 'destroy', 'print', 'filter'];
  
  for (var resource in allResources) {
    for (var action in allActions) {
      permissions.add('${action}_${resource}');
    }
  }

      } else {
        // تحويل الصلاحيات المحددة
        for (var permission in _selectedPermissions) {
          // يمكنك هنا تحويل الصلاحيات المبسطة إلى الصيغة التي يتوقعها Laravel
          // لكن بناءً على طلبك، سنرسلها كما هي وسيتم حفظها في حقل permissions
          permissions.add(permission);
        }
      }

      final result = await UserService.addUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        permissions: permissions,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onUserAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                // العنوان
                const Center(
                  child: Text(
                    'إضافة مستخدم جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                // معلومات المستخدم الأساسية
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم المستخدم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'يرجى إدخال بريد إلكتروني صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 10),
                
                // ✅ صلاحيات مبسطة - بدون مشاكل Render Box
                const Text(
                  'صلاحيات المستخدم',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                // خيار منح كل الصلاحيات
                Card(
                  color: Colors.blue[50],
                  child: CheckboxListTile(
                    title: const Text(
                      'منح كل الصلاحيات',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _giveAllPermissions,
                    onChanged: _toggleAllPermissions,
                    secondary: const Icon(Icons.security, color: Colors.blue),
                  ),
                ),
                
                const SizedBox(height: 10),
                const Text('اختر الصلاحيات المطلوبة:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                
                // ✅ قائمة صلاحيات مبسطة مع GridView
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _simplePermissions.length,
                    itemBuilder: (context, index) {
                      final permissionKey = _simplePermissions.keys.elementAt(index);
                      final permissionLabel = _simplePermissions[permissionKey]!;
                      
                      return Card(
                        child: CheckboxListTile(
                          title: Text(permissionLabel),
                          value: _selectedPermissions.contains(permissionKey),
                          onChanged: (value) => _togglePermission(permissionKey, value),
                          dense: true,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
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
                            : const Text('إضافة المستخدم'),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ✅ حوار تعديل المستخدم - مبسط أيضاً
class EditUserDialog extends StatefulWidget {
  final dynamic user;
  final VoidCallback onUserUpdated;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
 final Map<String, String> _simplePermissions = {
  // Employees
  'view_all': 'عرض الكل', 

  'view_employees': 'عرض الموظفين',
  'add_employees': 'إضافة موظف',
  'update_employees': 'تعديل موظف',
  'destroy_employees': 'حذف موظف',
  'print_employees': 'طباعة الموظفين',

  'add_users': 'add user',
  'update_users': 'edit user',
  'destroy_users': 'delete user',
  // Other modules (اختياري)
  'view_users': 'عرض المستخدمين',
  'view_projects': 'عرض المشاريع',
  'view_meters': 'عرض العدادات',
  'view_generators': 'عرض المولدات',
};


  
  final Set<String> _selectedPermissions = {};
  bool _isLoading = false;
  bool _giveAllPermissions = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _nameController.text = widget.user['name'];
    _emailController.text = widget.user['email'];
    
    // تحميل الصلاحيات الحالية
    if (widget.user['permissions'] != null && widget.user['permissions'] is List) {
      final List<dynamic> userPermissions = widget.user['permissions'];
      
      // تحويل الصلاحيات القديمة إلى الصيغة المبسطة
      for (var permission in userPermissions) {
        if (_simplePermissions.containsKey(permission)) {
          _selectedPermissions.add(permission);
        }
      }
      
      // إذا كان لديه كل الصلاحيات القديمة
      if (userPermissions.length > 5) {
        _giveAllPermissions = true;
      }
    }
  }

  void _togglePermission(String permission, bool? value) {
    setState(() {
      if (value == true) {
        _selectedPermissions.add(permission);
      } else {
        _selectedPermissions.remove(permission);
      }
    });
  }

  void _toggleAllPermissions(bool? value) {
    setState(() {
      _giveAllPermissions = value ?? false;
      if (_giveAllPermissions) {
        _selectedPermissions.addAll(_simplePermissions.keys);
      } else {
        _selectedPermissions.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // تحويل الصلاحيات
      List<String> permissions = [];
      
      if (_giveAllPermissions) {
  final List<String> allResources = [
    'users', 'employees', 'housings', 'buildings', 
    'rooms', 'projects', 'cases', 'meters', 
    'payment-reminders', 'generators'
  ];
  
  // Laravel Resource Actions
  final List<String> allActions = ['index', 'store', 'show', 'update', 'destroy', 'print', 'filter'];
  
  for (var resource in allResources) {
    for (var action in allActions) {
      permissions.add('${action}_${resource}');
    }
  }
      } else {
        permissions = _selectedPermissions.toList();
      }

      final result = await UserService.updateUser(
        userId: widget.user['id'],
        name: _nameController.text,
        email: _emailController.text,
        password: _changePassword ? _passwordController.text : null,
        permissions: permissions,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onUserUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    'تعديل المستخدم',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم المستخدم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'يرجى إدخال بريد إلكتروني صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                Card(
                  child: CheckboxListTile(
                    title: const Text('تغيير كلمة المرور'),
                    value: _changePassword,
                    onChanged: (value) => setState(() => _changePassword = value ?? false),
                  ),
                ),
                
                if (_changePassword)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور الجديدة',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        validator: (value) {
                          if (_changePassword && (value == null || value.isEmpty)) {
                            return 'يرجى إدخال كلمة المرور';
                          }
                          if (_changePassword && value != null && value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                
                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 10),
                
                const Text(
                  'صلاحيات المستخدم',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                Card(
                  color: Colors.blue[50],
                  child: CheckboxListTile(
                    title: const Text('منح كل الصلاحيات'),
                    value: _giveAllPermissions,
                    onChanged: _toggleAllPermissions,
                    secondary: const Icon(Icons.security, color: Colors.blue),
                  ),
                ),
                
                const SizedBox(height: 10),
                const Text('اختر الصلاحيات المطلوبة:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _simplePermissions.length,
                    itemBuilder: (context, index) {
                      final permissionKey = _simplePermissions.keys.elementAt(index);
                      final permissionLabel = _simplePermissions[permissionKey]!;
                      
                      return Card(
                        child: CheckboxListTile(
                          title: Text(permissionLabel),
                          value: _selectedPermissions.contains(permissionKey),
                          onChanged: (value) => _togglePermission(permissionKey, value),
                          dense: true,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}