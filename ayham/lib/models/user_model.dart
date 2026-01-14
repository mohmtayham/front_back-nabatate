import 'dart:convert';
import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String type;
  final Map<String, bool> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  /// ⭐ Permission checker
  bool can(String permission) {
    try {
      debugPrint('User.can: checking permission="$permission" for user id=$id type=$type');
      debugPrint('User.can: permissions map=$permissions');
      if (type == 'admin') {
        debugPrint('User.can: user is admin -> allowed');
        return true;
      }
      // direct match first
      final val = permissions[permission];
      debugPrint('User.can: permissions["$permission"] => $val');
      if (val == true) return true;

      // If permission is module-specific like 'view_employees', allow it when
      // the user has a generic action permission (e.g., 'view'), or an
      // action-wide permission like 'view_all'. Also accept '<action>_all'.
      final candidates = <String>[permission];
      if (permission.contains('_')) {
        final parts = permission.split('_');
        final action = parts.first;
        final module = parts.sublist(1).join('_');
        candidates.add(action); // e.g. 'view'
        candidates.add('${action}_all'); // e.g. 'view_all'
        candidates.add('${module}_all'); // e.g. 'employees_all' (less common)
      } else {
        // permission is action-only (e.g., 'view' or 'view_all')
        if (permission.endsWith('_all')) {
          final action = permission.split('_').first;
          candidates.add(action);
        }
      }

      for (final c in candidates) {
        final v = permissions[c];
        debugPrint('User.can: candidate "$c" => $v');
        if (v == true) return true;
      }

      return false;
    } catch (e, st) {
      debugPrint('User.can: error while checking permission: $e');
      debugPrint(st.toString());
      return false;
    }
  }

  /// ⭐ Screen access
  bool canAccessEmployees() {
    return can('view_employees');
  }
bool canViewEmployees() => can('view_employees');
bool canAddEmployee() => can('add_employees');
bool canEditEmployee() => can('update_employees');
bool canDeleteEmployee() => can('delete_employees');

  factory User.fromJson(Map<String, dynamic> json) {
  Map<String, bool> parsedPermissions = {};

  final rawPermissions = json['permissions'];

  debugPrint('User.fromJson: rawPermissions => $rawPermissions');

  if (rawPermissions is String) {
    // Case 1: permissions stored as JSON string
    final decoded = jsonDecode(rawPermissions);
    parsedPermissions = Map<String, bool>.from(decoded);
  } 
  else if (rawPermissions is Map) {
    // Case 2: permissions already Map<String, bool>
    parsedPermissions = rawPermissions.map(
      (key, value) => MapEntry(key.toString(), value == true),
    );
  } 
  else if (rawPermissions is List) {
    // Case 3: permissions is list of strings
    for (final p in rawPermissions) {
      parsedPermissions[p.toString()] = true;
    }
  }

  return User(
  id: json['id'] is int ? json['id'] : 0,
  name: json['name']?.toString() ?? '',
  email: json['email']?.toString() ?? '',
  type: json['type']?.toString() ?? 'user',
  permissions: parsedPermissions,
  createdAt: json['created_at'] != null
      ? DateTime.tryParse(json['created_at'].toString())
      : null,
  updatedAt: json['updated_at'] != null
      ? DateTime.tryParse(json['updated_at'].toString())
      : null,
);

}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type,
      'permissions': permissions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
