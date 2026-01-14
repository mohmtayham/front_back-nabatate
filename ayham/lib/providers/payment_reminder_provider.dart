import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/payment_reminder.dart';

import 'package:nabtatcompany/services/payment_reminder_service.dart';
import 'package:nabtatcompany/services/notification_service.dart';


class PaymentReminderProvider extends ChangeNotifier {
  // البيانات
  List<PaymentReminder> _reminders = [];
  PaymentReminderService? _service;
  bool _isLoading = false;
  String? _error;
  final NotificationService _notificationService = NotificationService();

  // الفلاتر
  bool _showCompleted = false;
  String _filterType = 'الكل';
  String _searchQuery = '';

  // Getter للبيانات
  List<PaymentReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showCompleted => _showCompleted;
  String get filterType => _filterType;
  String get searchQuery => _searchQuery;

  // التهيئة
  void initService() {
    if (_service == null) {
      _service = PaymentReminderService(); // بدون توكن
    }
  }

  // جلب جميع التذكيرات
  Future<void> fetchReminders() async {
    initService();
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
     _reminders = await _service!.getReminders();

// 🔔 جدولة الإشعارات
for (final reminder in _reminders) {
  // لو مدفوع → لا إشعار
  if (reminder.paymentStatus == true) continue;

  // لو بدون تاريخ استحقاق
  if (reminder.dueDate == null) continue;

  await _notificationService.scheduleReminderNotification(
    id: reminder.id!,
    title: 'فاتورة مستحقة',
    body:
        'فاتورة ${reminder.paymentType ?? ''} بقيمة ${reminder.amount ?? 0} '
        'تستحق بتاريخ ${reminder.dueDate!.toLocal().toString().split(' ')[0]}',
    dueDate: reminder.dueDate!,
  );
}

    } catch (e) {
      _error = 'خطأ في جلب التذكيرات: $e';
      _reminders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // التذكيرات بعد الفلترة
  List<PaymentReminder> get filteredReminders {
    var filtered = _reminders;

    // فلترة حسب حالة الدفع
    if (!_showCompleted) {
      filtered = filtered.where((r) => !(r.paymentStatus ?? false)).toList();
    }

    // فلترة حسب النوع
    if (_filterType != 'الكل') {
      filtered = filtered.where((r) => r.paymentType == _filterType).toList();
    }

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((reminder) {
        return (reminder.paymentType ?? '').contains(_searchQuery) ||
            (reminder.notes ?? '').contains(_searchQuery) ||
            (reminder.housingId?.toString() ?? '').contains(_searchQuery) ||
            (reminder.amount?.toString() ?? '').contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  // الإحصائيات
  Map<String, dynamic> getStatistics() {
    final total = _reminders.length;
    final paid = _reminders.where((r) => r.paymentStatus ?? false).length;
    final pending = total - paid;
    
    final totalAmount = _reminders.fold(0.0, (sum, r) => sum + (r.amount ?? 0));
    final paidAmount = _reminders
        .where((r) => r.paymentStatus ?? false)
        .fold(0.0, (sum, r) => sum + (r.amount ?? 0));
    final pendingAmount = totalAmount - paidAmount;

    return {
      'total': total,
      'paid': paid,
      'pending': pending,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'pending_amount': pendingAmount,
      'types': {
        'كهرباء': _reminders.where((r) => r.paymentType == 'كهرباء').length,
        'ماء': _reminders.where((r) => r.paymentType == 'ماء').length,
        'غيره': _reminders.where((r) => r.paymentType == 'غيره').length,
      },
    };
  }

  // إضافة تذكير جديد
  Future<void> addReminder(PaymentReminder reminder) async {
    initService();
    
    _isLoading = true;
    notifyListeners();

    try {
      final newReminder = await _service!.createReminder(reminder);
      _reminders.insert(0, newReminder);
      _error = null;
    } catch (e) {
      _error = 'خطأ في إضافة التذكير: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث تذكير
  Future<void> updateReminder(PaymentReminder reminder) async {
    initService();
    
    if (reminder.id == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final updatedReminder = await _service!.updateReminder(reminder.id!, reminder);
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = updatedReminder;
      }
      _error = null;
    } catch (e) {
      _error = 'خطأ في تحديث التذكير: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف تذكير
  Future<void> deleteReminder(int id) async {
    initService();
    
    _isLoading = true;
    notifyListeners();

    try {
      await _service!.deleteReminder(id);
      _reminders.removeWhere((r) => r.id == id);
      _error = null;
    } catch (e) {
      _error = 'خطأ في حذف التذكير: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث حالة الدفع
  Future<void> togglePaymentStatus(int id) async {
    initService();
    
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final oldReminder = _reminders[index];
    final newReminder = PaymentReminder(
      id: oldReminder.id,
      housingId: oldReminder.housingId,
      buildingId: oldReminder.buildingId,
      paymentType: oldReminder.paymentType,
      dueDate: oldReminder.dueDate,
      amount: oldReminder.amount,
      paymentStatus: !(oldReminder.paymentStatus ?? false),
      notes: oldReminder.notes,
    );

    await updateReminder(newReminder);
  }

  // تحديث الفلاتر
  void updateFilters({
    bool? showCompleted,
    String? filterType,
    String? searchQuery,
  }) {
    if (showCompleted != null) {
      _showCompleted = showCompleted;
    }
    if (filterType != null) {
      _filterType = filterType;
    }
    if (searchQuery != null) {
      _searchQuery = searchQuery;
    }
    notifyListeners();
  }

  // مسح الفلاتر
  void clearFilters() {
    _showCompleted = false;
    _filterType = 'الكل';
    _searchQuery = '';
    notifyListeners();
  }

  // مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }



  // إعادة تعيين
  void reset() {
    _reminders = [];
    _isLoading = false;
    _error = null;
    _showCompleted = false;
    _filterType = 'الكل';
    _searchQuery = '';
    notifyListeners();
  }
}