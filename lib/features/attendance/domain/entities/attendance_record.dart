import 'package:equatable/equatable.dart';

/// Represents a single successful attendance check-in.
class AttendanceRecord extends Equatable {
  final int? localId;
  final String? serverId;

  /// Links to the registered person (local or server ID).
  final String? personId;
  final String personName;
  final String department;

  /// Recognition confidence score (0.0 – 1.0).
  final double confidence;

  final DateTime checkedInAt;
  final bool isSynced;

  const AttendanceRecord({
    this.localId,
    this.serverId,
    this.personId,
    required this.personName,
    required this.department,
    required this.confidence,
    required this.checkedInAt,
    this.isSynced = false,
  });

  AttendanceRecord copyWith({
    int? localId,
    String? serverId,
    String? personId,
    String? personName,
    String? department,
    double? confidence,
    DateTime? checkedInAt,
    bool? isSynced,
  }) {
    return AttendanceRecord(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      department: department ?? this.department,
      confidence: confidence ?? this.confidence,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        localId,
        serverId,
        personId,
        personName,
        department,
        confidence,
        checkedInAt,
        isSynced,
      ];
}
