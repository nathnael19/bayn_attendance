import 'dart:convert';

import '../../domain/entities/person.dart';

class PersonModel extends Person {
  const PersonModel({
    super.localId,
    super.serverId,
    required super.name,
    required super.employeeId,
    required super.department,
    super.phone,
    super.email,
    super.role,
    super.pinCode,
    super.isActive,
    super.shiftId,
    super.faceImagePaths,
    super.embeddings,
    required super.registeredAt,
    super.isSynced,
  });

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    Map<String, List<String>> faceImagePaths = {};
    try {
      final raw = map['face_image_paths'] as String? ?? '{}';
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        faceImagePaths = decoded.map(
          (k, v) => MapEntry(
              k, v is List ? List<String>.from(v.whereType<String>()) : <String>[]),
        );
      }
    } catch (_) {
      faceImagePaths = {};
    }

    return PersonModel(
      localId: map['id'] as int?,
      serverId: map['server_id'] as String?,
      name: (map['name'] as String?) ?? '',
      employeeId: (map['employee_id'] as String?) ?? '',
      department: (map['department'] as String?) ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      role: (map['role'] as String?) ?? 'employee',
      pinCode: map['pin_code'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      shiftId: map['shift_id'] as int?,
      faceImagePaths: faceImagePaths,
      registeredAt:
          DateTime.tryParse(map['registered_at'] as String? ?? '') ?? DateTime.now(),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (localId != null) 'id': localId,
      'server_id': serverId,
      'name': name,
      'employee_id': employeeId,
      'department': department,
      'phone': phone,
      'email': email,
      'role': role,
      'pin_code': pinCode,
      'is_active': isActive ? 1 : 0,
      'shift_id': shiftId,
      'face_image_paths': jsonEncode(faceImagePaths),
      'registered_at': registeredAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employee_id': employeeId,
      'department': department,
      'registered_at': registeredAt.toIso8601String(),
    };
  }

  factory PersonModel.fromJson(Map<String, dynamic> json, Person local) {
    return PersonModel(
      localId: local.localId,
      serverId: json['id']?.toString(),
      name: local.name,
      employeeId: local.employeeId,
      department: local.department,
      phone: local.phone,
      email: local.email,
      role: local.role,
      pinCode: local.pinCode,
      isActive: local.isActive,
      shiftId: local.shiftId,
      faceImagePaths: local.faceImagePaths,
      registeredAt: local.registeredAt,
      isSynced: true,
    );
  }

  factory PersonModel.fromEntity(Person p) {
    return PersonModel(
      localId: p.localId,
      serverId: p.serverId,
      name: p.name,
      employeeId: p.employeeId,
      department: p.department,
      phone: p.phone,
      email: p.email,
      role: p.role,
      pinCode: p.pinCode,
      isActive: p.isActive,
      shiftId: p.shiftId,
      faceImagePaths: p.faceImagePaths,
      embeddings: p.embeddings,
      registeredAt: p.registeredAt,
      isSynced: p.isSynced,
    );
  }
}
