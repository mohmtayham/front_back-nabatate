import 'package:flutter/material.dart';
import 'package:nabtatcompany/providers/screens/RemindersListScreen.dart';
import 'package:nabtatcompany/providers/screens/employee_filter_screen.dart';
import 'package:nabtatcompany/providers/screens/meters_screen.dart';
import 'package:nabtatcompany/providers/screens/GeneratorsListScreen.dart'; // Added Generators screen
import 'package:provider/provider.dart';
import 'package:nabtatcompany/providers/screens/employees/employee_list_screen.dart';
import 'package:nabtatcompany/providers/employee_filter_provider.dart';
import 'package:nabtatcompany/providers/auth_provider.dart';
import 'package:nabtatcompany/core/guarded_screen.dart';
import 'package:nabtatcompany/generated/l10n.dart';
import 'package:nabtatcompany/services/auth_service.dart';

import 'login_screen.dart';
import 'users_screen.dart';
import 'housings_screen.dart';
import 'buildings_screen.dart';
import 'rooms_screen.dart';
import 'projects_screen.dart';

// تعريف فئة مساعدة لتخزين معلومات القائمة
class MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final Color color;
  final String? permission; // 🔥 NEW
  final bool isProviderWrapped;


  MenuItem({
    required this.title, 
    required this.icon, 
    required this.screen, 
    this.color = Colors.white,
    this.permission,
    this.isProviderWrapped = false,
  });
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _userName = 'Admin';

  late final List<MenuItem> _menuItems;

  String _currentScreenTitle = 'employees';
 late Widget _currentScreen;

