import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nabtatcompany/models/user_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabtatcompany/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  bool get isAdmin => _user?.type == 'admin';

 void setUser(User user) async {
  _user = user;

  // حفظ البيانات محلياً فوراً لضمان تزامن AuthService
  final prefs = await SharedPreferences.getInstance();
  final json = jsonEncode(user.toJson());
  if (kDebugMode) debugPrint('AuthProvider.setUser: saving user json => $json');
  await prefs.setString('user', json);
  await prefs.setBool('is_logged_in', true);

  notifyListeners();
}


  void logout() {
    _user = null;
    notifyListeners();
  }
  
 static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString == null) return null;
    return jsonDecode(userString);
  }
  /// 🔥 Permission check
  bool can(String permission) {
    if (isAdmin) return true;
    // If we have a populated User in memory, use its logic
    if (_user != null && _user!.permissions.isNotEmpty) {
      return _user!.can(permission);
    }

    // Otherwise, try to read the saved raw user from SharedPreferences
    // to handle cases where quick-login or checkAuth saved a different shape.
    try {
      final raw = ApiService.getUser();
      // ApiService.getUser returns Future<Map<String,dynamic>?>, but we
      // can't await here in a sync method. Use stored prefs synchronously
    } catch (_) {}

    // As a synchronous fallback, read directly from SharedPreferences
    // via the static AuthService.getUser (which is async) — to keep this
    // method sync we will attempt a quick synchronous check using stored
    // _user (already handled) and otherwise conservatively return false.
    // NOTE: For full accuracy, call AuthService.getUser() earlier during
    // app init so AuthProvider._user is always populated.
    return false;
  }
}
