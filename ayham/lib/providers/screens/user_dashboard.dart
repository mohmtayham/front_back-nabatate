import 'package:flutter/material.dart';
import 'package:nabtatcompany/providers/screens/RemindersListScreen.dart';
import 'package:nabtatcompany/providers/screens/employee_filter_screen.dart';
import 'package:nabtatcompany/providers/screens/meters_screen.dart';
import 'package:nabtatcompany/providers/screens/GeneratorsListScreen.dart';
import 'package:provider/provider.dart';
import 'package:nabtatcompany/core/guarded_screen.dart';


import 'package:nabtatcompany/providers/screens/employees/employee_list_screen.dart';
import 'package:nabtatcompany/providers/screens/users_screen.dart';

import 'package:nabtatcompany/providers/employee_filter_provider.dart';
import 'package:nabtatcompany/services/auth_service.dart';
import 'package:nabtatcompany/providers/auth_provider.dart';
import 'package:nabtatcompany/generated/l10n.dart';


import 'login_screen.dart';

// نفس MenuItem (إعادة استخدام)
class MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final Color color;
 final List<String>? permission;

  MenuItem({
    required this.title,
    required this.icon,
    required this.screen,
    this.color = Colors.white,
    this.permission, // 👈 وأضف هذا هنا
  });
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String _userName = 'User';

  List<MenuItem> _menuItems = [];

  String _currentScreenTitle = 'Employees';
  Widget _currentScreen = const SizedBox.shrink();

@override
void initState() {
  super.initState();
  _initializeMenuItems();
}


  @override
 

  void _initializeMenuItems() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _menuItems = [
       MenuItem(
      title: 'users',
        icon: Icons.person,
        screen: const GuardedScreen(
          module: 'users',
          action: 'view',
          child: UsersScreen(),
        ),
        permission: ['view_users', 'view_all'],
        color: Colors.teal,
      ),
      MenuItem(
        title: 'employees',
        icon: Icons.person,
        screen: const GuardedScreen(
          module: 'employees',
          action: 'view',
          child: EmployeeListScreen(),
        ),
        permission: ['view_employees', 'view_all'],
        color: Colors.teal,
      ),
      MenuItem(
        title: 'employee_filter',
        icon: Icons.filter_alt,
        color: Colors.deepPurple,
        screen: ChangeNotifierProvider(
          create: (_) => EmployeeFilterProvider(),
          child: const EmployeeFilterScreen(),
        ),
      ),
      MenuItem(
        title: 'projects',
        icon: Icons.work,
        screen: _buildComingSoonWidget('Projects'),
        color: Colors.brown,
      ),
      MenuItem(
        title: 'meters',
        icon: Icons.speed, 
        screen: const MetersScreen(),
        color: Colors.blueGrey,
      ),
      MenuItem(
        title: 'payment_reminders',
        icon: Icons.notifications,
        screen: const RemindersListScreen(),
        color: Colors.pink,
      ),
      MenuItem(
        title: 'generators',
        icon: Icons.electrical_services,
        screen: const GeneratorsListScreen(),
        color: Colors.amber,
      ),
    ];

    // الفلترة: نأخذ فقط العناصر التي يملك المستخدم صلاحية "واحدة" منها على الأقل
  _menuItems = _menuItems.where((item) {
    if (item.permission == null) return true;
    // منطق الـ OR: إذا كان لديه index_employees "أو" لديه view
    return item.permission!.any((p) => authProvider.can(p));
  }).toList();

  // تحديث الشاشة الافتراضية لأول عنصر مسموح
  if (_menuItems.isNotEmpty) {
    _currentScreen = _menuItems.first.screen;
    _currentScreenTitle = _menuItems.first.title;
  }

   
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    setState(() => _userName = name.toLowerCase());
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToScreen(String title) {
    final item = _menuItems.firstWhere(
      (item) => item.title == title,
      orElse: () => MenuItem(
        title: 'NotFound',
        icon: Icons.error,
        screen: const Center(child: Text('Screen not available')),
      ),
    );
    if (item.title == 'NotFound') return;
    setState(() {
      _currentScreenTitle = title;
      _currentScreen = item.screen;
    });
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      color: isSelected ? Colors.white : Colors.transparent,
      child: Material(
        color: isSelected ? Colors.white : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    color: isSelected ? Colors.grey[700] : Colors.white),
                const SizedBox(width: 8),
                Text(
                  _menuLabel(title),
                  style: TextStyle(
                    color:
                        isSelected ? Colors.grey[700] : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonWidget(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.build_circle,
              size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            '$feature is under development',
            style:
                const TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _menuLabel(String id) {
    final s = S.of(context);
    switch (id) {
      case 'users':
        return s.usersTitle;
      case 'employees':
        return s.employeesTitle;
      case 'employee_filter':
        return s.filterEmployeesTitle;
      case 'projects':
        return 'Projects';
      case 'meters':
        return s.metersTitle;
      case 'payment_reminders':
        return s.paymentRemindersTitle;
      case 'generators':
        return s.generatorsTitle;
      case 'logout':
        return s.logout;
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF2C3E50),
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF2E8B57),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    S.of(context).appName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: _menuItems.map((item) {
                      final selected =
                          item.title == _currentScreenTitle;
                      return _buildSidebarItem(
                        item.title,
                        item.icon,
                        selected,
                        () => _navigateToScreen(item.title),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(color: Colors.white38),
                _buildSidebarItem(
                  'logout',
                  Icons.logout,
                  false,
                  _logout,
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _currentScreen,
            ),
          ),
        ],
      ),
    );
  }
}
