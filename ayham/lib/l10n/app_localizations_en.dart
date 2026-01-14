// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get appDescription => 'Nabtat Company for Contracting\nAccommodation Management System';

  @override
  String get usernameOrEmail => 'Username or Email';

  @override
  String get enterUsername => 'Enter your username or email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'SIGN IN';

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String loginAs(Object email) {
    return 'Login as @email';
  }

  @override
  String get required => 'Required';

  @override
  String get sessionExpired => 'Session expired';

  @override
  String get copyright => '© 2025 | Developed by Ahmad Al-Atoum';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get usersTitle => 'Users';

  @override
  String get employeesTitle => 'Employees';

  @override
  String get metersTitle => 'Meters';

  @override
  String get paymentRemindersTitle => 'Payment Reminders';

  @override
  String get generatorsTitle => 'Generators';

  @override
  String get appName => 'Company Management System';

  @override
  String get changePassword => 'Change Password';
}
