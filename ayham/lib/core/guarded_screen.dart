import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../providers/auth_provider.dart';
import 'access_denied_screen.dart';

class GuardedScreen extends StatelessWidget {
  final String module; 
  final String action; 
  final Widget child;

  const GuardedScreen({
    super.key,
    required this.child,
    required this.module,
    this.action = 'view', 
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    debugPrint('GuardedScreen: entering for module="$module", action="$action"');

    if (user == null) {
      debugPrint('GuardedScreen: no user in authProvider');
      return const AccessDeniedScreen();
    }

    debugPrint('GuardedScreen: user type=${user.type}; permissions=${user.permissions}');

    // ✅ Admins always have access
    if (user.type == 'admin') {
      debugPrint('GuardedScreen: user is admin — allowing access');
      return child;
    }

    // ✅ Check permission in format: 'view_employees', 'add_employees', etc.
    final String permissionKey = '${action}_${module}'; // e.g., 'view_employees'

    try {
      debugPrint('GuardedScreen: checking permissionKey="$permissionKey"');
      final bool allowed = user.can(permissionKey);
      debugPrint('GuardedScreen: user.can("$permissionKey") => $allowed');
      if (allowed) {
        return child;
      }
    } catch (e, st) {
      debugPrint('GuardedScreen: permission check threw: $e');
      debugPrint(st.toString());
    }

    debugPrint('GuardedScreen: access denied for permissionKey="$permissionKey"');
    return const AccessDeniedScreen();
  }
}