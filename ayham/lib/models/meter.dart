import 'dart:convert';

class Meter {
  int id;
  String name;
  String serialNumber;
  int housingId;
  int? buildingId;
  String? billNumber;
  double? billAmount;
  String paymentStatus;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  Housing? housing;
  Building? building;

  Meter({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.housingId,
    this.buildingId,
    this.billNumber,
    this.billAmount,
    required this.paymentStatus,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.housing,
    this.building,
  });

  factory Meter.fromJson(Map<String, dynamic> json) {
    return Meter(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      housingId: json['housing_id'] ?? 0,
      buildingId: json['building_id'],
      billNumber: json['bill_number'],
      billAmount: json['bill_amount'] != null
          ? double.tryParse(json['bill_amount'].toString()) ?? 0.0
          : null,
      paymentStatus: json['payment_status'] ?? 'مسدد',
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      housing: json['housing'] != null
          ? Housing.fromJson(json['housing'])
          : null,
      building: json['building'] != null
          ? Building.fromJson(json['building'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'serial_number': serialNumber,
      'housing_id': housingId,
      'building_id': buildingId,
      'bill_number': billNumber,
      'bill_amount': billAmount,
      'payment_status': paymentStatus,
      'notes': notes,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'serial_number': serialNumber,
      'housing_id': housingId,
      'building_id': buildingId,
      'bill_number': billNumber,
      'bill_amount': billAmount,
      'payment_status': paymentStatus,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'serial_number': serialNumber,
      'housing_id': housingId,
      'building_id': buildingId,
      'bill_number': billNumber,
      'bill_amount': billAmount,
      'payment_status': paymentStatus,
      'notes': notes,
    };
  }
}

class Housing {
  int id;
  String name;

  Housing({
    required this.id,
    required this.name,
  });

  factory Housing.fromJson(Map<String, dynamic> json) {
    return Housing(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Building {
  int id;
  String name;

  Building({
    required this.id,
    required this.name,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}