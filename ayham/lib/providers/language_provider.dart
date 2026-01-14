// providers/language_provider.dart
import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isArabic = true;
  
  bool get isArabic => _isArabic;
  
  void toggleLanguage() {
    _isArabic = !_isArabic;
    notifyListeners();
  }
  
  void setLanguage(bool isArabic) {
    _isArabic = isArabic;
    notifyListeners();
  }
}