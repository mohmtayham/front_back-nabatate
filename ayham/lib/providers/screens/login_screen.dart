import 'package:flutter/material.dart';
import 'package:nabtatcompany/services/api_service.dart';
import 'package:nabtatcompany/services/auth_service.dart'; // Ensure this is imported
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabtatcompany/main.dart';

import 'admin_dashboard.dart';
import 'package:nabtatcompany/providers/auth_provider.dart';
import 'package:nabtatcompany/providers/screens/user_dashboard.dart';
import 'package:nabtatcompany/dialogs/change_password_dialog.dart';
import 'package:nabtatcompany/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showNormalLogin = false;
  bool _isLoading = false;
  bool _isQuickLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _hasSavedAccount = false;
  String _errorMessage = '';
  String _selectedLanguage = 'en';
  String? _savedEmail;
  List<Map<String, dynamic>> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _checkSavedAccount();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loc = prefs.getString('locale');
      if (loc != null && loc.isNotEmpty) {
        setState(() => _selectedLanguage = loc);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MyApp.setLocale(context, Locale(loc));
        });
      }
    } catch (e) {
      // ignore
    }
  }

 Future<void> _checkSavedAccount() async {
    final loggedIn = await ApiService().isLoggedIn();
    final email = await ApiService().getSavedEmail();
    final accounts = await ApiService().getSavedAccounts();

    if (accounts.isNotEmpty) {
      setState(() {
        _savedAccounts = accounts;
        _hasSavedAccount = true;
      });
    }

    if (loggedIn && email != null && email.isNotEmpty) {
      setState(() {
        _savedEmail = email;
        _emailController.text = email;
      });

      // Try silent auth with current token
      _quickLogin();
    }
}

  // ✅ FIXED QUICK LOGIN
// ✅ FIXED QUICK LOGIN
// ✅ الحل النهائي للدخول السريع في LoginScreen
// داخل ملف login_screen.dart
Future<void> _quickLogin() async {
  setState(() => _isQuickLoading = true);
  try {
    final result = await ApiService().checkAuth();

    if (result['authenticated'] == true && result['user'] != null) {
      final user = User.fromJson(result['user']);
      
      if (!mounted) return;

      // 1. تحديث الـ Provider فوراً (سيقوم بحفظ البيانات في SharedPreferences أيضاً)
      Provider.of<AuthProvider>(context, listen: false).setUser(user);

     //  2. التحقق من النوع والتوجه الصارم
       if (user.type == 'admin') {
         print("Quick Login SUCCESS: Admin detected");
         Navigator.pushAndRemoveUntil(
           context,
           MaterialPageRoute(builder: (_) => const AdminDashboard()),
           (route) => false,
         );
       } else {
        print("Quick Login SUCCESS: User detected");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboard()),
          (route) => false,
        );
       }
    } 
    else {
      // إذا كان التوكن تالفاً أو البيانات ناقصة
      setState(() {
        _hasSavedAccount = false;
        _showNormalLogin = true;
      });
    }
  } catch (e) {
    print("Quick Login Failed: $e");
    setState(() => _showNormalLogin = true);
  } finally {
    if (mounted) setState(() => _isQuickLoading = false);
  }
}
 // ✅ FIXED LOGIN inside LoginScreen
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final result = await ApiService().login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (result['success'] == true && result['user'] != null) {
      final user = User.fromJson(result['user']);
      
      if (!mounted) return;

      Provider.of<AuthProvider>(context, listen: false).setUser(user);

      // ✅ FIX: Redirect based on user type
      if (user.type == 'admin') {
        print("Login SUCCESS: Admin detected");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
          (route) => false,
        );
      } else {
        print("Login SUCCESS: User detected");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboard()),
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = result['message']?.toString() ?? 'بيانات الدخول غير صحيحة';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'حدث خطأ في الاتصال: $e';
    });
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  void _switchLanguage() {
    setState(() {
      _selectedLanguage = _selectedLanguage == 'en' ? 'ar' : 'en';
    });

    // Apply immediately and persist
    final newLocale = Locale(_selectedLanguage);
    MyApp.setLocale(context, newLocale);
    SharedPreferences.getInstance().then((prefs) => prefs.setString('locale', _selectedLanguage));
  }

  String tr(String en, String ar) {
    return _selectedLanguage == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2D5A27);
    const accentGreen = Color(0xFF70AD47);

    return Scaffold(
      body: Row(
        children: [
          // Left Side (Image)
          Expanded(
            flex: 11,
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(color: primaryGreen),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/photo_2025-12-18_20-11-57.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: primaryGreen),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildLanguageSelector(),
                  ),
                ],
              ),
            ),
          ),

          // Right Side (Form)
          Expanded(
            flex: 9,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.eco_rounded, color: accentGreen, size: 48),
                          const SizedBox(height: 20),
                          Text(
                            tr("Welcome Back", "مرحباً بعودتك"),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 48),

                         // داخل Column في قسم الـ Form (الجهة اليمنى)
