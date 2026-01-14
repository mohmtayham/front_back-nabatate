import 'package:flutter/foundation.dart';
import 'package:nabtatcompany/services/meter_service.dart';
import 'package:nabtatcompany/models/meter.dart';

class MeterProvider with ChangeNotifier {
  List<Meter> _meters = [];
  bool _isLoading = false;
  String? _error;

  List<Meter> get meters => _meters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final MeterService _meterService = MeterService();

  // جلب جميع العدادات
  Future<void> fetchMeters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meters = await _meterService.getMeters();
    } catch (e) {
      _error = e.toString();
      print('Error in fetchMeters: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب عداد معين
  Future<Meter> getMeter(int id) async {
    try {
      return await _meterService.getMeter(id);
    } catch (e) {
      print('Error in getMeter: $e');
      rethrow;
    }
  }

  // إضافة عداد جديد
  Future<Meter> addMeter(Meter meter) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newMeter = await _meterService.createMeter(meter);
      _meters.add(newMeter);
      _error = null;
      notifyListeners();
      return newMeter;
    } catch (e) {
      _error = e.toString();
      print('Error in addMeter: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // تحديث عداد
  Future<Meter> updateMeter(int id, Meter meter) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedMeter = await _meterService.updateMeter(id, meter);
      final index = _meters.indexWhere((m) => m.id == id);
      if (index != -1) {
        _meters[index] = updatedMeter;
      }
      _error = null;
      notifyListeners();
      return updatedMeter;
    } catch (e) {
      _error = e.toString();
      print('Error in updateMeter: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // حذف عداد
  Future<void> deleteMeter(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _meterService.deleteMeter(id);
      if (success) {
        _meters.removeWhere((meter) => meter.id == id);
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error in deleteMeter: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // البحث في العدادات
  List<Meter> searchMeters(String query) {
    if (query.isEmpty) return _meters;
    
    return _meters.where((meter) {
      return meter.name.toLowerCase().contains(query.toLowerCase()) ||
             meter.serialNumber.toLowerCase().contains(query.toLowerCase()) ||
             (meter.billNumber?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  // مسح الأخطاء
  void clearError() {
    _error = null;
    notifyListeners();
  }
}