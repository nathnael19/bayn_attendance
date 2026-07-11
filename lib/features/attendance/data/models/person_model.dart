import 'dart:convert';
import '../../domain/entities/person.dart';

/// Data-layer representation of [Person].
/// Adds SQLite serialization (fromMap / toMap) and
/// JSON serialization (fromJson / toJson) for the backend API.
class PersonModel extends Person {
  const PersonModel({
    super.localId,
    super.serverId,
    required super.name,
    required super.employeeId,
    required super.department,
    required super.faceImagePaths,
    required super.registeredAt,
    super.isSynced,
  });

  // ── SQLite ────────────────────────────────────────────────

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    // faceImagePaths is stored as a JSON string in SQLite
    final raw = map['face_image_paths'] as String? ?? '{}';
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final faceImagePaths = decoded.map(
      (k, v) => MapEntry(k, List<String>.from(v as List)),
    );

    return PersonModel(
      localId: map['id'] as int?,
      serverId: map['server_id'] as String?,
      name: map['name'] as String,
      employeeId: map['employee_id'] as String,
      department: map['department'] as String,
      faceImagePaths: faceImagePaths,
      registeredAt: DateTime.parse(map['registered_at'] as String),
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
      'face_image_paths': jsonEncode(faceImagePaths),
      'registered_at': registeredAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // ── REST API JSON ─────────────────────────────────────────

  /// Build the JSON body sent to the backend on registration.
  /// Image bytes / multipart is handled separately in the datasource.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employee_id': employeeId,
      'department': department,
      'registered_at': registeredAt.toIso8601String(),
    };
  }

  /// Parse the backend response after a successful registration.
  factory PersonModel.fromJson(Map<String, dynamic> json, Person local) {
    return PersonModel(
      localId: local.localId,
      serverId: json['id']?.toString(),   // adjust key to match your API
      name: local.name,
      employeeId: local.employeeId,
      department: local.department,
      faceImagePaths: local.faceImagePaths,
      registeredAt: local.registeredAt,
      isSynced: true,
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  factory PersonModel.fromEntity(Person p) {
    return PersonModel(
      localId: p.localId,
      serverId: p.serverId,
      name: p.name,
      employeeId: p.employeeId,
      department: p.department,
      faceImagePaths: p.faceImagePaths,
      registeredAt: p.registeredAt,
      isSynced: p.isSynced,
    );
  }
}
