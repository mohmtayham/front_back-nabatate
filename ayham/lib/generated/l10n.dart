// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `مرحباً بعودتك`
  String get welcomeBack {
    return Intl.message(
      'مرحباً بعودتك',
      name: 'welcomeBack',
      desc: '',
      args: [],
    );
  }

  /// `شركة نبات للمقاولات\nنظام إدارة السكن`
  String get appDescription {
    return Intl.message(
      'شركة نبات للمقاولات\nنظام إدارة السكن',
      name: 'appDescription',
      desc: '',
      args: [],
    );
  }

  /// `اسم المستخدم أو البريد`
  String get usernameOrEmail {
    return Intl.message(
      'اسم المستخدم أو البريد',
      name: 'usernameOrEmail',
      desc: '',
      args: [],
    );
  }

  /// `أدخل اسم المستخدم أو البريد`
  String get enterUsername {
    return Intl.message(
      'أدخل اسم المستخدم أو البريد',
      name: 'enterUsername',
      desc: '',
      args: [],
    );
  }

  /// `كلمة المرور`
  String get password {
    return Intl.message(
      'كلمة المرور',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `تذكرني`
  String get rememberMe {
    return Intl.message(
      'تذكرني',
      name: 'rememberMe',
      desc: '',
      args: [],
    );
  }

  /// `نسيت كلمة المرور؟`
  String get forgotPassword {
    return Intl.message(
      'نسيت كلمة المرور؟',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `تسجيل الدخول`
  String get signIn {
    return Intl.message(
      'تسجيل الدخول',
      name: 'signIn',
      desc: '',
      args: [],
    );
  }

  /// `استخدام حساب آخر`
  String get useAnotherAccount {
    return Intl.message(
      'استخدام حساب آخر',
      name: 'useAnotherAccount',
      desc: '',
      args: [],
    );
  }

  /// `تسجيل الدخول كـ @email`
  String loginAs(Object email) {
    return Intl.message(
      'تسجيل الدخول كـ @email',
      name: 'loginAs',
      desc: 'زر الدخول السريع',
      args: [email],
    );
  }

  /// `مطلوب`
  String get required {
    return Intl.message(
      'مطلوب',
      name: 'required',
      desc: '',
      args: [],
    );
  }

  /// `انتهت صلاحية الجلسة`
  String get sessionExpired {
    return Intl.message(
      'انتهت صلاحية الجلسة',
      name: 'sessionExpired',
      desc: '',
      args: [],
    );
  }

  /// `© 2025 | مطور بواسطة أحمد العطوم`
  String get copyright {
    return Intl.message(
      '© 2025 | مطور بواسطة أحمد العطوم',
      name: 'copyright',
      desc: '',
      args: [],
    );
  }

  /// `لوحة التحكم`
  String get dashboardTitle {
    return Intl.message(
      'لوحة التحكم',
      name: 'dashboardTitle',
      desc: '',
      args: [],
    );
  }

  /// `المستخدمين`
  String get usersTitle {
    return Intl.message(
      'المستخدمين',
      name: 'usersTitle',
      desc: '',
      args: [],
    );
  }

  /// `الموظفين`
  String get employeesTitle {
    return Intl.message(
      'الموظفين',
      name: 'employeesTitle',
      desc: '',
      args: [],
    );
  }

  /// `العدادات`
  String get metersTitle {
    return Intl.message(
      'العدادات',
      name: 'metersTitle',
      desc: '',
      args: [],
    );
  }

  /// `تذكيرات الدفع`
  String get paymentRemindersTitle {
    return Intl.message(
      'تذكيرات الدفع',
      name: 'paymentRemindersTitle',
      desc: '',
      args: [],
    );
  }

  /// `المولدات`
  String get generatorsTitle {
    return Intl.message(
      'المولدات',
      name: 'generatorsTitle',
      desc: '',
      args: [],
    );
  }

  /// `نظام إدارة الشركة`
  String get appName {
    return Intl.message(
      'نظام إدارة الشركة',
      name: 'appName',
      desc: '',
      args: [],
    );
  }

  /// `تغيير كلمة المرور`
  String get changePassword {
    return Intl.message(
      'تغيير كلمة المرور',
      name: 'changePassword',
      desc: '',
      args: [],
    );
  }

  /// `ليس لديك صلاحية للوصول إلى هذه الصفحة`
  String get accessDenied {
    return Intl.message(
      'ليس لديك صلاحية للوصول إلى هذه الصفحة',
      name: 'accessDenied',
      desc: '',
      args: [],
    );
  }

  /// `غير مسموح: ليس لديك صلاحية طباعة الموظفين`
  String get forbidden_print {
    return Intl.message(
      'غير مسموح: ليس لديك صلاحية طباعة الموظفين',
      name: 'forbidden_print',
      desc: '',
      args: [],
    );
  }

  /// `غير مسموح: ليس لديك صلاحية الاستيراد`
  String get forbidden_import {
    return Intl.message(
      'غير مسموح: ليس لديك صلاحية الاستيراد',
      name: 'forbidden_import',
      desc: '',
      args: [],
    );
  }

  /// `غير مسموح: ليس لديك صلاحية التصدير`
  String get forbidden_export {
    return Intl.message(
      'غير مسموح: ليس لديك صلاحية التصدير',
      name: 'forbidden_export',
      desc: '',
      args: [],
    );
  }

  /// `غير مسموح: ليس لديك صلاحية الإضافة`
  String get forbidden_add {
    return Intl.message(
      'غير مسموح: ليس لديك صلاحية الإضافة',
      name: 'forbidden_add',
      desc: '',
      args: [],
    );
  }

  /// `غير مسموح: ليس لديك صلاحية الحذف`
  String get forbidden_delete {
    return Intl.message(
      'غير مسموح: ليس لديك صلاحية الحذف',
      name: 'forbidden_delete',
      desc: '',
      args: [],
    );
  }

  /// `غير مسموح: ليس لديك صلاحية العرض`
  String get forbidden_view {
    return Intl.message(
      'غير مسموح: ليس لديك صلاحية العرض',
      name: 'forbidden_view',
      desc: '',
      args: [],
    );
  }

  /// `غير مسموح: ليس لديك صلاحية التعديل`
  String get forbidden_edit {
    return Intl.message(
      'غير مسموح: ليس لديك صلاحية التعديل',
      name: 'forbidden_edit',
      desc: '',
      args: [],
    );
  }

  /// `إلغاء`
  String get cancel {
    return Intl.message(
      'إلغاء',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `إغلاق`
  String get close {
    return Intl.message(
      'إغلاق',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `حفظ الموظف`
  String get saveEmployee {
    return Intl.message(
      'حفظ الموظف',
      name: 'saveEmployee',
      desc: '',
      args: [],
    );
  }

  /// `تفاصيل الموظف`
  String get employeeDetails {
    return Intl.message(
      'تفاصيل الموظف',
      name: 'employeeDetails',
      desc: '',
      args: [],
    );
  }

  /// `إضافة موظف جديد`
  String get addNewEmployee {
    return Intl.message(
      'إضافة موظف جديد',
      name: 'addNewEmployee',
      desc: '',
      args: [],
    );
  }

  /// `تعديل الموظف`
  String get editEmployee {
    return Intl.message(
      'تعديل الموظف',
      name: 'editEmployee',
      desc: '',
      args: [],
    );
  }

  /// `الاسم الكامل`
  String get fullName {
    return Intl.message(
      'الاسم الكامل',
      name: 'fullName',
      desc: '',
      args: [],
    );
  }

  /// `الجنس`
  String get gender {
    return Intl.message(
      'الجنس',
      name: 'gender',
      desc: '',
      args: [],
    );
  }

  /// `رقم الإقامة`
  String get iqamahNumber {
    return Intl.message(
      'رقم الإقامة',
      name: 'iqamahNumber',
      desc: '',
      args: [],
    );
  }

  /// `رقم الهوية`
  String get idNumber {
    return Intl.message(
      'رقم الهوية',
      name: 'idNumber',
      desc: '',
      args: [],
    );
  }

  /// `الجنسية`
  String get nationality {
    return Intl.message(
      'الجنسية',
      name: 'nationality',
      desc: '',
      args: [],
    );
  }

  /// `رقم الجواز`
  String get passportNumber {
    return Intl.message(
      'رقم الجواز',
      name: 'passportNumber',
      desc: '',
      args: [],
    );
  }

  /// `المسمى الوظيفي`
  String get jobTitle {
    return Intl.message(
      'المسمى الوظيفي',
      name: 'jobTitle',
      desc: '',
      args: [],
    );
  }

  /// `السكن`
  String get housing {
    return Intl.message(
      'السكن',
      name: 'housing',
      desc: '',
      args: [],
    );
  }

  /// `اسم المشروع`
  String get projectName {
    return Intl.message(
      'اسم المشروع',
      name: 'projectName',
      desc: '',
      args: [],
    );
  }

  /// `الهاتف`
  String get phone {
    return Intl.message(
      'الهاتف',
      name: 'phone',
      desc: '',
      args: [],
    );
  }

  /// `ملاحظات`
  String get notes {
    return Intl.message(
      'ملاحظات',
      name: 'notes',
      desc: '',
      args: [],
    );
  }

  /// `تاريخ الانضمام`
  String get joiningDate {
    return Intl.message(
      'تاريخ الانضمام',
      name: 'joiningDate',
      desc: '',
      args: [],
    );
  }

  /// `تاريخ المغادرة`
  String get leavingDate {
    return Intl.message(
      'تاريخ المغادرة',
      name: 'leavingDate',
      desc: '',
      args: [],
    );
  }

  /// `الرقم التسلسلي`
  String get serialNumber {
    return Intl.message(
      'الرقم التسلسلي',
      name: 'serialNumber',
      desc: '',
      args: [],
    );
  }

  /// `الحالات / المشاكل`
  String get casesIssues {
    return Intl.message(
      'الحالات / المشاكل',
      name: 'casesIssues',
      desc: '',
      args: [],
    );
  }

  /// `خطأ في الطباعة: {error}`
  String error_print(Object error) {
    return Intl.message(
      'خطأ في الطباعة: $error',
      name: 'error_print',
      desc: '',
      args: [error],
    );
  }

  /// `خطأ: {error}`
  String error_generic(Object error) {
    return Intl.message(
      'خطأ: $error',
      name: 'error_generic',
      desc: '',
      args: [error],
    );
  }

  /// `تم الحفظ بنجاح`
  String get snack_save_success {
    return Intl.message(
      'تم الحفظ بنجاح',
      name: 'snack_save_success',
      desc: '',
      args: [],
    );
  }

  /// `فشل في الحفظ`
  String get snack_save_failed {
    return Intl.message(
      'فشل في الحفظ',
      name: 'snack_save_failed',
      desc: '',
      args: [],
    );
  }

  /// `فلترة الموظفين`
  String get filterEmployeesTitle {
    return Intl.message(
      'فلترة الموظفين',
      name: 'filterEmployeesTitle',
      desc: '',
      args: [],
    );
  }

  /// `مسح الفلاتر`
  String get clearFilters {
    return Intl.message(
      'مسح الفلاتر',
      name: 'clearFilters',
      desc: '',
      args: [],
    );
  }

  /// `بحث`
  String get search {
    return Intl.message(
      'بحث',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `بحث بالاسم أو الهوية أو الوظيفة...`
  String get searchHint {
    return Intl.message(
      'بحث بالاسم أو الهوية أو الوظيفة...',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `إدارة المستخدمين`
  String get usersManagementTitle {
    return Intl.message(
      'إدارة المستخدمين',
      name: 'usersManagementTitle',
      desc: '',
      args: [],
    );
  }

  /// `العودة للوحة التحكم`
  String get backToDashboard {
    return Intl.message(
      'العودة للوحة التحكم',
      name: 'backToDashboard',
      desc: '',
      args: [],
    );
  }

  /// `إضافة مستخدم`
  String get addUser {
    return Intl.message(
      'إضافة مستخدم',
      name: 'addUser',
      desc: '',
      args: [],
    );
  }

  /// `تحديث القائمة`
  String get refreshList {
    return Intl.message(
      'تحديث القائمة',
      name: 'refreshList',
      desc: '',
      args: [],
    );
  }

  /// `تسجيل الخروج`
  String get logout {
    return Intl.message(
      'تسجيل الخروج',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `لا يوجد مستخدمين بعد`
  String get noUsersYet {
    return Intl.message(
      'لا يوجد مستخدمين بعد',
      name: 'noUsersYet',
      desc: '',
      args: [],
    );
  }

  /// `اضغط على زر (+) لإضافة مستخدم جديد`
  String get pressAddToCreateUser {
    return Intl.message(
      'اضغط على زر (+) لإضافة مستخدم جديد',
      name: 'pressAddToCreateUser',
      desc: '',
      args: [],
    );
  }

  /// `تم إضافة المستخدم بنجاح`
  String get userAddedSuccess {
    return Intl.message(
      'تم إضافة المستخدم بنجاح',
      name: 'userAddedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `تم تحديث المستخدم بنجاح`
  String get userUpdatedSuccess {
    return Intl.message(
      'تم تحديث المستخدم بنجاح',
      name: 'userUpdatedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `حذف المستخدم`
  String get confirmDeleteUserTitle {
    return Intl.message(
      'حذف المستخدم',
      name: 'confirmDeleteUserTitle',
      desc: '',
      args: [],
    );
  }

  /// `هل أنت متأكد من حذف هذا المستخدم؟`
  String get confirmDeleteUserContent {
    return Intl.message(
      'هل أنت متأكد من حذف هذا المستخدم؟',
      name: 'confirmDeleteUserContent',
      desc: '',
      args: [],
    );
  }

  /// `حذف`
  String get delete {
    return Intl.message(
      'حذف',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `تم حذف المستخدم بنجاح`
  String get userDeletedSuccess {
    return Intl.message(
      'تم حذف المستخدم بنجاح',
      name: 'userDeletedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `معرّف`
  String get col_id {
    return Intl.message(
      'معرّف',
      name: 'col_id',
      desc: '',
      args: [],
    );
  }

  /// `الرقم التسلسلي`
  String get col_sn {
    return Intl.message(
      'الرقم التسلسلي',
      name: 'col_sn',
      desc: '',
      args: [],
    );
  }

  /// `الاسم`
  String get col_name {
    return Intl.message(
      'الاسم',
      name: 'col_name',
      desc: '',
      args: [],
    );
  }

  /// `الإقامة`
  String get col_iqamah {
    return Intl.message(
      'الإقامة',
      name: 'col_iqamah',
      desc: '',
      args: [],
    );
  }

  /// `رقم الهوية`
  String get col_id_number {
    return Intl.message(
      'رقم الهوية',
      name: 'col_id_number',
      desc: '',
      args: [],
    );
  }

  /// `الجنسية`
  String get col_nationality {
    return Intl.message(
      'الجنسية',
      name: 'col_nationality',
      desc: '',
      args: [],
    );
  }

  /// `الهاتف`
  String get col_phone {
    return Intl.message(
      'الهاتف',
      name: 'col_phone',
      desc: '',
      args: [],
    );
  }

  /// `الإجراءات`
  String get col_actions {
    return Intl.message(
      'الإجراءات',
      name: 'col_actions',
      desc: '',
      args: [],
    );
  }

  /// `تعديل`
  String get action_edit {
    return Intl.message(
      'تعديل',
      name: 'action_edit',
      desc: '',
      args: [],
    );
  }

  /// `حذف`
  String get action_delete {
    return Intl.message(
      'حذف',
      name: 'action_delete',
      desc: '',
      args: [],
    );
  }

  /// `المرفقات`
  String get action_attachments {
    return Intl.message(
      'المرفقات',
      name: 'action_attachments',
      desc: '',
      args: [],
    );
  }

  /// `عرض التفاصيل`
  String get action_view_details {
    return Intl.message(
      'عرض التفاصيل',
      name: 'action_view_details',
      desc: '',
      args: [],
    );
  }

  /// `لم يتم العثور على موظفين`
  String get noEmployeesFound {
    return Intl.message(
      'لم يتم العثور على موظفين',
      name: 'noEmployeesFound',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
