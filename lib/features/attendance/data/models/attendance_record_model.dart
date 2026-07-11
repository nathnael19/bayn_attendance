import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    super.localId,
    super.serverId,
    super.personId,
    required super.personName,
    required super.department,
    required super.confidence,
    required super.checkedInAt,
    super.isSynced,
  });

  // ── SQLite ────────────────────────────────────────────────

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    return AttendanceRecordModel(
      localId: map['id'] as int?,
      serverId: map['server_id'] as String?,
      personId: map['person_id'] as String?,
      personName: map['person_name'] as String,
      department: map['department'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      checkedInAt: DateTime.parse(map['checked_in_at'] as String),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (localId != null) 'id': localId,
      'server_id': serverId,
      'person_id': personId,
      'person_name': personName,
      'department': department,
      'confidence': confidence,
      'checked_in_at': checkedInAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // ── REST API JSON ─────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'person_id': personId,
      'person_name': personName,
      'department': department,
      'confidence': confidence,
      'checked_in_at': checkedInAt.toIso8601String(),
    };
  }

  factory AttendanceRecordModel.fromJson(
      Map<String, dynamic> json, AttendanceRecord local) {
    return AttendanceRecordModel(
      localId: local.localId,
      serverId: json['id']?.toString(), // TODO: match your API key
      personId: local.personId,
      personName: local.personName,
      department: local.department,
      confidence: local.confidence,
      checkedInAt: local.checkedInAt,
      isSynced: true,
    );
  }

  factory AttendanceRecordModel.fromEntity(AttendanceRecord r) {
    return AttendanceRecordModel(
      localId: r.localId,
      serverId: r.serverId,
      personId: r.personId,
      personName: r.personName,
      department: r.department,
      confidence: r.confidence,
      checkedInAt: r.checkedInAt,
      isSynced: r.isSynced,
    );
  }
}
