// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ar';

  static String m0(error) => "خطأ: ${error}";

  static String m1(error) => "خطأ في الطباعة: ${error}";

  static String m2(email) => "تسجيل الدخول كـ @email";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accessDenied": MessageLookupByLibrary.simpleMessage(
            "ليس لديك صلاحية للوصول إلى هذه الصفحة"),
        "action_attachments": MessageLookupByLibrary.simpleMessage("المرفقات"),
        "action_delete": MessageLookupByLibrary.simpleMessage("حذف"),
        "action_edit": MessageLookupByLibrary.simpleMessage("تعديل"),
        "action_view_details":
            MessageLookupByLibrary.simpleMessage("عرض التفاصيل"),
        "addNewEmployee":
            MessageLookupByLibrary.simpleMessage("إضافة موظف جديد"),
        "addUser": MessageLookupByLibrary.simpleMessage("إضافة مستخدم"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "شركة نبات للمقاولات\nنظام إدارة السكن"),
        "appName": MessageLookupByLibrary.simpleMessage("نظام إدارة الشركة"),
        "backToDashboard":
            MessageLookupByLibrary.simpleMessage("العودة للوحة التحكم"),
        "cancel": MessageLookupByLibrary.simpleMessage("إلغاء"),
        "casesIssues":
            MessageLookupByLibrary.simpleMessage("الحالات / المشاكل"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("تغيير كلمة المرور"),
        "clearFilters": MessageLookupByLibrary.simpleMessage("مسح الفلاتر"),
        "close": MessageLookupByLibrary.simpleMessage("إغلاق"),
        "col_actions": MessageLookupByLibrary.simpleMessage("الإجراءات"),
        "col_id": MessageLookupByLibrary.simpleMessage("معرّف"),
        "col_id_number": MessageLookupByLibrary.simpleMessage("رقم الهوية"),
        "col_iqamah": MessageLookupByLibrary.simpleMessage("الإقامة"),
        "col_name": MessageLookupByLibrary.simpleMessage("الاسم"),
        "col_nationality": MessageLookupByLibrary.simpleMessage("الجنسية"),
        "col_phone": MessageLookupByLibrary.simpleMessage("الهاتف"),
        "col_sn": MessageLookupByLibrary.simpleMessage("الرقم التسلسلي"),
        "confirmDeleteUserContent": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من حذف هذا المستخدم؟"),
        "confirmDeleteUserTitle":
            MessageLookupByLibrary.simpleMessage("حذف المستخدم"),
        "copyright": MessageLookupByLibrary.simpleMessage(
            "© 2025 | مطور بواسطة أحمد العطوم"),
        "dashboardTitle": MessageLookupByLibrary.simpleMessage("لوحة التحكم"),
        "delete": MessageLookupByLibrary.simpleMessage("حذف"),
        "editEmployee": MessageLookupByLibrary.simpleMessage("تعديل الموظف"),
        "employeeDetails":
            MessageLookupByLibrary.simpleMessage("تفاصيل الموظف"),
        "employeesTitle": MessageLookupByLibrary.simpleMessage("الموظفين"),
        "enterUsername":
            MessageLookupByLibrary.simpleMessage("أدخل اسم المستخدم أو البريد"),
        "error_generic": m0,
        "error_print": m1,
        "filterEmployeesTitle":
            MessageLookupByLibrary.simpleMessage("فلترة الموظفين"),
        "forbidden_add": MessageLookupByLibrary.simpleMessage(
            "غير مسموح: ليس لديك صلاحية الإضافة"),
        "forbidden_delete": MessageLookupByLibrary.simpleMessage(
            "غير مسموح: ليس لديك صلاحية الحذف"),
        "forbidden_edit": MessageLookupByLibrary.simpleMessage(
            "غير مسموح: ليس لديك صلاحية التعديل"),
        "forbidden_export": MessageLookupByLibrary.simpleMessage(
            "غير مسموح: ليس لديك صلاحية التصدير"),
        "forbidden_import": MessageLookupByLibrary.simpleMessage(
            "غير مسموح: ليس لديك صلاحية الاستيراد"),
        "forbidden_print": MessageLookupByLibrary.simpleMessage(
            "غير مسموح: ليس لديك صلاحية طباعة الموظفين"),
        "forbidden_view": MessageLookupByLibrary.simpleMessage(
            "غير مسموح: ليس لديك صلاحية العرض"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("نسيت كلمة المرور؟"),
        "fullName": MessageLookupByLibrary.simpleMessage("الاسم الكامل"),
        "gender": MessageLookupByLibrary.simpleMessage("الجنس"),
        "generatorsTitle": MessageLookupByLibrary.simpleMessage("المولدات"),
        "housing": MessageLookupByLibrary.simpleMessage("السكن"),
        "idNumber": MessageLookupByLibrary.simpleMessage("رقم الهوية"),
        "iqamahNumber": MessageLookupByLibrary.simpleMessage("رقم الإقامة"),
        "jobTitle": MessageLookupByLibrary.simpleMessage("المسمى الوظيفي"),
        "joiningDate": MessageLookupByLibrary.simpleMessage("تاريخ الانضمام"),
        "leavingDate": MessageLookupByLibrary.simpleMessage("تاريخ المغادرة"),
        "loginAs": m2,
        "logout": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
        "metersTitle": MessageLookupByLibrary.simpleMessage("العدادات"),
        "nationality": MessageLookupByLibrary.simpleMessage("الجنسية"),
        "noEmployeesFound":
            MessageLookupByLibrary.simpleMessage("لم يتم العثور على موظفين"),
        "noUsersYet":
            MessageLookupByLibrary.simpleMessage("لا يوجد مستخدمين بعد"),
        "notes": MessageLookupByLibrary.simpleMessage("ملاحظات"),
        "passportNumber": MessageLookupByLibrary.simpleMessage("رقم الجواز"),
        "password": MessageLookupByLibrary.simpleMessage("كلمة المرور"),
        "paymentRemindersTitle":
            MessageLookupByLibrary.simpleMessage("تذكيرات الدفع"),
        "phone": MessageLookupByLibrary.simpleMessage("الهاتف"),
        "pressAddToCreateUser": MessageLookupByLibrary.simpleMessage(
            "اضغط على زر (+) لإضافة مستخدم جديد"),
        "projectName": MessageLookupByLibrary.simpleMessage("اسم المشروع"),
        "refreshList": MessageLookupByLibrary.simpleMessage("تحديث القائمة"),
        "rememberMe": MessageLookupByLibrary.simpleMessage("تذكرني"),
        "required": MessageLookupByLibrary.simpleMessage("مطلوب"),
        "saveEmployee": MessageLookupByLibrary.simpleMessage("حفظ الموظف"),
        "search": MessageLookupByLibrary.simpleMessage("بحث"),
        "searchHint": MessageLookupByLibrary.simpleMessage(
            "بحث بالاسم أو الهوية أو الوظيفة..."),
        "serialNumber": MessageLookupByLibrary.simpleMessage("الرقم التسلسلي"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("انتهت صلاحية الجلسة"),
        "signIn": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
        "snack_save_failed":
            MessageLookupByLibrary.simpleMessage("فشل في الحفظ"),
        "snack_save_success":
            MessageLookupByLibrary.simpleMessage("تم الحفظ بنجاح"),
        "useAnotherAccount":
            MessageLookupByLibrary.simpleMessage("استخدام حساب آخر"),
        "userAddedSuccess":
            MessageLookupByLibrary.simpleMessage("تم إضافة المستخدم بنجاح"),
        "userDeletedSuccess":
            MessageLookupByLibrary.simpleMessage("تم حذف المستخدم بنجاح"),
        "userUpdatedSuccess":
            MessageLookupByLibrary.simpleMessage("تم تحديث المستخدم بنجاح"),
        "usernameOrEmail":
            MessageLookupByLibrary.simpleMessage("اسم المستخدم أو البريد"),
        "usersManagementTitle":
            MessageLookupByLibrary.simpleMessage("إدارة المستخدمين"),
        "usersTitle": MessageLookupByLibrary.simpleMessage("المستخدمين"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("مرحباً بعودتك")
      };
}
