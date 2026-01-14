class EmployeeCase {
  final int? id;                 // DB
  final String caseType;         // required
  final String status;           // required
  final String? notes;           // optional
  final DateTime? createdAt;     // DB

  EmployeeCase({
    this.id,
    required this.caseType,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory EmployeeCase.fromJson(Map<String, dynamic> json) {
    return EmployeeCase(
      id: json['id'],
      caseType: json['case_type'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'case_type': caseType,
      'status': status,
      'notes': notes,
    };
  }
}
