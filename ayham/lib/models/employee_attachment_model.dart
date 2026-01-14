import 'package:flutter/material.dart';

class EmployeeAttachment {
  int id;
  int employeeId;
  String filePath;
  String fileName;
  DateTime? createdAt;
  DateTime? updatedAt;

  EmployeeAttachment({
    required this.id,
    required this.employeeId,
    required this.filePath,
    required this.fileName,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeAttachment.fromJson(Map<String, dynamic> json) {
    return EmployeeAttachment(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? '',
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
      'employee_id': employeeId,
      'file_path': filePath,
      'file_name': fileName,
    };
  }

  String get fullUrl {
    const baseUrl = 'http://localhost:8000/storage/';
    return baseUrl + filePath;
  }

  String get fileType {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) return 'صورة';
    if (['pdf'].contains(extension)) return 'PDF';
    if (['doc', 'docx'].contains(extension)) return 'Word';
    if (['xls', 'xlsx'].contains(extension)) return 'Excel';
    return 'ملف';
  }

  IconData get fileIcon {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) return Icons.image;
    if (['pdf'].contains(extension)) return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(extension)) return Icons.description;
    if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  EmployeeAttachment copyWith({
    int? id,
    int? employeeId,
    String? filePath,
    String? fileName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeAttachment(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}