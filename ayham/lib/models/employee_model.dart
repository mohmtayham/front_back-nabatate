import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'housing_model.dart';
import 'building_model.dart';
import 'room_model.dart';
import 'project_model.dart';
import 'employee_attachment_model.dart';

class Employee {
  int id;
  String name;
  String? iqamaNumber;
  String? employeeNumber;
  String? nationality;
  String? passportNumber;
  String gender;
  String? jobTitle;
  int? housingId;
  Housing? housing;
  int? buildingId;
  Building? building;
  int? roomId;
  Room? room;
  int? projectId;
  Project? project;
  String? projectCode;
  String? contractName;
  String? phone;
  String? email;
  String? joiningDate;
  String? notes;
  List<EmployeeAttachment> attachments;
  DateTime? createdAt;
  DateTime? updatedAt;

  Employee({
    required this.id,
    required this.name,
    this.iqamaNumber,
    this.employeeNumber,
    this.nationality,
    this.passportNumber,
    required this.gender,
    this.jobTitle,
    this.housingId,
    this.housing,
    this.buildingId,
    this.building,
    this.roomId,
    this.room,
    this.projectId,
    this.project,
    this.projectCode,
    this.contractName,
    this.phone,
    this.email,
    this.joiningDate,
    this.notes,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iqamaNumber: json['iqama_number'],
      employeeNumber: json['employee_number'],
      nationality: json['nationality'],
      passportNumber: json['passport_number'],
      gender: json['gender'] ?? 'ذكر',
      jobTitle: json['job_title'],
      housingId: json['housing_id'],
      housing: json['housing'] != null ? Housing.fromJson(json['housing']) : null,
      buildingId: json['building_id'],
      building: json['building'] != null ? Building.fromJson(json['building']) : null,
      roomId: json['room_id'],
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
      projectId: json['project_id'],
      project: json['project'] != null ? Project.fromJson(json['project']) : null,
      projectCode: json['project_code'],
      contractName: json['contract_name'],
      phone: json['phone'],
      email: json['email'],
      joiningDate: json['joining_date'],
      notes: json['notes'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => EmployeeAttachment.fromJson(e))
              .toList()
          : [],
      createdAt: json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.parse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null && json['updated_at'].toString().isNotEmpty
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iqama_number': iqamaNumber,
      'employee_number': employeeNumber,
      'nationality': nationality,
      'passport_number': passportNumber,
      'gender': gender,
      'job_title': jobTitle,
      'housing_id': housingId,
      'building_id': buildingId,
      'room_id': roomId,
      'project_id': projectId,
      'project_code': projectCode,
      'contract_name': contractName,
      'phone': phone,
      'email': email,
      'joining_date': joiningDate,
      'notes': notes,
    };
  }

  // دالة لعرض تاريخ الالتحاق بشكل منسق
  String get formattedJoiningDate {
    if (joiningDate == null || joiningDate!.isEmpty) return 'غير محدد';
    
    try {
      final dateTime = joiningDateAsDateTime;
      if (dateTime != null) {
        return DateFormat('yyyy-MM-dd').format(dateTime);
      }
      return joiningDate!;
    } catch (e) {
      return 'تاريخ غير صالح';
    }
  }

  // دالة للحصول على تاريخ الالتحاق كـ DateTime
  DateTime? get joiningDateAsDateTime {
    if (joiningDate == null || joiningDate!.isEmpty) return null;
    
    try {
      String dateString = joiningDate!;
      
      // إذا كان يحتوي على T (تنسيق ISO)
      if (dateString.contains('T')) {
        return DateTime.parse(dateString);
      }
      
      // إذا كان بدون وقت
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateString)) {
        return DateTime.parse('${dateString}T00:00:00');
      }
      
      // محاولة أخرى
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // دالة لعرض تاريخ الإنشاء بشكل منسق
  String get formattedCreatedAt {
    if (createdAt == null) return 'غير متاح';
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt!);
  }

  // دالة لعرض تاريخ التحديث بشكل منسق
  String get formattedUpdatedAt {
    if (updatedAt == null) return 'غير متاح';
    return DateFormat('yyyy-MM-dd HH:mm').format(updatedAt!);
  }

  String get fullName => name;

  String get genderText => gender;

  Color get genderColor => gender == 'ذكر' ? Colors.blue : Colors.pink;

  String get accommodationInfo {
    List<String> info = [];
    if (housing != null) info.add(housing!.name);
    if (building != null) info.add(building!.name);
    if (room != null) info.add(room!.name);
    return info.isNotEmpty ? info.join(' - ') : 'غير محدد';
  }

  Employee copyWith({
    int? id,
    String? name,
    String? iqamaNumber,
    String? employeeNumber,
    String? nationality,
    String? passportNumber,
    String? gender,
    String? jobTitle,
    int? housingId,
    Housing? housing,
    int? buildingId,
    Building? building,
    int? roomId,
    Room? room,
    int? projectId,
    Project? project,
    String? projectCode,
    String? contractName,
    String? phone,
    String? email,
    String? joiningDate,
    String? notes,
    List<EmployeeAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      iqamaNumber: iqamaNumber ?? this.iqamaNumber,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      nationality: nationality ?? this.nationality,
      passportNumber: passportNumber ?? this.passportNumber,
      gender: gender ?? this.gender,
      jobTitle: jobTitle ?? this.jobTitle,
      housingId: housingId ?? this.housingId,
      housing: housing ?? this.housing,
      buildingId: buildingId ?? this.buildingId,
      building: building ?? this.building,
      roomId: roomId ?? this.roomId,
      room: room ?? this.room,
      projectId: projectId ?? this.projectId,
      project: project ?? this.project,
      projectCode: projectCode ?? this.projectCode,
      contractName: contractName ?? this.contractName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      joiningDate: joiningDate ?? this.joiningDate,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}