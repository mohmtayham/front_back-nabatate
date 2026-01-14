import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'package:nabtatcompany/providers/employee_provider.dart';
import 'package:nabtatcompany/providers/employee_filter_provider.dart';
import 'package:nabtatcompany/providers/meter_provider.dart';
import 'package:nabtatcompany/providers/auth_provider.dart';
import 'package:nabtatcompany/providers/payment_reminder_provider.dart';

import 'package:nabtatcompany/dialogs/change_password_dialog.dart';
import 'package:nabtatcompany/generated/l10n.dart';

import 'package:nabtatcompany/providers/screens/GeneratorsListScreen.dart';
import 'package:nabtatcompany/providers/screens/RemindersListScreen.dart';
import 'package:nabtatcompany/providers/screens/admin_dashboard.dart';
import 'package:nabtatcompany/providers/screens/employees/employee_list_screen.dart';
import 'package:nabtatcompany/providers/screens/login_screen.dart';
import 'package:nabtatcompany/providers/screens/users_screen.dart';
import 'package:nabtatcompany/providers/screens/meters_screen.dart';

import 'package:nabtatcompany/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  debugPrint = (String? message, {int? wrapWidth}) {
    if (kDebugMode) {
      print(message);
    }
  };

  runApp(const MyApp());
}

// ===================================================================
// ============================== APP ================================
// ===================================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeFilterProvider()),
        ChangeNotifierProvider(create: (_) => MeterProvider()),
        ChangeNotifierProvider(create: (_) => PaymentReminderProvider()),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: _locale,
                localizationsDelegates: const [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                theme: _getWindowsTheme(screenWidth),

                /// 🚨 IMPORTANT: DO NOT USE initialRoute with auth logic
                home: _getHomeScreen(auth),

                onGenerateRoute: (settings) {
                  return _generateRoute(settings, auth);
                },

                builder: (context, child) {
                  final updatedChild = MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      devicePixelRatio: _getWindowsDPR(screenWidth),
                      textScaleFactor: _getWindowsTextScale(screenWidth),
                    ),
                    child: child!,
                  );

                  final routeName =
                      ModalRoute.of(context)?.settings.name;

                  if (routeName == '/' || routeName == null) {
                    return updatedChild;
                  }

                  return Scaffold(
                    appBar: AppBar(
                      title: Text(_getPageTitle(context, routeName)),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.lock_outline, size: 20),
                          tooltip: S.of(context).changePassword,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  const ChangePasswordDialog(),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    body: updatedChild,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ===================================================================
  // ========================== ROUTING LOGIC ===========================
  // ===================================================================

  Widget _getHomeScreen(AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    if (auth.isAdmin) {
      return const AdminDashboard();
    }

    // ✅ NORMAL USER → EMPLOYEES ONLY
    return EmployeeListScreen();
  }

  Route _generateRoute(RouteSettings settings, AuthProvider auth) {
    switch (settings.name) {
      case '/dashboard':
        if (!auth.isAdmin) return _accessDenied();
        return MaterialPageRoute(builder: (_) => const AdminDashboard());

      case '/users':
        if (!auth.isAdmin) return _accessDenied();
        return MaterialPageRoute(builder: (_) => const UsersScreen());

      case '/employees':
        return MaterialPageRoute(builder: (_) => EmployeeListScreen());

      case '/meters':
        return MaterialPageRoute(builder: (_) => const MetersScreen());

      case '/payment-reminders':
        return MaterialPageRoute(builder: (_) => const RemindersListScreen());

      case '/generators':
        return MaterialPageRoute(builder: (_) => const GeneratorsListScreen());

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  Route _accessDenied() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text(
            '🚫 Access Denied',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // ========================= PAGE TITLES ==============================
  // ===================================================================

  String _getPageTitle(BuildContext context, String routeName) {
    final s = S.of(context);

    switch (routeName) {
      case '/dashboard':
        return s.dashboardTitle;
      case '/users':
        return s.usersTitle;
      case '/employees':
        return s.employeesTitle;
      case '/meters':
        return s.metersTitle;
      case '/payment-reminders':
        return s.paymentRemindersTitle;
      case '/generators':
        return s.generatorsTitle;
      default:
        return s.appName;
    }
  }

  // ===================================================================
  // ======================= THEME & SCALE ==============================
  // ===================================================================

  ThemeData _getWindowsTheme(double screenWidth) {
    final isSmall = screenWidth < 800;
    final baseFontSize = isSmall ? 12.0 : screenWidth < 1200 ? 14.0 : 16.0;

    return ThemeData(
      fontFamily: 'Cairo',
      useMaterial3: true,
      visualDensity:
          isSmall ? VisualDensity.compact : VisualDensity.standard,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: baseFontSize),
        bodyMedium: TextStyle(fontSize: baseFontSize - 2),
      ),
    );
  }

  double _getWindowsDPR(double screenWidth) {
    if (screenWidth >= 3840) return 2.0;
    if (screenWidth >= 2560) return 1.5;
    if (screenWidth >= 1920) return 1.25;
    return 1.0;
  }

  double _getWindowsTextScale(double screenWidth) {
    if (screenWidth < 800) return 0.9;
    if (screenWidth < 1200) return 1.0;
    return 1.1;
  }
}
