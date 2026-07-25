import 'package:equatable/equatable.dart';

/// The type of scan within a single work day.
enum ScanType {
  checkIn,
  lunchBreak,
  checkOut;

  /// DB / JSON string representation.
  String get value {
    switch (this) {
      case ScanType.checkIn:
        return 'check_in';
      case ScanType.lunchBreak:
        return 'lunch_break';
      case ScanType.checkOut:
        return 'check_out';
    }
  }

  /// Parses the DB / JSON string back to an enum value.
  static ScanType fromValue(String value) {
    switch (value) {
      case 'lunch_break':
        return ScanType.lunchBreak;
      case 'check_out':
        return ScanType.checkOut;
      default:
        return ScanType.checkIn;
    }
  }

  /// Human-readable label used in the UI.
  String get label {
    switch (this) {
      case ScanType.checkIn:
        return 'Check-In';
      case ScanType.lunchBreak:
        return 'Return from Lunch';
      case ScanType.checkOut:
        return 'Check-Out';
    }
  }
}

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
  final ScanType scanType;

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
    this.scanType = ScanType.checkIn,
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
    ScanType? scanType,
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
      scanType: scanType ?? this.scanType,
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
    scanType,
  ];
}
