import 'package:flutter/material.dart';

class Project {
  int id;
  String name;
  String code;
  String? location;
  String? managerName;
  String status;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.code,
    this.location,
    this.managerName,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      location: json['location'],
      managerName: json['manager_name'],
      status: json['status'] ?? 'قائم',
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'manager_name': managerName,
      'status': status,
      'notes': notes,
    };
  }

  Color get statusColor {
    switch (status) {
      case 'منتهي':
        return Colors.green;
      case 'قائم':
        return Colors.blue;
      case 'سلم':
        return Colors.orange;
      case 'يتمدد':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'منتهي':
        return Icons.check_circle;
      case 'قائم':
        return Icons.play_circle_filled;
      case 'سلم':
        return Icons.assignment_turned_in;
      case 'يتمدد':
        return Icons.expand;
      default:
        return Icons.help;
    }
  }

  Project copyWith({
    int? id,
    String? name,
    String? code,
    String? location,
    String? managerName,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      managerName: managerName ?? this.managerName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}