if (_hasSavedAccount && !_showNormalLogin)
  Column(
    children: [
      const CircleAvatar(
        radius: 40,
        backgroundColor: Color(0xFF70AD47),
        child: Icon(Icons.person, size: 50, color: Colors.white),
      ),
      const SizedBox(height: 10),
      // List saved accounts
      for (var acc in _savedAccounts)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isQuickLoading ? null : () => _quickLoginAs(acc['email'] ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A27),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isQuickLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('${acc['name'] ?? ''} (${acc['email'] ?? ''})'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () async {
                  await ApiService().removeSavedAccount(acc['email'] ?? '');
                  final refreshed = await ApiService().getSavedAccounts();
                  setState(() {
                    _savedAccounts = refreshed;
                    _hasSavedAccount = refreshed.isNotEmpty;
                  });
                },
              ),
            ],
          ),
        ),

      const SizedBox(height: 14),
      TextButton(
        onPressed: () {
          setState(() {
            _showNormalLogin = true;
          });
        },
        child: Text(tr("Login with another account", "الدخول بحساب آخر")),
      ),
    ],
  ),

                          if (!_hasSavedAccount || _showNormalLogin) ...[
                            _buildInputLabel(tr("Email", "البريد الإلكتروني")),
                            _buildTextField(
                              controller: _emailController,
                              hint: "email@example.com",
                              icon: Icons.email_outlined,
                              validator: (v) => v!.isEmpty ? tr("Required", "مطلوب") : null,
                            ),
                            const SizedBox(height: 20),
                            _buildInputLabel(tr("Password", "كلمة المرور")),
                            _buildTextField(
                              controller: _passwordController,
                              hint: "••••••••",
                              isPassword: true,
                              icon: Icons.lock_outline,
                              validator: (v) => v!.isEmpty ? tr("Required", "مطلوب") : null,
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
                                child: _isLoading 
                                    ? const CircularProgressIndicator(color: Colors.white) 
                                    : Text(tr("SIGN IN", "تسجيل الدخول")),
                              ),
                            ),
                          ],

                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Helpers (Labels, Language Selector, etc) - Keep your existing versions of these
  Widget _buildLanguageSelector() {
    return InkWell(
      onTap: _switchLanguage,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: Text(_selectedLanguage.toUpperCase(), style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Text(label, style: const TextStyle(fontWeight: FontWeight.bold));

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
      ),
    );
  }
  
  Future<void> _quickLoginAs(String email) async {
    setState(() => _isQuickLoading = true);
    try {
      final result = await ApiService().quickLogin(email);

      if (result['success'] == true && result['user'] != null) {
        final user = User.fromJson(result['user']);
        if (!mounted) return;
        Provider.of<AuthProvider>(context, listen: false).setUser(user);

        if (user.type == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboard()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message']?.toString() ?? 'فشل الدخول السريع';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _isQuickLoading = false);
    }
  }
}