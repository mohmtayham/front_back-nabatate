import 'package:flutter/material.dart';

class Room {
  int id;
  String name;
  int buildingId;
  Map<String, dynamic>? buildingData;
  int? bedsCount;
  int? residentsCount;
  String status;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  Room({
    required this.id,
    required this.name,
    required this.buildingId,
    this.buildingData,
    this.bedsCount,
    this.residentsCount,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      buildingId: json['building_id'] ?? 0,
      buildingData: json['building'],
      bedsCount: json['beds_count'],
      residentsCount: json['residents_count'],
      status: json['status'] ?? 'فارغة',
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
      'building_id': buildingId,
      'beds_count': bedsCount,
      'residents_count': residentsCount,
      'status': status,
      'notes': notes,
    };
  }

  String get buildingName {
    if (buildingData != null && buildingData is Map<String, dynamic>) {
      return buildingData!['name'] ?? '';
    }
    return '';
  }

  Color get statusColor {
    switch (status) {
      case 'مشغولة':
        return Colors.red;
      case 'فارغة':
        return Colors.green;
      case 'تحت الصيانة':
        return Colors.orange;
      case 'مغلقة':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'مشغولة':
        return Icons.person;
      case 'فارغة':
        return Icons.event_available;
      case 'تحت الصيانة':
        return Icons.build;
      case 'مغلقة':
        return Icons.lock;
      default:
        return Icons.help;
    }
  }

  Room copyWith({
    int? id,
    String? name,
    int? buildingId,
    Map<String, dynamic>? buildingData,
    int? bedsCount,
    int? residentsCount,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      buildingId: buildingId ?? this.buildingId,
      buildingData: buildingData ?? this.buildingData,
      bedsCount: bedsCount ?? this.bedsCount,
      residentsCount: residentsCount ?? this.residentsCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}