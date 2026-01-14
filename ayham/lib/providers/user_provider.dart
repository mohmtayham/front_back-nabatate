import 'package:flutter/material.dart';
import '../services/api_service.dart';  // ✅ استيراد ApiService

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();  // ✅ الآن يعرفها
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get userData => _userData;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);
      
      if (result['success'] == true) {
        _userData = result['user'];
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'خطأ في الاتصال بالخادم';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }




}