@override
void initState() {
  super.initState();
  _initializeMenuItems();

  _currentScreen = _menuItems
      .first
      .screen; // أول شاشة مسموحة فقط
}



 
  void _initializeMenuItems() {
    _menuItems = [
      // العناصر الأساسية التي كانت موجودة في GridView
      MenuItem(title: 'users', icon: Icons.people, screen: const UsersScreen(), color: const Color(0xFF4A90E2)),
      MenuItem(title: 'housing', icon: Icons.home, screen: const HousingsScreen(), color: Colors.green),
      MenuItem(title: 'buildings', icon: Icons.business, screen: const BuildingsScreen(), color: Colors.orange),
      MenuItem(title: 'rooms', icon: Icons.meeting_room, screen: const RoomsScreen(), color: Colors.purple),
    // ابحث عن عنصر Employees وقم بتعديله هكذا:
MenuItem(
  title: 'employees', 
  icon: Icons.person, 
  screen: const GuardedScreen(
    module: 'employees', // 👈 استخدم الموديل
    action: 'view',      // 👈 استخدم الأكشن
    child: EmployeeListScreen(),
  ),
  permission: 'view_employees', // 👈 تأكد أن هذا يطابق ما في قاعدة البيانات
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
        isProviderWrapped: true,
      ),
      MenuItem(title: 'projects', icon: Icons.work, screen: const ProjectsScreen(), color: Colors.brown),
      MenuItem(title: 'meters', icon: Icons.speed, screen: const MetersScreen(), color: Colors.blueGrey),
      MenuItem(title: 'payment_reminders', icon: Icons.notifications, screen: const RemindersListScreen(), color: Colors.pink),
      MenuItem(title: 'generators', icon: Icons.electrical_services, screen: const GeneratorsListScreen(), color: Colors.amber),
      
      // العناصر التي كانت تظهر "Coming Soon"
      MenuItem(title: 'reports', icon: Icons.analytics, screen: _buildComingSoonWidget('Reports Screen'), color: Colors.indigo),
      MenuItem(title: 'settings', icon: Icons.settings, screen: _buildComingSoonWidget('Settings Screen'), color: Colors.grey[700]!),
      MenuItem(title: 'maintenance', icon: Icons.build, screen: _buildComingSoonWidget('Maintenance Screen'), color: Colors.cyan),
      MenuItem(title: 'contracts', icon: Icons.description, screen: _buildComingSoonWidget('Contracts Screen'), color: Colors.deepOrange),
      MenuItem(title: 'invoices', icon: Icons.receipt, screen: _buildComingSoonWidget('Invoices Screen'), color: Colors.lightGreen),
      MenuItem(title: 'statistics', icon: Icons.bar_chart, screen: _buildComingSoonWidget('Statistics Screen'), color: Colors.pinkAccent),
      // تم إضافة 'Issues' يدوياً للمطابقة مع الصورة
      MenuItem(title: 'issues', icon: Icons.warning, screen: _buildComingSoonWidget('Issues Screen'), color: Colors.red),
    ];
    
    // تعيين الشاشة الافتراضية — استخدم orElse لتجنب استثناءات عندما لا توجد قيمة
    _currentScreen = _menuItems.firstWhere(
      (item) => item.title == _currentScreenTitle,
      orElse: () => _menuItems.first,
    ).screen;
  }


  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    setState(() => _userName = name.toLowerCase());
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToScreen(String title) {
    setState(() {
      _currentScreenTitle = title;
      // البحث عن الشاشة المقابلة وتحديثها
      _currentScreen = _menuItems.firstWhere(
        (item) => item.title == title,
        orElse: () => _menuItems.first,
      ).screen;
    });
  }
  
  // دالة مساعدة لبناء عنصر القائمة في الشريط الجانبي
  Widget _buildSidebarItem(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return Container(
      color: isSelected ? Colors.white : Colors.transparent,
      child: Material(
        color: isSelected ? Colors.white : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.grey[700] : Colors.white),
                const SizedBox(width: 8),
                Text(
                  _menuLabel(title),
                  style: TextStyle(
                    color: isSelected ? Colors.grey[700] : Colors.white,
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

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE6E6E6), 
        foregroundColor: Colors.black,
        minimumSize: const Size(80, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(title),
    );
  }

  // دالة مساعدة لعرض "قريباً" في المحتوى الرئيسي
  Widget _buildComingSoonWidget(String featureName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.build_circle, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            '$featureName is under development (Coming Soon)',
            style: const TextStyle(fontSize: 20, color: Colors.grey),
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
   final user = context.watch<AuthProvider>().user;

final visibleMenuItems = _menuItems.where((item) {
  // No permission → always show
  if (item.permission == null) return true;

  // Not logged in → hide
  if (user == null) return false;

  // Admin → show everything
  if (user.type == 'admin') return true;

  // Normal user → check permission
  return user.can(item.permission!);
}).toList();


    return Scaffold(
      // لا يوجد AppBar هنا، يتم تضمين شريط العنوان في تخطيط Row
      body: Row(
        children: [
          // 1. الشريط الجانبي (Sidebar)
          Container(
            width: 220, 
            color: const Color(0xFF2C3E50), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // رأس الشريط الجانبي (الشعار)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  height: 60,
                  color: const Color(0xFF2E8B57), 
                  alignment: Alignment.centerLeft,
                  child: Text(
                    S.of(context).appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                // قائمة عناصر التنقل الأصلية
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                     ...visibleMenuItems.map((item) {

                        final isSelected = item.title == _currentScreenTitle;
                        return _buildSidebarItem(
                          item.title,
                          item.icon,
                          isSelected,
                          () {
                            // تم توحيد منطق التنقل حيث أن _currentScreen سيتم تحديثه بالشاشة الفعلية مباشرة.
                            // لا نحتاج للتعامل مع isProviderWrapped هنا، لأن الشاشة الفعلية (سواء كانت مغلفة بـ Provider أو لا) هي من يتم تخزينها في قائمة _menuItems
                            _navigateToScreen(item.title);
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white38),
                
                // زر تسجيل الخروج
                _buildSidebarItem(
                  'logout',
                  Icons.logout,
                  false,
                  _logout,
                ),
              ],
            ),
          ),

          // 2. محتوى الشاشة الرئيسي (Main Content)
          Expanded(
            child: Container(
              color: Colors.grey[100], 
              // **التغيير هنا:** يتم عرض الشاشة الفعلية (_currentScreen) مباشرة بغض النظر عن العنوان،
              // وبالتالي يتم استرداد EmployeeListScreen() عندما يكون _currentScreenTitle == 'Employees'.
              child: _currentScreen,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$featureName is under development'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}