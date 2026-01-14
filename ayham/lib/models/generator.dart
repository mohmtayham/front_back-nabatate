class Generator {
  final int? id;
  final String supplierName;
  final String generatorName;
  final String powerCapacity;
  final double monthlyRent;
  final double? yearlyTotal;
  final String status;
  final int? dieselConsumptionLitersPerHour;
  final double? monthlyDieselCost;
  final int? buildingId;
  final int? housingId;
  final DateTime? installationDate;
  final DateTime? nextMaintenanceDate;
  final int? maintenanceIntervalDays;
  final int operatingHours;
  final List<String>? attachments;
  final List<String>? attachmentUrls;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? building;
  final Map<String, dynamic>? housing;
  final double? totalMonthlyCost;

  Generator({
    this.id,
    required this.supplierName,
    required this.generatorName,
    required this.powerCapacity,
    required this.monthlyRent,
    this.yearlyTotal,
    required this.status,
    this.dieselConsumptionLitersPerHour,
    this.monthlyDieselCost,
    this.buildingId,
    this.housingId,
    this.installationDate,
    this.nextMaintenanceDate,
    this.maintenanceIntervalDays,
    this.operatingHours = 0,
    this.attachments,
    this.attachmentUrls,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.building,
    this.housing,
    this.totalMonthlyCost,
  });

factory Generator.fromJson(Map<String, dynamic> json) {
  return Generator(
    id: json['id'],
    supplierName: json['supplier_name'],
    generatorName: json['generator_name'],
    powerCapacity: json['power_capacity'],
    monthlyRent: json['monthly_rent'] is String 
        ? double.parse(json['monthly_rent'])
        : (json['monthly_rent'] as num).toDouble(),
    yearlyTotal: json['yearly_total'] != null
        ? (json['yearly_total'] is String 
            ? double.parse(json['yearly_total'])
            : (json['yearly_total'] as num).toDouble())
        : null,
    status: json['status'],
    
    // ⭐⭐⭐ الحل: تحويل String إلى int عند الضرورة ⭐⭐⭐
    dieselConsumptionLitersPerHour: json['diesel_consumption_liters_per_hour'] != null
        ? (json['diesel_consumption_liters_per_hour'] is String
            ? int.tryParse(json['diesel_consumption_liters_per_hour'])
            : (json['diesel_consumption_liters_per_hour'] as int?))
        : null,
    
    monthlyDieselCost: json['monthly_diesel_cost'] != null
        ? (json['monthly_diesel_cost'] is String 
            ? double.parse(json['monthly_diesel_cost'])
            : (json['monthly_diesel_cost'] as num).toDouble())
        : null,
    
    // ⭐⭐⭐ الحل: معالجة building_id سواء كان String أو int ⭐⭐⭐
    buildingId: json['building_id'] != null
        ? (json['building_id'] is String
            ? (json['building_id']!.isNotEmpty 
                ? int.tryParse(json['building_id']!)
                : null)
            : (json['building_id'] as int?))
        : null,
    
    // ⭐⭐⭐ الحل: معالجة housing_id سواء كان String أو int ⭐⭐⭐
    housingId: json['housing_id'] != null
        ? (json['housing_id'] is String
            ? (json['housing_id']!.isNotEmpty 
                ? int.tryParse(json['housing_id']!)
                : null)
            : (json['housing_id'] as int?))
        : null,
    
    installationDate: json['installation_date'] != null 
        ? DateTime.parse(json['installation_date'])
        : null,
    nextMaintenanceDate: json['next_maintenance_date'] != null 
        ? DateTime.parse(json['next_maintenance_date'])
        : null,
    
    // ⭐⭐⭐ الحل: معالجة maintenance_interval_days ⭐⭐⭐
    maintenanceIntervalDays: json['maintenance_interval_days'] != null
        ? (json['maintenance_interval_days'] is String
            ? int.tryParse(json['maintenance_interval_days'])
            : (json['maintenance_interval_days'] as int?))
        : null,
    
    operatingHours: json['operating_hours'] != null
        ? (json['operating_hours'] is String
            ? int.tryParse(json['operating_hours']) ?? 0
            : (json['operating_hours'] as int?) ?? 0)
        : 0,
    
    attachments: json['attachments'] != null 
        ? List<String>.from(json['attachments'])
        : null,
    attachmentUrls: json['attachment_urls'] != null
        ? List<String>.from(json['attachment_urls'])
        : null,
    notes: json['notes'],
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'])
        : null,
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'])
        : null,
    building: json['building'],
    housing: json['housing'],
    totalMonthlyCost: json['total_monthly_cost'] != null
        ? (json['total_monthly_cost'] is String 
            ? double.parse(json['total_monthly_cost'])
            : (json['total_monthly_cost'] as num).toDouble())
        : null,
  );
}
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'supplier_name': supplierName,
      'generator_name': generatorName,
      'power_capacity': powerCapacity,
      'monthly_rent': monthlyRent,
      if (yearlyTotal != null) 'yearly_total': yearlyTotal,
      'status': status,
      if (dieselConsumptionLitersPerHour != null) 
        'diesel_consumption_liters_per_hour': dieselConsumptionLitersPerHour,
      if (monthlyDieselCost != null) 'monthly_diesel_cost': monthlyDieselCost,
      'building_id': buildingId,
      'housing_id': housingId,
      if (installationDate != null) 
        'installation_date': installationDate!.toIso8601String().split('T')[0],
      if (nextMaintenanceDate != null) 
        'next_maintenance_date': nextMaintenanceDate!.toIso8601String().split('T')[0],
      if (maintenanceIntervalDays != null) 
        'maintenance_interval_days': maintenanceIntervalDays,
      'operating_hours': operatingHours,
      if (attachments != null && attachments!.isNotEmpty) 'attachments': attachments,
      if (notes != null) 'notes': notes,
    };
  }

  Generator copyWith({
    int? id,
    String? supplierName,
    String? generatorName,
    String? powerCapacity,
    double? monthlyRent,
    double? yearlyTotal,
    String? status,
    int? dieselConsumptionLitersPerHour,
    double? monthlyDieselCost,
    int? buildingId,
    int? housingId,
    DateTime? installationDate,
    DateTime? nextMaintenanceDate,
    int? maintenanceIntervalDays,
    int? operatingHours,
    List<String>? attachments,
    List<String>? attachmentUrls,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? building,
    Map<String, dynamic>? housing,
    double? totalMonthlyCost,
  }) {
    return Generator(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      generatorName: generatorName ?? this.generatorName,
      powerCapacity: powerCapacity ?? this.powerCapacity,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      yearlyTotal: yearlyTotal ?? this.yearlyTotal,
      status: status ?? this.status,
      dieselConsumptionLitersPerHour: dieselConsumptionLitersPerHour ?? this.dieselConsumptionLitersPerHour,
      monthlyDieselCost: monthlyDieselCost ?? this.monthlyDieselCost,
      buildingId: buildingId ?? this.buildingId,
      housingId: housingId ?? this.housingId,
      installationDate: installationDate ?? this.installationDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      maintenanceIntervalDays: maintenanceIntervalDays ?? this.maintenanceIntervalDays,
      operatingHours: operatingHours ?? this.operatingHours,
      attachments: attachments ?? this.attachments,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      building: building ?? this.building,
      housing: housing ?? this.housing,
      totalMonthlyCost: totalMonthlyCost ?? this.totalMonthlyCost,
    );
  }
}