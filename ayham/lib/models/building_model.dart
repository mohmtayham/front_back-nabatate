import 'housing_model.dart';

class Building {
  int id;
  String name;
  int housingId;
  Housing? housing;
  int? floorsCount;
  int? roomsCount;
  List<dynamic>? rooms;
  DateTime? createdAt;
  DateTime? updatedAt;

  Building({
    required this.id,
    required this.name,
    required this.housingId,
    this.housing,
    this.floorsCount,
    this.roomsCount,
    this.rooms,
    this.createdAt,
    this.updatedAt,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      housingId: json['housing_id'] ?? 0,
      housing: json['housing'] != null ? Housing.fromJson(json['housing']) : null,
      floorsCount: json['floors_count'],
      roomsCount: json['rooms_count'],
      rooms: json['rooms'],
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
      'housing_id': housingId,
      'floors_count': floorsCount,
      'rooms_count': roomsCount,
    };
  }

  Building copyWith({
    int? id,
    String? name,
    int? housingId,
    Housing? housing,
    int? floorsCount,
    int? roomsCount,
    List<dynamic>? rooms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Building(
      id: id ?? this.id,
      name: name ?? this.name,
      housingId: housingId ?? this.housingId,
      housing: housing ?? this.housing,
      floorsCount: floorsCount ?? this.floorsCount,
      roomsCount: roomsCount ?? this.roomsCount,
      rooms: rooms ?? this.rooms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}