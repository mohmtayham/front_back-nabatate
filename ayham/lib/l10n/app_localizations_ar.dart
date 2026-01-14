// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get appDescription => 'شركة نبات للمقاولات\nنظام إدارة السكن';

  @override
  String get usernameOrEmail => 'اسم المستخدم أو البريد';

  @override
  String get enterUsername => 'أدخل اسم المستخدم أو البريد';

  @override
  String get password => 'كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get useAnotherAccount => 'استخدام حساب آخر';

  @override
  String loginAs(Object email) {
    return 'تسجيل الدخول كـ @email';
  }

  @override
  String get required => 'مطلوب';

  @override
  String get sessionExpired => 'انتهت صلاحية الجلسة';

  @override
  String get copyright => '© 2025 | مطور بواسطة أحمد العطوم';

  @override
  String get dashboardTitle => 'لوحة التحكم';

  @override
  String get usersTitle => 'المستخدمين';

  @override
  String get employeesTitle => 'الموظفين';

  @override
  String get metersTitle => 'العدادات';

  @override
  String get paymentRemindersTitle => 'تذكيرات الدفع';

  @override
  String get generatorsTitle => 'المولدات';

  @override
  String get appName => 'نظام إدارة الشركة';

  @override
  String get changePassword => 'تغيير كلمة المرور';
}
