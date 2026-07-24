import 'package:equatable/equatable.dart';

/// Represents a single successful attendance check-in.
class AttendanceRecord extends Equatable {
  final int? localId;
  final String? serverId;
  final String? personId;
  final String personName;
  final String department;
  final double confidence;
  final DateTime checkedInAt;
  final DateTime? checkedOutAt;
  final String status;
  final int? shiftId;
  final String? location;
  final bool isSynced;

  const AttendanceRecord({
    this.localId,
    this.serverId,
    this.personId,
    required this.personName,
    required this.department,
    required this.confidence,
    required this.checkedInAt,
    this.checkedOutAt,
    this.status = 'present',
    this.shiftId,
    this.location,
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
    DateTime? checkedOutAt,
    String? status,
    int? shiftId,
    String? location,
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
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      status: status ?? this.status,
      shiftId: shiftId ?? this.shiftId,
      location: location ?? this.location,
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
        checkedOutAt,
        status,
        shiftId,
        location,
        isSynced,
      ];
}
