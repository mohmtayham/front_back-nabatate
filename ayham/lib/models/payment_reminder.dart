class PaymentReminder {
  final int? id;
  final int housingId;
  final int? buildingId;
  final String paymentType;
  final DateTime dueDate;
  final double amount;
  final bool paymentStatus;
  final DateTime? paidAt; // ✅ أضف هذه الخاصية
  final List<String>? attachments;
  final List<String>? attachmentUrls;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? housing;
  final Map<String, dynamic>? building;

  PaymentReminder({
    this.id,
    required this.housingId,
    this.buildingId,
    required this.paymentType,
    required this.dueDate,
    required this.amount,
    this.paymentStatus = false,
    this.paidAt, // ✅ أضفها هنا
    this.attachments,
    this.attachmentUrls,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.housing,
    this.building,
  });
  PaymentReminder copyWith({
    int? id,
    int? housingId,
    int? buildingId,
    String? paymentType,
    DateTime? dueDate,
    double? amount,
    bool? paymentStatus,
    DateTime? paidAt,
    List<String>? attachments,
    List<String>? attachmentUrls,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? housing,
    Map<String, dynamic>? building,
  }) {
    return PaymentReminder(
      id: id ?? this.id,
      housingId: housingId ?? this.housingId,
      buildingId: buildingId ?? this.buildingId,
      paymentType: paymentType ?? this.paymentType,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      attachments: attachments ?? this.attachments,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      housing: housing ?? this.housing,
      building: building ?? this.building,
    );
  }

  factory PaymentReminder.fromJson(Map<String, dynamic> json) {
    return PaymentReminder(
      id: json['id'],
      housingId: json['housing_id'],
      buildingId: json['building_id'],
      paymentType: json['payment_type'],
      dueDate: DateTime.parse(json['due_date']),
      amount: json['amount'] is String 
          ? double.parse(json['amount'])
          : (json['amount'] as num).toDouble(),
      paymentStatus: json['payment_status'] ?? false,
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at']) // ✅ معالجة paid_at
          : null,
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
      housing: json['housing'],
      building: json['building'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'housing_id': housingId,
      if (buildingId != null) 'building_id': buildingId,
      'payment_type': paymentType,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'amount': amount,
      'payment_status': paymentStatus,
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(), // ✅ أضفها هنا
      if (attachments != null && attachments!.isNotEmpty) 'attachments': attachments,
      if (notes != null) 'notes': notes,
    };
 
  }
}