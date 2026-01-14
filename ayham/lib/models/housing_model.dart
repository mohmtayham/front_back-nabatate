// lib/models/housing_model.dart
class Housing {
  int id;
  String name;
  String housingType;
  String? housingNumber;
  String? address;
  int? buildingsCount;
  int? roomsCount;
  String? housingLicense;
  String? housingLicenseUrl;
  double? housingValue;
  bool rentDue;
  String? rentDueDate;
  bool rentPaid;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  Housing({
    required this.id,
    required this.name,
    required this.housingType,
    this.housingNumber,
    this.address,
    this.buildingsCount,
    this.roomsCount,
    this.housingLicense,
    this.housingLicenseUrl,
    this.housingValue,
    this.rentDue = false,
    this.rentDueDate,
    this.rentPaid = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Housing.fromJson(Map<String, dynamic> json) {
    return Housing(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      housingType: json['housing_type'] ?? 'ملك',
      housingNumber: json['housing_number'],
      address: json['address'],
      buildingsCount: json['buildings_count'] != null
          ? int.tryParse(json['buildings_count'].toString())
          : null,
      roomsCount: json['rooms_count'] != null
          ? int.tryParse(json['rooms_count'].toString())
          : null,
      housingLicense: json['housing_license'],
      housingLicenseUrl: json['housing_license_url'],
      housingValue: json['housing_value'] != null
          ? double.tryParse(json['housing_value'].toString())
          : null,
      rentDue: json['rent_due'] ?? false,
      rentDueDate: json['rent_due_date'],
      rentPaid: json['rent_paid'] ?? false,
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
      'housing_type': housingType,
      'housing_number': housingNumber,
      'address': address,
      'buildings_count': buildingsCount,
      'rooms_count': roomsCount,
      'housing_license': housingLicense,
      'housing_value': housingValue,
      'rent_due': rentDue,
      'rent_due_date': rentDueDate,
      'rent_paid': rentPaid,
      'notes': notes,
    };
  }

  bool get hasLicense => housingLicense != null && housingLicense!.isNotEmpty;

  Housing copyWith({
    int? id,
    String? name,
    String? housingType,
    String? housingNumber,
    String? address,
    int? buildingsCount,
    int? roomsCount,
    String? housingLicense,
    double? housingValue,
    bool? rentDue,
    String? rentDueDate,
    bool? rentPaid,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Housing(
      id: id ?? this.id,
      name: name ?? this.name,
      housingType: housingType ?? this.housingType,
      housingNumber: housingNumber ?? this.housingNumber,
      address: address ?? this.address,
      buildingsCount: buildingsCount ?? this.buildingsCount,
      roomsCount: roomsCount ?? this.roomsCount,
      housingLicense: housingLicense ?? this.housingLicense,
      housingLicenseUrl: housingLicense != null ? null : this.housingLicenseUrl,
      housingValue: housingValue ?? this.housingValue,
      rentDue: rentDue ?? this.rentDue,
      rentDueDate: rentDueDate ?? this.rentDueDate,
      rentPaid: rentPaid ?? this.rentPaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}