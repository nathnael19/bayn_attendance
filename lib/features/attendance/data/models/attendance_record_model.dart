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
    super.checkedOutAt,
    super.status,
    super.shiftId,
    super.location,
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
      checkedOutAt: map['checked_out_at'] != null
          ? DateTime.tryParse(map['checked_out_at'] as String)
          : null,
      status: (map['status'] as String?) ?? 'present',
      shiftId: map['shift_id'] as int?,
      location: map['location'] as String?,
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
      'checked_out_at': checkedOutAt?.toIso8601String(),
      'status': status,
      'shift_id': shiftId,
      'location': location,
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
      'checked_out_at': checkedOutAt?.toIso8601String(),
      'status': status,
      'shift_id': shiftId,
      'location': location,
    };
  }

  factory AttendanceRecordModel.fromJson(
      Map<String, dynamic> json, AttendanceRecord local) {
    return AttendanceRecordModel(
      localId: local.localId,
      serverId: json['id']?.toString(),
      personId: local.personId,
      personName: local.personName,
      department: local.department,
      confidence: local.confidence,
      checkedInAt: local.checkedInAt,
      checkedOutAt: local.checkedOutAt,
      status: local.status,
      shiftId: local.shiftId,
      location: local.location,
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
      checkedOutAt: r.checkedOutAt,
      status: r.status,
      shiftId: r.shiftId,
      location: r.location,
      isSynced: r.isSynced,
    );
  }
}
